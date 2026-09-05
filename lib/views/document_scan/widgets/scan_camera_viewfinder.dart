import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_batch_pill.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_viewfinder_frame.dart';

/// Full-height camera viewfinder framed with mint outline and batch pill.
class ScanCameraViewfinder extends StatelessWidget {
  const ScanCameraViewfinder({
    super.key,
    required this.controller,
    required this.aspectRatio,
    required this.isId,
    required this.isBatch,
    required this.onBatchToggle,
  });

  final CameraController controller;
  final double aspectRatio;
  final bool isId;
  final bool isBatch;
  final ValueChanged<bool> onBatchToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxWidth / aspectRatio,
                      child: CameraPreview(controller),
                    ),
                  ),
                );
              },
            ),
            ScanViewfinderFrame(isIdCard: isId),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: ScanBatchPill(
                  isBatch: isBatch,
                  onToggle: onBatchToggle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
