"""
Test client for the Document Scanning Pipeline Flask endpoint.
Usage:
    python test_client.py path/to/document.jpg --mode color
    python test_client.py path/to/document.jpg --mode bw
    python test_client.py path/to/document.jpg --mode gray
"""

import argparse
import sys
import requests


def test_scan(image_path: str, mode: str = "color", url: str = "http://127.0.0.1:5000/scan"):
    print(f"Uploading '{image_path}' to {url} with mode='{mode}'...")
    try:
        with open(image_path, "rb") as f:
            files = {"image": f}
            data = {"mode": mode, "detect_corners": "true"}
            response = requests.post(url, files=files, data=data, timeout=30)

        if response.status_code == 200:
            output_filename = f"scanned_result_{mode}.jpg"
            with open(output_filename, "wb") as out_f:
                out_f.write(response.content)
            print(f"Success! Saved processed scan as '{output_filename}' ({len(response.content)} bytes).")
        else:
            print(f"Failed with status code {response.status_code}: {response.text}")
    except Exception as exc:
        print(f"Request error: {exc}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Test CamScanner Document Scanner Endpoint")
    parser.add_argument("image", help="Path to input document photo")
    parser.add_argument("--mode", choices=["color", "gray", "bw"], default="color", help="Enhancement mode")
    parser.add_argument("--url", default="http://127.0.0.1:5000/scan", help="Server endpoint URL")

    args = parser.parse_args()
    test_scan(args.image, mode=args.mode, url=args.url)
