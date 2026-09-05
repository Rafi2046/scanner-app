import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/id_card_category.dart';
import 'package:scanner_app/core/enums/id_scan_side.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/providers/custom_scan_provider.dart';
import 'package:scanner_app/providers/custom_scan_state.dart';
import 'package:scanner_app/providers/service_providers.dart';
import 'package:scanner_app/models/scan_quad.dart';
import 'package:scanner_app/services/camera_capture_service.dart';
import 'package:scanner_app/services/live_document_detector.dart';
import 'package:scanner_app/views/document_scan/widgets/id_card_type_selector_view.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_camera_top_bar.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_camera_viewfinder.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_features_bottom_sheet.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_mode_carousel.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_shutter_bar.dart';
import 'package:scanner_app/views/ocr/ocr_result_view.dart';
import 'package:scanner_app/views/tools/compress_view.dart';
import 'package:scanner_app/views/tools/merge_pdf_view.dart';
import 'package:scanner_app/views/tools/password_lock_view.dart';
import 'package:scanner_app/views/tools/pdf_to_image_view.dart';
import 'package:scanner_app/views/tools/signature_view.dart';
import 'package:scanner_app/views/tools/watermark_view.dart';

/// Full-screen immersive camera capture screen with live document focus.
class CaptureStepView extends ConsumerStatefulWidget {
  const CaptureStepView({super.key});

  @override
  ConsumerState<CaptureStepView> createState() => _CaptureStepViewState();
}

class _CaptureStepViewState extends ConsumerState<CaptureStepView> {
  final LiveDocumentDetector _detector = LiveDocumentDetector();
  late final CameraCaptureService _camera;
  ScanQuad? _detectedQuad;
  bool _ready = false;
  bool _disposed = false;
  Object? _initError;
  FlashMode _flashMode = FlashMode.off;
  bool _isBatch = false;
  ScanTabMode _tabMode = ScanTabMode.scan;
  bool _inIdCardCamera = false;
  int _missedFrames = 0;

  @override
  void initState() {
    super.initState();
    _camera = ref.read(cameraCaptureServiceProvider);
    _tabMode = ref.read(customScanNotifierProvider).mode == CustomScanMode.idCard
        ? ScanTabMode.idCards
        : ScanTabMode.scan;
    _initCamera();
  }

