# Document Scanning & Enhancement Pipeline (Flask + OpenCV)

A CamScanner-grade document processing service with a 6-stage computer vision pipeline.

## 6-Stage Pipeline

```
Raw Photo
   │
   ▼
[1] Document Edge Detection (Canny edges + contour hierarchy + 4-point polygon approximation)
   │
   ▼
[2] Perspective Warp (Ordered 4-point perspective transform into top-down rectangle)
   │
   ▼
[3] Bilateral Denoising (d=9, sigma=75: smooths sensor noise, preserves crisp edges)
   │
   ▼
[4] LAB Color Space CLAHE (clipLimit=2.0, tileGrid=8x8 on L channel for uniform lighting)
   │
   ▼
[5] High-Pass Unsharp Mask (Laplacian / Gaussian edge boost for sharp text)
   │
   ▼
[6] Output Mode Selection:
       ├── 'color' : Vibrant, shadow-free, color-accurate document
       ├── 'gray'  : Smooth continuous-tone monochrome
       └── 'bw'    : Adaptive Gaussian thresholding (blockSize=25, C=15)
```

---

## Quickstart

### 1. Install dependencies
```bash
cd scanner_service
pip install -r requirements.txt
```

### 2. Run the server
```bash
python app.py
```
*Server runs on `http://127.0.0.1:5000`.*

For production, run with Gunicorn:
```bash
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

---

## API Documentation

### `GET /health`
Returns service status.

**Response:**
```json
{
  "status": "healthy",
  "service": "document-scanner-pipeline",
  "supported_modes": ["color", "gray", "bw"]
}
```

---

### `POST /scan`
Processes a document photo through the 6-stage pipeline.

**Request Headers:**
- `Content-Type: multipart/form-data`

**Parameters:**
| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `image` | File | **Yes** | Input image file (JPEG / PNG / WebP) |
| `mode` | String | No | `color` (default), `gray`, or `bw` |
| `detect_corners` | String | No | `true` (default, auto crops & flattens) or `false` (skips warp) |

**Response:**
- Returns binary `image/jpeg` (JPEG quality 95).

---

## Example Usage

### Using cURL
```bash
# Color mode
curl -X POST http://127.0.0.1:5000/scan \
  -F "image=@/path/to/my_document.jpg" \
  -F "mode=color" \
  --output scanned_color.jpg

# Black & White mode (high-contrast photocopy)
curl -X POST http://127.0.0.1:5000/scan \
  -F "image=@/path/to/my_document.jpg" \
  -F "mode=bw" \
  --output scanned_bw.jpg

# Grayscale mode
curl -X POST http://127.0.0.1:5000/scan \
  -F "image=@/path/to/my_document.jpg" \
  -F "mode=gray" \
  --output scanned_gray.jpg
```

### Using Python
```python
import requests

with open("my_document.jpg", "rb") as f:
    response = requests.post(
        "http://127.0.0.1:5000/scan",
        files={"image": f},
        data={"mode": "color", "detect_corners": "true"},
    )

with open("output.jpg", "wb") as f:
    f.write(response.content)
```

### Using the included test client
```bash
python test_client.py /path/to/my_document.jpg --mode color
```
