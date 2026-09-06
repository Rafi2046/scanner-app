"""
CamScanner-Style Document Scanning & Enhancement Pipeline Server.

Stages:
1. Document Edge Detection: Multi-scale edge detection (Canny + morphological closing + 4-point polygon approximation).
2. Perspective Transformation: Ordered 4-point perspective warp into a flat top-down rectangular document.
3. Edge-Preserving Denoising: Bilateral filter removes camera sensor noise while keeping text boundaries sharp.
4. CLAHE Equalization: Contrast Limited Adaptive Histogram Equalization on the L-channel (LAB space) for uniform lighting.
5. High-Pass Unsharp Masking: Laplacian/Gaussian edge boost for razor-sharp character legibility.
6. Multi-Mode Output:
   - 'color': Vibrant, shadow-free color document scan.
   - 'gray': CLAHE-enhanced smooth continuous-tone monochrome.
   - 'bw': Adaptive Gaussian thresholding (blockSize=25, C=15) for high-contrast 1-bit printing/photocopy.
"""

import io
import logging
from typing import Optional

import cv2
import numpy as np
from flask import Flask, jsonify, request, send_file

logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] %(levelname)s in %(module)s: %(message)s",
)

app = Flask(__name__)


def order_points(pts: np.ndarray) -> np.ndarray:
    """
    Orders 4 polygon points consistently:
    [top-left, top-right, bottom-right, bottom-left].
    """
    rect = np.zeros((4, 2), dtype="float32")
    pts_2d = pts.reshape(4, 2)

    # Top-left has smallest sum (x + y), bottom-right has largest sum
    s = pts_2d.sum(axis=1)
    rect[0] = pts_2d[np.argmin(s)]
    rect[2] = pts_2d[np.argmax(s)]

    # Top-right has smallest difference (y - x), bottom-left has largest difference
    diff = np.diff(pts_2d, axis=1)
    rect[1] = pts_2d[np.argmin(diff)]
    rect[3] = pts_2d[np.argmax(diff)]

    return rect


def find_document_contour(image: np.ndarray) -> Optional[np.ndarray]:
    """
    Stage 1: Detects document boundary contour using morphological closing,
    Gaussian smoothing, Canny edge detection, and 4-point polygon approximation.
    """
    h, w = image.shape[:2]
    max_dim = 800.0
    scale = max_dim / max(h, w) if max(h, w) > max_dim else 1.0

    if scale < 1.0:
        small = cv2.resize(image, (int(w * scale), int(h * scale)))
    else:
        small = image.copy()

    gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)

    # Morphological closing wipes text to isolate paper boundaries
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (9, 9))
    text_erased = cv2.morphologyEx(gray, cv2.MORPH_CLOSE, kernel)

    blurred = cv2.GaussianBlur(text_erased, (5, 5), 0)
    edged = cv2.Canny(blurred, 50, 150)
    edged = cv2.dilate(edged, None, iterations=2)
    edged = cv2.erode(edged, None, iterations=1)

    contours, _ = cv2.findContours(edged, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    contours = sorted(contours, key=cv2.contourArea, reverse=True)[:5]

    for c in contours:
        area = cv2.contourArea(c)
        # Require candidate to cover at least 10% of image area
        if area < (small.shape[0] * small.shape[1] * 0.10):
            continue

        peri = cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, 0.02 * peri, True)
        if len(approx) == 4:
            # Rescale points back to original image coordinates
            pts = approx.reshape(4, 2).astype("float32")
            if scale < 1.0:
                pts /= scale
            return pts

    return None


def perspective_warp(image: np.ndarray, pts: np.ndarray) -> np.ndarray:
    """
    Stage 2: Warps 4-point quadrilateral into a flat top-down rectangular view.
    """
    rect = order_points(pts)
    tl, tr, br, bl = rect

    # Calculate optimal target rectangle dimensions
    width_a = np.linalg.norm(br - bl)
    width_b = np.linalg.norm(tr - tl)
    max_width = int(max(width_a, width_b))

    height_a = np.linalg.norm(tr - br)
    height_b = np.linalg.norm(tl - bl)
    max_height = int(max(height_a, height_b))

    # Guard against degenerate / zero-area dimensions
    max_width = max(max_width, 100)
    max_height = max(max_height, 100)

    dst = np.array(
        [
            [0, 0],
            [max_width - 1, 0],
            [max_width - 1, max_height - 1],
            [0, max_height - 1],
        ],
        dtype="float32",
    )

    m = cv2.getPerspectiveTransform(rect, dst)
    warped = cv2.warpPerspective(
        image,
        m,
        (max_width, max_height),
        flags=cv2.INTER_CUBIC,
        borderMode=cv2.BORDER_REPLICATE,
    )
    return warped


