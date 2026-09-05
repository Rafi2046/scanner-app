import 'dart:io';
import 'dart:ui' show Offset, Size;

import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/services/image_resize_ops.dart';

/// Android camera + gallery capture with immediate max-edge downscale.
class CameraCaptureService {
  CameraCaptureService({
    ImagePicker? imagePicker,
  }) : _picker = imagePicker ?? ImagePicker();

  final ImagePicker _picker;
  CameraController? _controller;

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Aspect ratio for preview in portrait (`width / height`).
  double get previewAspectRatio {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized) {
      return 9 / 16;
    }
    final double ratio = c.value.aspectRatio;
    return ratio > 1 ? 1 / ratio : ratio;
  }

  Future<void> ensureCameraPermission() async {
    final PermissionStatus status = await Permission.camera.request();
    if (!status.isGranted) {
      throw const ScannerException(
        'Camera permission is required to scan documents.',
      );
    }
  }

  Future<void> initialize({
    ResolutionPreset preset = ResolutionPreset.high,
  }) async {
    await ensureCameraPermission();
    await dispose();

    final List<CameraDescription> cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw const ScannerException('No camera is available on this device.');
    }

    final CameraDescription back = cameras.firstWhere(
      (CameraDescription c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final CameraController next = CameraController(
      back,
      preset,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await next.initialize();
      try {
        await next.setFocusMode(FocusMode.auto);
      } catch (_) {}
      _controller = next;
    } catch (error) {
      await next.dispose();
      throw ScannerException('Failed to start the camera.', cause: error);
    }
  }

  Future<void> setFlash(FlashMode mode) async {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized) {
      return;
    }
    try {
      await c.setFlashMode(mode);
    } catch (error) {
      throw ScannerException('Could not change flash mode.', cause: error);
    }
  }

  /// Triggers hardware autofocus and auto-exposure at the touched screen location.
  /// Translates screen coordinates to camera sensor space based on [sensorOrientation].
  Future<void> triggerFocus({
    required Offset screenPoint,
    required Size viewSize,
  }) async {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized) return;

    final double normX = (screenPoint.dx / viewSize.width).clamp(0.0, 1.0);
    final double normY = (screenPoint.dy / viewSize.height).clamp(0.0, 1.0);

    // Map portrait view coordinates to landscape sensor coordinates
    final int orientation = sensorOrientation;
    Offset sensorPoint;
    switch (orientation) {
      case 90:
        sensorPoint = Offset(normY, 1.0 - normX);
      case 270:
        sensorPoint = Offset(1.0 - normY, normX);
      case 180:
        sensorPoint = Offset(1.0 - normX, 1.0 - normY);
      case 0:
      default:
        sensorPoint = Offset(normX, normY);
    }

    sensorPoint = Offset(
      sensorPoint.dx.clamp(0.0, 1.0),
      sensorPoint.dy.clamp(0.0, 1.0),
    );

    try {
      if (c.value.focusPointSupported) {
        await c.setFocusPoint(sensorPoint);
      }
      if (c.value.exposurePointSupported) {
        await c.setExposurePoint(sensorPoint);
      }
      // Explicitly trigger autofocus search and lock
      await c.setFocusMode(FocusMode.auto);
      try {
        await c.setExposureMode(ExposureMode.auto);
      } catch (_) {}
    } catch (_) {
      try {
        if (c.value.focusPointSupported) {
          await c.setFocusPoint(Offset(normX, normY));
        }
        await c.setFocusMode(FocusMode.auto);
      } catch (_) {}
    }
  }

  int get sensorOrientation =>
      _controller?.description.sensorOrientation ?? 90;

  Future<void> startImageStream(
    void Function(CameraImage image) onAvailable,
  ) async {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isStreamingImages) {
      return;
    }
    try {
      await c.startImageStream(onAvailable);
    } catch (_) {}
  }

  Future<void> stopImageStream() async {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized || !c.value.isStreamingImages) {
      return;
    }
    try {
      await c.stopImageStream();
    } catch (_) {}
  }

  /// Captures a still, downscales to [AppConstants.scanMaxEdge], returns path.
  Future<String> takePicture() async {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized) {
      throw const ScannerException('Camera is not ready.');
    }
    if (c.value.isTakingPicture) {
      throw const ScannerException('Capture already in progress.');
    }

    try {
      if (c.value.isStreamingImages) {
        await c.stopImageStream();
      }
      final XFile raw = await c.takePicture();
      await setFlash(FlashMode.off);
      return _downscaleToScanCache(raw.path);
    } on AppException {
      rethrow;
    } catch (error) {
      throw ScannerException('Failed to take a picture.', cause: error);
    }
  }

  /// Picks from gallery and downscales before returning.
  Future<String> pickFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (picked == null) {
        throw const ScannerCancelledException('Gallery pick was cancelled.');
      }
      return _downscaleToScanCache(picked.path);
    } on AppException {
      rethrow;
    } catch (error) {
      throw ScannerException('Failed to import from gallery.', cause: error);
    }
  }

  Future<String> _downscaleToScanCache(String rawPath) async {
    final Directory cache = await getTemporaryDirectory();
    final String outPath = p.join(
      cache.path,
      'scan_cap_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    return downscaleImageFile(
      inputPath: rawPath,
      outputPath: outPath,
      maxEdge: AppConstants.scanMaxEdge,
      quality: AppConstants.scanJpegQuality,
    );
  }

  Future<void> dispose() async {
    final CameraController? c = _controller;
    _controller = null;
    if (c != null) {
      await c.dispose();
    }
  }
}
