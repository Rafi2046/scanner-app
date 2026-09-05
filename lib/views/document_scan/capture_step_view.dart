import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/errors/app_exception.dart';
import 'package:scanner_app/providers/custom_scan_provider.dart';
import 'package:scanner_app/providers/custom_scan_state.dart';
import 'package:scanner_app/providers/service_providers.dart';
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

/// Full-screen immersive camera capture screen.
class CaptureStepView extends ConsumerStatefulWidget {
  const CaptureStepView({super.key});

  @override
  ConsumerState<CaptureStepView> createState() => _CaptureStepViewState();
}

class _CaptureStepViewState extends ConsumerState<CaptureStepView> {
  bool _ready = false;
  Object? _initError;
  FlashMode _flashMode = FlashMode.off;
  bool _isBatch = false;
  ScanTabMode _tabMode = ScanTabMode.scan;

  @override
  void initState() {
    super.initState();
    _tabMode = ref.read(customScanNotifierProvider).mode == CustomScanMode.idCard
        ? ScanTabMode.idCards
        : ScanTabMode.scan;
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      await ref.read(cameraCaptureServiceProvider).initialize();
      if (mounted) setState(() => _ready = true);
    } catch (error) {
      if (mounted) setState(() => _initError = error);
    }
  }

  Future<void> _toggleFlash() async {
    _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    await ref.read(cameraCaptureServiceProvider).setFlash(_flashMode);
    setState(() {});
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _onModeChanged(ScanTabMode mode) {
    setState(() => _tabMode = mode);
    switch (mode) {
      case ScanTabMode.scan:
        ref.read(customScanNotifierProvider.notifier).startSession(CustomScanMode.document);
      case ScanTabMode.idCards:
        ref.read(customScanNotifierProvider.notifier).startSession(CustomScanMode.idCard);
      case ScanTabMode.text:
        _push(const OcrResultView());
      case ScanTabMode.sign:
        _push(const SignatureView());
      case ScanTabMode.toWord:
        _push(const PdfToImageView());
      case ScanTabMode.questionSet:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question Set scan mode active.')),
        );
    }
  }

  Future<void> _capture(Future<String> Function() action) async {
    try {
      final String path = await action();
      await ref.read(customScanNotifierProvider.notifier).onRawCaptured(path);
    } on ScannerCancelledException {
      // User cancelled picker
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppException ? error.message : 'Action failed: $error',
            ),
          ),
        );
      }
    }
  }

  void _openFeaturesSheet() {
    ScanFeaturesBottomSheet.show(
      context,
      onDocumentScan: () => _onModeChanged(ScanTabMode.scan),
      onIdCard: () => _onModeChanged(ScanTabMode.idCards),
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
    final camera = ref.watch(cameraCaptureServiceProvider);

    if (_initError != null) {
      return Center(
        child: Text(
          _initError is AppException
              ? (_initError! as AppException).message
              : 'Camera failed to start.',
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }

    if (!_ready || !camera.isInitialized || camera.controller == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00D2A0)));
    }

    final bool isId = scan.mode == CustomScanMode.idCard;

    return Container(
      color: Colors.black,
      child: Column(
        children: <Widget>[
          ScanCameraTopBar(
            onClose: () => Navigator.of(context).maybePop(),
            flashMode: _flashMode,
            onFlashToggle: _toggleFlash,
          ),
          Expanded(
            child: ScanCameraViewfinder(
              controller: camera.controller!,
              aspectRatio: camera.previewAspectRatio,
              isId: isId,
              isBatch: _isBatch,
              onBatchToggle: (bool val) => setState(() => _isBatch = val),
            ),
          ),
          const SizedBox(height: 6),
          ScanModeCarousel(
            selectedMode: _tabMode,
            onModeSelected: _onModeChanged,
          ),
          ScanShutterBar(
            enabled: !scan.busy,
            onShutter: () => _capture(camera.takePicture),
            onAllFeatures: _openFeaturesSheet,
            onGallery: () => _capture(camera.pickFromGallery),
          ),
        ],
      ),
    );
  }
}