def enhance_document(
    image: np.ndarray,
    mode: str = "color",
    auto_detect_corners: bool = True,
) -> np.ndarray:
    """
    Executes stages 1-6 of the CamScanner pipeline:
    detect -> warp -> bilateral denoise -> LAB CLAHE -> unsharp mask -> mode output.

    :param image: BGR numpy image array.
    :param mode: 'color' | 'gray' | 'bw'.
    :param auto_detect_corners: Detect and warp boundaries if True.
    :return: Processed document image.
    """
    # Stages 1 & 2: Boundary detection & perspective warp
    if auto_detect_corners:
        contour = find_document_contour(image)
        if contour is not None:
            warped = perspective_warp(image, contour)
        else:
            warped = image
    else:
        warped = image

    # Stage 3: Bilateral Denoising (preserves text edges, removes camera sensor noise)
    denoised = cv2.bilateralFilter(warped, d=9, sigmaColor=75, sigmaSpace=75)

    # Stage 6: Modes
    if mode == "color":
        # Stage 4: CLAHE on L channel in LAB color space
        lab = cv2.cvtColor(denoised, cv2.COLOR_BGR2LAB)
        l_channel, a_channel, b_channel = cv2.split(lab)

        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        l_enhanced = clahe.apply(l_channel)

        merged_lab = cv2.merge((l_enhanced, a_channel, b_channel))
        color_enhanced = cv2.cvtColor(merged_lab, cv2.COLOR_LAB2BGR)

        # Stage 5: Unsharp Mask for crisp, high-contrast text edges
        gaussian = cv2.GaussianBlur(color_enhanced, (0, 0), 3.0)
        sharpened = cv2.addWeighted(color_enhanced, 1.5, gaussian, -0.5, 0)
        return sharpened

    # Grayscale conversion for monochrome modes
    gray = cv2.cvtColor(denoised, cv2.COLOR_BGR2GRAY)

    if mode == "gray":
        # Stage 4: CLAHE equalization on continuous-tone grayscale
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        gray_enhanced = clahe.apply(gray)

        # Stage 5: Subtle unsharp mask for sharp typography
        gaussian = cv2.GaussianBlur(gray_enhanced, (0, 0), 2.5)
        return cv2.addWeighted(gray_enhanced, 1.3, gaussian, -0.3, 0)

    if mode in ("bw", "bwprint"):
        # Stage 6: Adaptive thresholding for print-ready black & white
        # Eliminates shadows, guarantees solid black ink on pure white paper
        bw = cv2.adaptiveThreshold(
            gray,
            255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            blockSize=25,
            C=15,
        )
        return bw

    # Default fallback
    return denoised


# -----------------------------------------------------------------------------
# Flask API Endpoints
# -----------------------------------------------------------------------------
@app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint."""
    return jsonify(
        {
            "status": "healthy",
            "service": "document-scanner-pipeline",
            "supported_modes": ["color", "gray", "bw"],
        }
    )


@app.route("/scan", methods=["POST"])
def scan_document_endpoint():
    """
    Document processing endpoint.
    Expects multipart/form-data:
      - 'image': File upload (JPEG/PNG/WebP).
      - 'mode': (Optional) 'color' (default) | 'gray' | 'bw'.
      - 'detect_corners': (Optional) 'true' (default) | 'false'.
    Returns processed JPEG image stream.
    """
    if "image" not in request.files:
        return jsonify({"error": "Missing 'image' file in multipart request."}), 400

    file = request.files["image"]
    if file.filename == "":
        return jsonify({"error": "No file selected."}), 400

    try:
        # Read uploaded image bytes directly into OpenCV
        file_bytes = file.read()
        np_arr = np.frombuffer(file_bytes, np.uint8)
        image = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)

        if image is None or image.size == 0:
            return jsonify({"error": "Failed to decode input image."}), 400

        mode = request.form.get("mode", "color").strip().lower()
        if mode not in ("color", "gray", "bw", "bwprint"):
            mode = "color"

        detect_corners_param = (
            request.form.get("detect_corners", "true").strip().lower()
        )
        auto_detect = detect_corners_param != "false"

        app.logger.info(
            f"Processing image {image.shape[1]}x{image.shape[0]} with mode='{mode}' (auto_detect={auto_detect})"
        )

        processed = enhance_document(
            image,
            mode=mode,
            auto_detect_corners=auto_detect,
        )

        # Encode processed image to JPEG
        encode_params = [int(cv2.IMWRITE_JPEG_QUALITY), 95]
        success, encoded_buf = cv2.imencode(".jpg", processed, encode_params)

        if not success:
            return jsonify({"error": "Failed to encode processed image."}), 500

        return send_file(
            io.BytesIO(encoded_buf.tobytes()),
            mimetype="image/jpeg",
            as_attachment=False,
            download_name="scanned_document.jpg",
        )

    except Exception as exc:
        app.logger.exception(f"Error processing scan: {exc}")
        return jsonify({"error": f"Processing failure: {str(exc)}"}), 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
