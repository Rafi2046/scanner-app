import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/models/scan_quad.dart';
import 'package:scanner_app/providers/custom_scan_provider.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_crop_overlay.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_shutter_button.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

/// Perspective crop step allowing corners adjustment.
class CropStepView extends ConsumerStatefulWidget {
  const CropStepView({super.key});

  @override
  ConsumerState<CropStepView> createState() => _CropStepViewState();
}

class _CropStepViewState extends ConsumerState<CropStepView> {
  Size? _imageSize;

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

    return Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return FutureBuilder<Size>(
                  future: _resolveImageSize(path),
                  builder: (BuildContext context, AsyncSnapshot<Size> snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    _imageSize = snap.data;
                    return ScanCropOverlay(
                      imagePath: path,
                      imageSize: snap.data!,
                      quad: quad,
                      maxSize: constraints.biggest,
                      onQuadChanged: (ScanQuad q) => ref
                          .read(customScanNotifierProvider.notifier)
                          .updateQuad(q),
                    );
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

  Future<Size> _resolveImageSize(String path) async {
    if (_imageSize != null) return _imageSize!;
    final File file = File(path);
    final bytes = await file.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }
}
