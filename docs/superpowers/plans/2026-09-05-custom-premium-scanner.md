# Custom Premium Scanner (M4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Android-only CamScanner-style custom scan flow (capture → crop → enhance → pages → save), replacing ML Kit native UI.

**Architecture:** Services (`CameraCaptureService`, `EdgeDetectService`, `ScanEnhanceService`) + `CustomScanNotifier` + dark `document_scan` views. Reuse `PdfService` / `StorageService`.

**Tech stack:** `camera`, `permission_handler`, `image_picker`, `opencv_dart`, `image`, Riverpod.

## Performance constraints (enforce every task)

- Downscale to max edge **1920** immediately after capture/import (`Isolate.run` + `image`).
- All heavy image/OpenCV work off UI thread (`Isolate.run` / `compute`; OpenCV via path-only isolate payloads).
- `CameraPreview` always inside matching `AspectRatio`.
- Files ≤ ~250 lines; `AppConstants` for tokens.

## File map

| File | Responsibility |
|------|----------------|
| `lib/models/scan_quad.dart` | 4 corner points (image pixels) |
| `lib/services/image_resize_ops.dart` | Isolate-safe downscale |
| `lib/services/camera_capture_service.dart` | Permission, camera, capture, gallery → downscaled path |
| `lib/services/edge_detect_ops.dart` | Isolate OpenCV detect + warp |
| `lib/services/edge_detect_service.dart` | Public API wrapping ops |
| `lib/services/scan_enhance_service.dart` | Filters in isolate (later task) |
| `lib/providers/custom_scan_*.dart` | Session state (later) |
| `lib/views/document_scan/*` | UI shells (later) |

---

### Task 1: Constants + models + CameraCaptureService

**Files:**
- Modify: `lib/core/constants/app_constants.dart`
- Create: `lib/models/scan_quad.dart`
- Create: `lib/services/image_resize_ops.dart`
- Create: `lib/services/camera_capture_service.dart`
- Modify: `lib/providers/service_providers.dart` (+ codegen)
- Modify: `android/app/src/main/AndroidManifest.xml`

- [x] Add `scanMaxEdge = 1920`, `scanJpegQuality = 90`
- [x] Implement downscale in isolate; camera take/gallery always downscale before return
- [x] Register provider; add gallery permissions
- [ ] Commit: `Add CameraCaptureService with isolate downscale`

### Task 2: EdgeDetectService (OpenCV)

**Files:**
- Create: `lib/services/edge_detect_ops.dart`
- Create: `lib/services/edge_detect_service.dart`
- Modify: `lib/providers/service_providers.dart` (+ codegen)

- [x] `detectCorners(path)` → `ScanQuad` (fallback inset rect on failure)
- [x] `warp(path, quad)` → warped JPEG path
- [x] All OpenCV work in `Isolate.run`
- [ ] Commit: `Add EdgeDetectService with OpenCV isolate pipeline`

### Task 3: ScanEnhanceService

- [x] Original / Color / B&W / Enhance via `Isolate.run` + `image`
- [ ] Commit enhance service

### Task 4: CustomScanNotifier + navigation shell

- [x] Session state + step machine; wire Home FAB away from ML Kit
- [ ] Commit notifier + entry wiring

### Task 5: Capture / Crop / Enhance / Pages UI

- [x] Dark premium screens; AspectRatio preview; page strip; save via existing PDF/storage
- [x] ID front/back mode
- [ ] Commit UI flow

### Task 6: Device verification

- [ ] Real Android: multi-page PDF + ID A4; no Google scanner UI; no UI jank on capture
- [x] `dart analyze` on new scan modules clean

## Dependencies locked

```yaml
camera: (pub)
permission_handler: (pub)
image_picker: (pub)
opencv_dart: ^2.2.2
image: (existing)
```
