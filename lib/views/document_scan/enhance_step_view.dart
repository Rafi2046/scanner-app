import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';
import 'package:scanner_app/providers/custom_scan_provider.dart';
import 'package:scanner_app/providers/custom_scan_state.dart';
import 'package:scanner_app/providers/ocr_provider.dart';
import 'package:scanner_app/views/document_scan/widgets/document_scan_beam.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_enhance_bottom_bar.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_filter_visual_carousel.dart';
import 'package:scanner_app/views/ocr/ocr_result_view.dart';
import 'package:scanner_app/views/tools/signature_view.dart';

/// Document enhancement step featuring real-time image filter processing,
/// interactive visual filter previews, page management, and quick tools.
class EnhanceStepView extends ConsumerStatefulWidget {
  const EnhanceStepView({super.key});

  @override
  ConsumerState<EnhanceStepView> createState() => _EnhanceStepViewState();
}

class _EnhanceStepViewState extends ConsumerState<EnhanceStepView> {
  static const Color _accent = Color(0xFF00D2A0);

  Future<void> _onAddPage() async {
    await ref.read(customScanNotifierProvider.notifier).confirmEnhance();
    if (mounted) {
      ref.read(customScanNotifierProvider.notifier).goToCapture();
    }
  }

  void _onDiscardPage() {
    showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2129),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Page?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to discard this scanned page?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard', style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).then((bool? confirmed) {
      if (confirmed == true && mounted) {
        ref.read(customScanNotifierProvider.notifier).goToCapture();
      }
    });
  }

  void _onExtractText(String path) {
    ref.read(ocrNotifierProvider.notifier).extractTextFromImage(path);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OcrResultView(),
      ),
    );
  }

  void _onSign() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SignatureView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CustomScanState scan = ref.watch(customScanNotifierProvider);
    final String? path = scan.warpedPath;

    if (path == null) {
      return const Center(
        child: Text(
          'No cropped image',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final int currentPage = scan.pages.length + 1;
    final int totalPages = scan.pages.length + 1;

    return Scaffold(
      backgroundColor: const Color(0xFF12151B),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Top Bar: Sleek "+ Add Page" action & status indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  InkWell(
                    onTap: scan.busy ? null : _onAddPage,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _accent.withValues(alpha: 0.4), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.add_rounded, color: _accent, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'Add Page',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (scan.busy)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          scan.busyMessage ?? 'Processing…',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        scan.selectedFilter.label,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Document Center Preview Stage
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                        child: DocumentScanBeam(
                          autoStart: true,
                          trigger: scan.selectedFilter,
                          child: Image.file(
                            File(path),
                            key: ValueKey<String>(path),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating Discard/Trash button on top-left of document preview
                  Positioned(
                    top: 14,
                    left: 26,
                    child: GestureDetector(
                      onTap: scan.busy ? null : _onDiscardPage,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24, width: 0.8),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page Indicator Pill: ◀ 1 / 1 ▶
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F242C),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.arrow_left_rounded,
                      color: Colors.white60,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$currentPage / $totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_right_rounded,
                      color: Colors.white60,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Our App's Unique Visual Filter Cards Carousel
            ScanFilterVisualCarousel(
              selected: scan.selectedFilter,
              onSelected: (ScanFilter filter) {
                if (scan.busy) return;
                ref.read(customScanNotifierProvider.notifier).selectFilter(filter);
              },
            ),

            const SizedBox(height: 10),

            // Bottom Action Toolbar with our signature UI styling
            ScanEnhanceBottomBar(
              busy: scan.busy,
              onRetake: () {
                ref.read(customScanNotifierProvider.notifier).goToCapture();
              },
              onRotateLeft: () {
                ref.read(customScanNotifierProvider.notifier).rotateLeft();
              },
              onCrop: () {
                ref.read(customScanNotifierProvider.notifier).goToCrop();
              },
              onExtractText: () {
                _onExtractText(path);
              },
              onSign: _onSign,
              onConfirm: () {
                ref.read(customScanNotifierProvider.notifier).confirmEnhance();
              },
            ),
          ],
        ),
      ),
    );
  }
}
