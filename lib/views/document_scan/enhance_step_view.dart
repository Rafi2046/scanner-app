import 'dart:io';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';
import 'package:scanner_app/models/scan_page_draft.dart';
import 'package:scanner_app/providers/custom_scan_provider.dart';
import 'package:scanner_app/providers/custom_scan_state.dart';
import 'package:scanner_app/providers/ocr_provider.dart';
import 'package:scanner_app/providers/service_providers.dart';
import 'package:scanner_app/views/document_scan/widgets/document_scan_beam.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_enhance_bottom_bar.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_filter_visual_carousel.dart';
import 'package:scanner_app/views/ocr/ocr_result_view.dart';
import 'package:scanner_app/views/tools/signature_view.dart';

/// Clean, sleek, non-bulky CamScanner Pro document enhancement view.
/// Features lightweight 3D carousel, clean document elevation, compact filter cards,
/// and refined non-bulky icons.
class EnhanceStepView extends ConsumerStatefulWidget {
  const EnhanceStepView({super.key});

  @override
  ConsumerState<EnhanceStepView> createState() => _EnhanceStepViewState();
}

class _EnhanceStepViewState extends ConsumerState<EnhanceStepView> {
  static const Color _accent = Color(0xFF00D2A0);
  late PageController _pageController;
  int _scanTrigger = 1;
  String? _previousPath;
  int _carouselIndex = 0;

