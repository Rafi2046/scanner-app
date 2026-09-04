# Custom Premium Document Scanner — Design

**Date:** 2026-09-05  
**Status:** Approved (product) — pending user review of this spec  
**Platform (MVP):** Android only  
**Goal:** Replace Google ML Kit Document Scanner’s native UI with a CamScanner-style custom Flutter flow (premium dark shell, offline).

## Decisions locked

| Topic | Choice |
|--------|--------|
| Scope | Full MVP: custom camera → auto edge crop → filters → multi-page → save PDF |
| Platforms | Android first; iOS later |
| ID Card | Same capture/crop/enhance engine; front → back → A4 PDF |
| Approach | `camera` + edge/perspective plugin + Dart `image` filters |
| Brand | Own “Scanner” UI language — not a ProScan/CamScanner clone |

## User flow

Shared pipeline; `mode` is `document` or `id`.

1. **Capture** — Full-screen dark camera; document frame or ID aspect overlay; shutter, flash, gallery import; mode chips Document | ID Card.
2. **Crop** — Auto-detected 4 corners + manual drag; Retake / Confirm; perspective warp on confirm.
3. **Enhance** — Filters: Original · Color · B&W · Enhance; live preview; Next.
4. **Pages** — Thumbnail strip; Add page (returns to Capture); delete page (reorder out of scope); primary Save.
5. **Save** — Document: multi-page PDF via existing `PdfService.createDocumentPdfFromImages`. ID: both sides required → `PdfService.createIdCardA4`. Persist via existing `StorageService`; refresh library.

**Entry points:** Home FAB, Home quick tools (Scan / ID Card), Tools tab.  
**Removed from UX:** Launching ML Kit `DocumentScanner.scanDocument()` full UI for these entry points.

## UI principles

- Dark scan surfaces (`DarkScanScaffold` / `#12141A`), blue primary CTAs, pill toolbars.
- Edge-to-edge preview on Capture; large shutter; compact flash/gallery controls.
- Modular widgets; files stay under ~200–250 lines; layout tokens from `AppConstants`.

## Architecture

```
lib/views/document_scan/          # Capture, Crop, Enhance, Pages screens
  widgets/                        # Overlay, shutter, filter chips, page strip, corner handles
lib/services/
  camera_capture_service.dart     # Camera init, flash, still capture, dispose
  edge_detect_service.dart        # Contour → quads; warp; fallback rectangle
  scan_enhance_service.dart       # Filter pipeline (isolate-friendly)
lib/providers/
  custom_scan_provider.dart       # Session state + step navigation + save
lib/models/
  scan_page.dart                  # Temp paths, applied filter, id side if any
```

**Keep as-is:** `PdfService`, `StorageService`, library notifiers.  
**Deprecate (stop calling):** `DocumentScannerService` for Home/Tools document & ID flows. Package may remain until a cleanup PR removes it.

### Session state (conceptual)

- `mode`: `document` | `id`
- `step`: `capture` | `crop` | `enhance` | `pages`
- `pages`: ordered list of processed page images (paths + filter)
- ID: track which side is being captured (`front` | `back`); Save enabled only when both exist
- `pendingCapture`: raw image awaiting crop/enhance
- Errors: typed `AppException` subclasses; snackbars via existing helpers; cancel/back does not leave orphan temp files when possible

## Services — responsibilities

### CameraCaptureService

- Request camera permission; start preview; toggle torch; take picture to temp path; pick from gallery to temp path; release camera on leave Capture.

### EdgeDetectService

- Input: image path. Output: four normalized corner points (or null).
- On null/failure: default inset rectangle; UI always allows manual adjustment.
- `warp(path, corners) →` cropped JPEG temp path.

### ScanEnhanceService

| Filter | Behavior |
|--------|----------|
| Original | Passthrough copy or same path |
| Color | Mild contrast / white-balance style adjust |
| B&W | Grayscale + contrast |
| Enhance | Sharpen + contrast for document readability |

Processing should not block the UI isolate for large images (compute / isolate).

## Navigation map

```
Home / Tools
  → CustomScanShell (holds notifier)
       → CaptureView
       → CropView
       → EnhanceView
       → PagesView → save → pop to Home + snackbar
```

ID mode reuses the same screens; PagesView shows Front/Back slots instead of an open-ended strip (still allows retake per side).

## Dependencies (new)

- `camera` (+ Android camera permissions already present; runtime request)
- Edge / perspective plugin (OpenCV-based or equivalent Android-capable package chosen at implement time)
- Gallery pick: existing `file_picker` or `image_picker` as needed
- `image` (already in project) for filters

Exact package name for edge detection is fixed in the implementation plan after a short pub.dev/Android compatibility check — must support offline perspective transform on Android.

## Error & edge cases

- Permission denied → explanatory UI + open settings link; no crash.
- User cancels mid-flow → discard session temps; return Home.
- Edge detect fail → manual crop only; no hard error.
- Empty pages on Save → disable button / snackbar.
- ID Save with one side missing → disable Save; prompt to capture the other side.
- Scanner cancelled / camera errors → `ScannerException` / typed errors, existing snackbar pattern.

## Out of scope (MVP)

- iOS custom camera
- Live viewfinder real-time edge animation
- OCR during scan
- Magic erase / handwriting remove
- Drag-reorder pages
- Cloud sync / premium paywall
- Keeping ML Kit native review UI

## Success criteria

1. Tapping Scan/FAB opens **our** dark Capture screen — not Google’s Filters/Crop/Next Activity.
2. User can capture ≥2 document pages, apply filters, save a multi-page PDF into the library.
3. ID Card path: front + back through same engine → single A4 PDF in library.
4. Entire flow works offline on Android.
5. New/edited Dart files remain modular (≤ ~250 lines) and use `AppConstants` for spacing/sizes.

## Implementation notes (for planning)

- Wire `DocumentScanNotifier.startDocumentScan` (and ID entry) to push custom flow instead of ML Kit.
- Prefer one `CustomScanNotifier` for the session rather than duplicating ID vs document notifiers.
- Temp files under app cache; persist only on successful Save.
- Visual regression: manual device check on Capture → Crop → Enhance → Pages → library card appears.