  @override
  void dispose() {
    _disposed = true;
    _camera.setFlash(FlashMode.off);
    _camera.stopImageStream();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      await _camera.initialize();
      if (!mounted || _disposed) return;
      setState(() => _ready = true);
      final int orientation = _camera.sensorOrientation;
      await _camera.startImageStream((CameraImage image) {
        if (!_disposed && mounted) {
          _scheduleDetection(image, orientation);
        }
      });
    } catch (error) {
      if (mounted && !_disposed) setState(() => _initError = error);
    }
  }

  void _scheduleDetection(CameraImage image, int orientation) {
    _detector.detectLiveDocument(image, orientation).then((ScanQuad? quad) {
      if (!mounted || _disposed) return;
      if (quad != null) {
        _missedFrames = 0;
        setState(() => _detectedQuad = quad);
      } else if (_detectedQuad != null) {
        _missedFrames++;
        if (_missedFrames > 12) {
          setState(() => _detectedQuad = null);
        }
      }
    });
  }

  Future<void> _toggleFlash() async {
    _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await _camera.setFlash(_flashMode);
    if (mounted) setState(() {});
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  void _onModeChanged(ScanTabMode mode) {
    setState(() {
      _tabMode = mode;
      _inIdCardCamera = false;
    });
    final notifier = ref.read(customScanNotifierProvider.notifier);
    switch (mode) {
      case ScanTabMode.scan: notifier.startSession(CustomScanMode.document);
      case ScanTabMode.idCards: notifier.startSession(CustomScanMode.idCard);
      case ScanTabMode.text: _push(const OcrResultView());
      case ScanTabMode.sign: _push(const SignatureView());
      case ScanTabMode.toWord: _push(const PdfToImageView());
      case ScanTabMode.questionSet:
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question Set active.')));
    }
  }

  Future<void> _capture(Future<String> Function() action) async {
    final notifier = ref.read(customScanNotifierProvider.notifier);
    notifier.beginCapture();
    try {
      final ScanQuad? live = _detectedQuad;
      await _camera.stopImageStream();
      final String path = await action();
      _flashMode = FlashMode.off;
      await _camera.setFlash(FlashMode.off);
      await notifier.onRawCaptured(path, liveQuad: live);
    } on ScannerCancelledException {
      notifier.cancelBusy();
    } catch (error) {
      notifier.cancelBusy();
      if (mounted) {
        final String msg = error is AppException
            ? error.message
            : 'Action failed: $error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    }
  }

  void _openFeaturesSheet() {
    ScanFeaturesBottomSheet.show(
      context,
      onDocumentScan: () => _onModeChanged(ScanTabMode.scan), onIdCard: () => _onModeChanged(ScanTabMode.idCards),
      onOcr: () => _push(const OcrResultView()),
      onSign: () => _push(const SignatureView()),
      onMerge: () => _push(const MergePdfView()),
      onWatermark: () => _push(const WatermarkView()),
      onProtect: () => _push(const PasswordLockView()),
      onCompress: () => _push(const CompressView()),
      onPdfToImage: () => _push(const PdfToImageView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CustomScanState scan = ref.watch(customScanNotifierProvider);

    // If user is on ID Cards tab and hasn't started the camera yet, show the full ID Card Preset screen!
    if (_tabMode == ScanTabMode.idCards && !_inIdCardCamera) {
      return IdCardTypeSelectorView(
        selectedCategory: scan.idCategory,
        onCategorySelected: (IdCardCategory cat) {
          ref.read(customScanNotifierProvider.notifier).selectIdCategory(cat);
        },
        onMakeItNow: () {
          setState(() => _inIdCardCamera = true);
        },
        onClose: () => Navigator.of(context).maybePop(),
        onToggleFlash: _toggleFlash,
        isFlashOn: _flashMode == FlashMode.torch,
        tabMode: _tabMode,
        onTabModeChanged: _onModeChanged,
        onOpenFeatures: _openFeaturesSheet,
      );
    }

    if (_initError != null) {
      final String msg = _initError is AppException
          ? (_initError! as AppException).message
          : 'Camera failed to start.';
      return Center(child: Text(msg, style: const TextStyle(color: Colors.white70)));
    }

    if (!_ready || !_camera.isInitialized || _camera.controller == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00D2A0)));
    }

    final bool isId = scan.mode == CustomScanMode.idCard;

    return Container(
      color: Colors.black,
      child: Column(
        children: <Widget>[
          ScanCameraTopBar(
            onClose: () {
              if (_tabMode == ScanTabMode.idCards && _inIdCardCamera) {
                setState(() => _inIdCardCamera = false);
              } else {
                Navigator.of(context).maybePop();
              }
            },
            flashMode: _flashMode,
            onFlashToggle: _toggleFlash,
          ),
          Expanded(
            child: Stack(
              children: <Widget>[
                ScanCameraViewfinder(
                  controller: _camera.controller!,
                  aspectRatio: _camera.previewAspectRatio,
                  isId: isId,
                  isBatch: _isBatch,
                  normalizedQuad: _detectedQuad,
                  onBatchToggle: (bool val) => setState(() => _isBatch = val),
                  onFocusTap: (Offset pos, Size size) {
                    _camera.triggerFocus(screenPoint: pos, viewSize: size);
                  },
                ),
                if (isId)
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _inIdCardCamera = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24, width: 1.0),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(LucideIcons.creditCard, size: 14, color: Color(0xFF00C292)),
                              const SizedBox(width: 7),
                              Text(
                                '${scan.idCategory.title} • ${scan.idSide == IdScanSide.front ? (scan.idCategory.isSingleSide ? "Document" : "Front Side") : "Back Side"}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(LucideIcons.chevronDown, size: 13, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ScanModeCarousel(
            selectedMode: _tabMode,
            onModeSelected: _onModeChanged,
          ),
          ScanShutterBar(
            enabled: !scan.busy,
            onShutter: () => _capture(_camera.takePicture),
            onAllFeatures: _openFeaturesSheet,
            onGallery: () => _capture(_camera.pickFromGallery),
          ),
        ],
      ),
    );
  }
}
