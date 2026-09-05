import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/models/scan_quad.dart';
import 'package:scanner_app/providers/custom_scan_provider.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_crop_overlay.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_shutter_button.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

/// Perspective crop step allowing interactive corner adjustment.
class CropStepView extends ConsumerStatefulWidget {
  const CropStepView({super.key});

  @override
  ConsumerState<CropStepView> createState() => _CropStepViewState();
}

class _CropStepViewState extends ConsumerState<CropStepView> {
  Size? _imageSize;
  String? _resolvedPath;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  void _loadImageSize() {
    final String? path = ref.read(customScanNotifierProvider).pendingPath;
    if (path != null && path != _resolvedPath) {
      _resolvedPath = path;
      _resolveImageSize(path).then((Size size) {
        if (mounted) setState(() => _imageSize = size);
      });
    }
  }

  Future<Size> _resolveImageSize(String path) async {
    final File file = File(path);
    final bytes = await file.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(customScanNotifierProvider);
    final String? path = scan.pendingPath;
    final ScanQuad? quad = scan.pendingQuad;

    if (path == null || quad == null) {
      return const Center(
        child: Text('No image to crop', style: TextStyle(color: Colors.white70)),
      );
    }

    if (path != _resolvedPath) {
      _loadImageSize();
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: _imageSize == null
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF00D2A0)),
                  )
                : LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return ScanCropOverlay(
                        imagePath: path,
                        imageSize: _imageSize!,
                        quad: quad,
                        maxSize: constraints.biggest,
                        onQuadChanged: (ScanQuad q) {
                          ref
                              .read(customScanNotifierProvider.notifier)
                              .updateQuad(q);
                        },
                      );
                    },
                  ),
          ),
        ),
        ScanBottomBar(
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: scan.busy
                      ? null
                      : () => ref
                          .read(customScanNotifierProvider.notifier)
                          .goToCapture(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusPill),
                    ),
                  ),
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: PrimaryButton(
                  label: 'Confirm',
                  onPressed: scan.busy
                      ? null
                      : () => ref
                          .read(customScanNotifierProvider.notifier)
                          .confirmCrop(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