  @override
  void initState() {
    super.initState();
    final int initialPage = ref.read(customScanNotifierProvider).currentPageIndex;
    _carouselIndex = initialPage;
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: 0.86,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFilterSelected(ScanFilter filter) {
    setState(() {
      _scanTrigger++;
      _previousPath = ref.read(customScanNotifierProvider).warpedPath;
    });
    ref.read(customScanNotifierProvider.notifier).selectFilter(filter);
  }

  void _confirmDiscardScan() {
    showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181C23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Scan?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text(
          'Discard current document and return to home?',
          style: TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Discard',
              style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ).then((bool? confirmed) {
      if (confirmed == true && mounted) {
        ref.read(customScanNotifierProvider.notifier).resetSession();
        Navigator.of(context).pop();
      }
    });
  }

  void _showAddPageSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161920),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 32,
                height: 3.5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Add Page',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: _accent, size: 20),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                subtitle: const Text(
                  'Scan next page with camera',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(customScanNotifierProvider.notifier).addPageViaCamera();
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.white70, size: 20),
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                subtitle: const Text(
                  'Choose from device photos',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ref.read(customScanNotifierProvider.notifier).addPageViaGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(String currentTitle) {
    final TextEditingController controller = TextEditingController(text: currentTitle);
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Rename Document',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16.5),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: 'Enter document name',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _accent.withValues(alpha: 0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              final String trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                ref.read(customScanNotifierProvider.notifier).setDocumentTitle(trimmed);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save', style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _openFullscreenViewer(String imagePath, int rotationTurns) {
    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (BuildContext ctx) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.5,
                child: RotatedBox(
                  quarterTurns: rotationTurns,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 12,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDiscardPage(int index) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Page?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: const Text(
          'Are you sure you want to discard this page?',
          style: TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard',
                style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).then((bool? confirmed) {
      if (confirmed == true && mounted) {
        ref.read(customScanNotifierProvider.notifier).removePage(index);
        final int totalAfter = ref.read(customScanNotifierProvider).pages.length;
        if (totalAfter > 0) {
          final int nextIdx = index.clamp(0, totalAfter - 1);
          _pageController.animateToPage(
            nextIdx,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  Future<void> _onExtractText(String path, int rotationTurns) async {
    String finalPath = path;
    if (rotationTurns != 0) {
      finalPath = await ref.read(scanEnhanceServiceProvider).rotateImage(
            imagePath: path,
            angle: (rotationTurns * 90) % 360,
          );
    }
    ref.read(ocrNotifierProvider.notifier).extractTextFromImage(finalPath);
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const OcrResultView(),
        ),
      );
    }
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
    final List<ScanPageDraft> pages = scan.pages;

    if (pages.isEmpty && scan.warpedPath == null) {
      return const Center(
        child: Text(
          'No pages to display',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final int totalPages = pages.length;
    final bool isOnAddCard = _carouselIndex >= totalPages;
    final String currentTitle = scan.documentTitle ?? 'CamScanner Document';

    final String activePath = (!isOnAddCard && _carouselIndex < totalPages)
        ? pages[_carouselIndex].imagePath
        : (scan.warpedPath ?? (pages.isNotEmpty ? pages.first.imagePath : ''));

    final int activeRotation = (!isOnAddCard && _carouselIndex < totalPages)
        ? pages[_carouselIndex].rotationTurns
        : scan.rotationTurns;

    final ScanFilter activeFilter = (!isOnAddCard && _carouselIndex < totalPages)
        ? pages[_carouselIndex].filter
        : scan.selectedFilter;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1217),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Sleek Top Bar: Compact Back Button + Center Title Chip + "+ Page" chip
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
              child: Row(
                children: <Widget>[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: scan.busy ? null : _confirmDiscardScan,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 0.8),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Center: Document Title Chip
                  Expanded(
                    child: Center(
                      child: GestureDetector(
                        onTap: scan.busy ? null : () => _showRenameDialog(currentTitle),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  currentTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.edit_outlined,
                                color: _accent,
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Right: "+ Page" compact chip
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: scan.busy ? null : _showAddPageSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _accent.withValues(alpha: 0.35), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.add_rounded, color: _accent, size: 14),
                            SizedBox(width: 3),
                            Text(
                              'Page',
                              style: TextStyle(
                                color: _accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Document Center Preview Stage with 3D Cover-flow Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalPages + 1, // Document Pages + 1 "+ Add Pages" Card
                onPageChanged: (int index) {
                  setState(() => _carouselIndex = index);
                  if (index < totalPages) {
                    ref.read(customScanNotifierProvider.notifier).selectPage(index);
                  }
                },
                itemBuilder: (BuildContext context, int index) {
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (BuildContext context, Widget? child) {
                      double scale = 1.0;
                      double opacity = 1.0;
                      if (_pageController.position.haveDimensions) {
                        final double page = _pageController.page ?? _carouselIndex.toDouble();
                        final double diff = (page - index).abs();
                        scale = (1.0 - (diff * 0.07)).clamp(0.93, 1.0);
                        opacity = (1.0 - (diff * 0.30)).clamp(0.70, 1.0);
                      }
                      return Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: child,
                        ),
                      );
                    },
                    child: index == totalPages
                        ? _buildAddPagesCard(scan)
                        : _buildDocumentPageCard(
                            page: pages[index],
                            index: index,
                            totalPages: totalPages,
                            scanBusy: scan.busy,
                          ),
                  );
                },
              ),
            ),

            // Slender, Minimalist Page Pill
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF161920),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        if (_carouselIndex > 0) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: _carouselIndex > 0 ? Colors.white70 : Colors.white24,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnAddCard ? '+ Add Page' : '${_carouselIndex + 1} / $totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        if (_carouselIndex < totalPages) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: _carouselIndex < totalPages ? Colors.white70 : Colors.white24,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Compact Visual Filter Cards Carousel
            ScanFilterVisualCarousel(
              selected: activeFilter,
              onSelected: (ScanFilter filter) {
                if (scan.busy || isOnAddCard) return;
                _onFilterSelected(filter);
              },
            ),

            const SizedBox(height: 4),

            // Clean, non-bulky bottom action toolbar
            ScanEnhanceBottomBar(
              busy: scan.busy,
              pageCount: totalPages,
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
                _onExtractText(activePath, activeRotation);
              },
              onSign: _onSign,
              onConfirm: () {
                ref.read(customScanNotifierProvider.notifier).save();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds clean, non-bulky Document Page Card.
  Widget _buildDocumentPageCard({
    required ScanPageDraft page,
    required int index,
    required int totalPages,
    required bool scanBusy,
  }) {
    final String pageImgPath = page.imagePath;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.8,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.60),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                RotatedBox(
                  quarterTurns: page.rotationTurns,
                  child: DocumentScanBeam(
                    trigger: _scanTrigger,
                    imagePath: pageImgPath,
                    previousImagePath: _previousPath ?? page.rawPath,
                    duration: const Duration(milliseconds: 1350),
                  ),
                ),

                // Top-left: Small page tag
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 0.7),
                    ),
                    child: Text(
                      '${index + 1} / $totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                // Top-right: Discard Page Button (multi-page only)
                if (totalPages > 1)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: scanBusy ? null : () => _onDiscardPage(index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 0.7),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 15,
                        ),
                      ),
                    ),
                  ),

                // Bottom-right: Interactive Zoom Inspection
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _openFullscreenViewer(pageImgPath, page.rotationTurns),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(5.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 0.7),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white70,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a clean, minimalist "+ Add Pages" slide without bulky banners or giant buttons.
  Widget _buildAddPagesCard(CustomScanState scan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Center(
        child: GestureDetector(
          onTap: scan.busy ? null : _showAddPageSheet,
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: const _DashedBorderPainter(
              color: Color(0x5500D2A0),
              strokeWidth: 1.4,
              dashLength: 7.0,
              gapLength: 5.0,
              borderRadius: 16.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF14171E),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Subtle, elegant camera circle
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: _accent.withValues(alpha: 0.35), width: 1.0),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: _accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Add Next Page',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap anywhere to add next page',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Compact, clean chips row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      // Camera chip
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: scan.busy
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  ref.read(customScanNotifierProvider.notifier).addPageViaCamera();
                                },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _accent.withValues(alpha: 0.4), width: 0.9),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(Icons.camera_alt_rounded, color: _accent, size: 15),
                                SizedBox(width: 5),
                                Text(
                                  'Camera',
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Gallery chip
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: scan.busy
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  ref.read(customScanNotifierProvider.notifier).addPageViaGallery();
                                },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white12, width: 0.9),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(Icons.photo_library_outlined, color: Colors.white70, size: 15),
                                SizedBox(width: 5),
                                Text(
                                  'Gallery',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter to render clean dashed card border.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashedPath = Path();

    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double len = (distance + dashLength < metric.length)
            ? dashLength
            : metric.length - distance;
        dashedPath.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.gapLength != gapLength ||
      oldDelegate.borderRadius != borderRadius;
}
