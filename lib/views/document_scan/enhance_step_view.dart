import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/core/enums/id_scan_side.dart';
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

/// Clean, sleek, full-screen CamScanner document enhancement view.
/// Pages occupy 100% viewport width without chopped edge-peeks,
/// with real document aspect ratios and minimal, non-bulky controls.
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
  int _selectedIdSideIndex = 0;
  double? _baseDocumentAspectRatio;
  String? _lastResolvedPath;

  /// Rapid synchronous JPEG header dimension reader.
  static Size? _getJpegSize(String path) {
    try {
      final File file = File(path);
      if (!file.existsSync()) return null;
      final RandomAccessFile raf = file.openSync(mode: FileMode.read);
      try {
        final Uint8List header = raf.readSync(math.min(4096, raf.lengthSync()));
        if (header.length < 4 || header[0] != 0xFF || header[1] != 0xD8) {
          return null;
        }
        int i = 2;
        while (i < header.length - 8) {
          if (header[i] != 0xFF) {
            i++;
            continue;
          }
          final int marker = header[i + 1];
          if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
            final int h = (header[i + 5] << 8) | header[i + 6];
            final int w = (header[i + 7] << 8) | header[i + 8];
            if (w > 0 && h > 0) return Size(w.toDouble(), h.toDouble());
          }
          if (i + 3 >= header.length) break;
          final int len = (header[i + 2] << 8) | header[i + 3];
          if (len <= 0) break;
          i += 2 + len;
        }
      } finally {
        raf.closeSync();
      }
    } catch (_) {}
    return null;
  }

  void _resolveDocumentAspectRatio(String path) {
    if (path.isEmpty || path == _lastResolvedPath) return;
    _lastResolvedPath = path;

    // 1. Fast synchronous JPEG dimension extraction
    final Size? size = _getJpegSize(path);
    if (size != null && size.width > 0 && size.height > 0) {
      final double ratio = size.width / size.height;
      if (_baseDocumentAspectRatio != ratio) {
        _baseDocumentAspectRatio = ratio;
      }
      return;
    }

    // 2. Fallback to Flutter ImageStream
    if (!File(path).existsSync()) return;
    final Image image = Image.file(File(path));
    image.image.resolve(ImageConfiguration.empty).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          final double w = info.image.width.toDouble();
          final double h = info.image.height.toDouble();
          if (w > 0 && h > 0) {
            final double ratio = w / h;
            if (mounted && (_baseDocumentAspectRatio == null || (_baseDocumentAspectRatio! - ratio).abs() > 0.005)) {
              setState(() {
                _baseDocumentAspectRatio = ratio;
              });
            }
          }
        },
        onError: (Object error, StackTrace? stackTrace) {},
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final int initialPage = ref.read(customScanNotifierProvider).currentPageIndex;
    _carouselIndex = initialPage;
    _pageController = PageController(
      initialPage: initialPage,
      viewportFraction: 1.0, // 100% full-screen page presentation, zero chopped edge-peeks
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    _lastResolvedPath = null;
    // Recreate controller on hot reload to force viewportFraction 1.0
    final int curr = _pageController.hasClients
        ? (_pageController.page?.round() ?? _carouselIndex)
        : _carouselIndex;
    _pageController.dispose();
    _pageController = PageController(
      initialPage: curr,
      viewportFraction: 1.0,
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

    final bool isIdCardMode = scan.mode == CustomScanMode.idCard;

    final ScanPageDraft? frontDraft = pages.where((ScanPageDraft p) => p.idSide == IdScanSide.front).firstOrNull ??
        (pages.isNotEmpty ? pages.first : null);
    final ScanPageDraft? backDraft = pages.where((ScanPageDraft p) => p.idSide == IdScanSide.back).firstOrNull ??
        (pages.length > 1 ? pages[1] : null);

    final ScanPageDraft? activeDraft = isIdCardMode
        ? (_selectedIdSideIndex == 1 && backDraft != null ? backDraft : frontDraft)
        : ((!isOnAddCard && _carouselIndex < totalPages) ? pages[_carouselIndex] : null);

    final String activePath = activeDraft != null
        ? activeDraft.imagePath
        : (scan.warpedPath ?? (pages.isNotEmpty ? pages.first.imagePath : ''));

    final int activeRotation = activeDraft?.rotationTurns ?? scan.rotationTurns;

    final ScanFilter activeFilter = activeDraft?.filter ?? scan.selectedFilter;

    if (activePath.isNotEmpty) {
      _resolveDocumentAspectRatio(activePath);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F1217),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Ultra-Premium Symmetrical Top Navigation Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F1217),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 0.8,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: <Widget>[
                  // Left: Modern Frosted Back Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: scan.busy
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _confirmDiscardScan();
                            },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Center: Document Title & Live Status
                  Expanded(
                    child: GestureDetector(
                      onTap: scan.busy
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              _showRenameDialog(currentTitle);
                            },
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  currentTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Icon(
                                Icons.edit_outlined,
                                color: _accent.withValues(alpha: 0.85),
                                size: 13,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isIdCardMode
                                ? (scan.canSaveIdCard
                                    ? '${scan.idCategory.title} · A4 Sheet Preview'
                                    : (scan.idCategory.isSingleSide
                                        ? '${scan.idCategory.title} · A4 Sheet Preview'
                                        : '${scan.idCategory.title} · Front Saved, Tap Back to Scan'))
                                : (isOnAddCard
                                    ? 'Add new page'
                                    : 'Page ${_carouselIndex + 1} of $totalPages · Tap to rename'),
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right: Balanced More Options Menu Button
                  PopupMenuButton<String>(
                    tooltip: 'More options',
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF1B1E26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                        width: 0.8,
                      ),
                    ),
                    onSelected: (String value) {
                      HapticFeedback.lightImpact();
                      if (value == 'rename') {
                        _showRenameDialog(currentTitle);
                      } else if (value == 'fullscreen') {
                        _openFullscreenViewer(activePath, activeRotation);
                      } else if (value == 'discard') {
                        _confirmDiscardScan();
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'rename',
                        height: 40,
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.drive_file_rename_outline_rounded, color: _accent, size: 17),
                            SizedBox(width: 10),
                            Text(
                              'Rename Document',
                              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'fullscreen',
                        height: 40,
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 18),
                            SizedBox(width: 10),
                            Text(
                              'Fullscreen View',
                              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(height: 1),
                      const PopupMenuItem<String>(
                        value: 'discard',
                        height: 40,
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.delete_outline_rounded, color: Color(0xFFFF5252), size: 17),
                            SizedBox(width: 10),
                            Text(
                              'Discard Scan',
                              style: TextStyle(color: Color(0xFFFF5252), fontSize: 13.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white70,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Document Center Preview Stage:
            // For ID Card: Renders an authentic A4 Paper Stage with Front on top and Back on bottom (Image 2 style).
            // For Document: Renders 100% full-screen width PageView with swipeable cards.
            Expanded(
              child: isIdCardMode
                  ? _buildIdCardA4Stage(
                      context: context,
                      scan: scan,
                      frontDraft: frontDraft,
                      backDraft: backDraft,
                    )
                  : PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: totalPages + 1, // Document Pages + 1 "+ Add Pages" Card
                      onPageChanged: (int index) {
                        setState(() => _carouselIndex = index);
                        if (index < totalPages) {
                          ref.read(customScanNotifierProvider.notifier).selectPage(index);
                        }
                      },
                      itemBuilder: (BuildContext context, int index) {
                        final double baseRatio = _baseDocumentAspectRatio ?? (1 / 1.414);
                        if (index == totalPages) {
                          final int lastRotation = pages.isNotEmpty ? pages.last.rotationTurns : 0;
                          final double addPageRatio = (lastRotation % 2 == 1) ? (1.0 / baseRatio) : baseRatio;
                          return _buildAddPagesCard(scan, addPageRatio);
                        }
                        final double pageRatio = (pages[index].rotationTurns % 2 == 1) ? (1.0 / baseRatio) : baseRatio;
                        return _buildDocumentPageCard(
                          page: pages[index],
                          index: index,
                          totalPages: totalPages,
                          scanBusy: scan.busy,
                          aspectRatio: pageRatio,
                        );
                      },
                    ),
            ),

            // Slender, Minimalist Page Pill / Status Pill (hidden on Add Page card to remove redundant text)
            AnimatedOpacity(
              opacity: isOnAddCard ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161920),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10, width: 0.8),
                  ),
                  child: isIdCardMode
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedIdSideIndex = 0);
                                if (frontDraft != null) {
                                  ref.read(customScanNotifierProvider.notifier).selectPage(scan.pages.indexOf(frontDraft));
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _selectedIdSideIndex == 0 ? _accent.withValues(alpha: 0.22) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Front Side',
                                  style: TextStyle(
                                    color: _selectedIdSideIndex == 0 ? _accent : Colors.white60,
                                    fontSize: 11.5,
                                    fontWeight: _selectedIdSideIndex == 0 ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            if (!scan.idCategory.isSingleSide) ...<Widget>[
                              const SizedBox(width: 4),
                              Container(width: 1, height: 12, color: Colors.white24),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {
                                  if (backDraft != null) {
                                    setState(() => _selectedIdSideIndex = 1);
                                    ref.read(customScanNotifierProvider.notifier).selectPage(scan.pages.indexOf(backDraft));
                                  } else {
                                    ref.read(customScanNotifierProvider.notifier).prepareScanBackSide();
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _selectedIdSideIndex == 1 ? _accent.withValues(alpha: 0.22) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    backDraft != null ? 'Back Side' : '+ Add Back',
                                    style: TextStyle(
                                      color: _selectedIdSideIndex == 1 ? _accent : Colors.white60,
                                      fontSize: 11.5,
                                      fontWeight: _selectedIdSideIndex == 1 ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
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
                              '${_carouselIndex + 1} / $totalPages',
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
            ),

            // Inactive grayed-out state when on "+ Add Page":
            // Visibly disabled (grayscale + 32% opacity) so user immediately sees
            // that filters and toolbar tools cannot be tapped on this empty sheet.
            IgnorePointer(
              ignoring: isOnAddCard,
              child: AnimatedOpacity(
                opacity: isOnAddCard ? 0.30 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: ColorFiltered(
                  colorFilter: isOnAddCard
                      ? const ColorFilter.matrix(<double>[
                          0.2126, 0.7152, 0.0722, 0, 0, // Red to grayscale
                          0.2126, 0.7152, 0.0722, 0, 0, // Green to grayscale
                          0.2126, 0.7152, 0.0722, 0, 0, // Blue to grayscale
                          0,      0,      0,      1, 0, // Alpha
                        ])
                      : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
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
                        pageCount: isIdCardMode ? (scan.canSaveIdCard ? 2 : 1) : totalPages,
                        onRetake: () {
                          if (isIdCardMode) {
                            if (_selectedIdSideIndex == 1 && backDraft != null) {
                              ref.read(customScanNotifierProvider.notifier).prepareScanBackSide();
                            } else {
                              ref.read(customScanNotifierProvider.notifier).goToCapture();
                            }
                          } else {
                            ref.read(customScanNotifierProvider.notifier).goToCapture();
                          }
                        },
                        onRotateLeft: () {
                          if (isIdCardMode) {
                            final int targetIdx = (_selectedIdSideIndex == 1 && backDraft != null)
                                ? pages.indexOf(backDraft)
                                : (frontDraft != null ? pages.indexOf(frontDraft) : 0);
                            if (targetIdx >= 0) {
                              ref.read(customScanNotifierProvider.notifier).selectPage(targetIdx);
                            }
                          }
                          ref.read(customScanNotifierProvider.notifier).rotateLeft();
                        },
                        onCrop: () {
                          if (isIdCardMode) {
                            final int targetIdx = (_selectedIdSideIndex == 1 && backDraft != null)
                                ? pages.indexOf(backDraft)
                                : (frontDraft != null ? pages.indexOf(frontDraft) : 0);
                            if (targetIdx >= 0) {
                              ref.read(customScanNotifierProvider.notifier).selectPage(targetIdx);
                            }
                          }
                          ref.read(customScanNotifierProvider.notifier).goToCrop();
                        },
                        onExtractText: () {
                          _onExtractText(activePath, activeRotation);
                        },
                        onSign: _onSign,
                        onConfirm: () {
                          final CustomScanState scanState = ref.read(customScanNotifierProvider);
                          if (scanState.mode == CustomScanMode.idCard &&
                              !scanState.idCategory.isSingleSide &&
                              !scanState.canSaveIdCard) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Front side saved! Now scan the back side.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            ref.read(customScanNotifierProvider.notifier).prepareScanBackSide();
                          } else {
                            ref.read(customScanNotifierProvider.notifier).save();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds authentic A4 Paper Stage for ID Card mode with Front on top and Back on bottom (Image 2 style).
  Widget _buildIdCardA4Stage({
    required BuildContext context,
    required CustomScanState scan,
    required ScanPageDraft? frontDraft,
    required ScanPageDraft? backDraft,
  }) {
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        final double availW = constraints.maxWidth - 44;
        final double availH = constraints.maxHeight - 20;
        double sheetW = availW;
        double sheetH = sheetW * 1.414;
        if (sheetH > availH) {
          sheetH = availH;
          sheetW = sheetH / 1.414;
        }

        // Exact 55% card width matching reference photocopy (Image 2)
        final double cardW = sheetW * 0.55;
        final double cardH = cardW / 1.586;
        final double cardRadius = math.max(6.0, cardW * 0.038);
        final bool isSingleSide = scan.idCategory.isSingleSide;

        return Center(
          child: Container(
            width: sheetW,
            height: sheetH,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.50),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: isSingleSide
                ? Center(
                    child: _buildIdCardSlot(
                      draft: frontDraft,
                      width: cardW,
                      height: cardH,
                      radius: cardRadius,
                      isSelected: true,
                      onTap: () {
                        setState(() => _selectedIdSideIndex = 0);
                        if (frontDraft != null) {
                          ref.read(customScanNotifierProvider.notifier).selectPage(scan.pages.indexOf(frontDraft));
                        }
                      },
                    ),
                  )
                : Stack(
                    children: <Widget>[
                      // Front Card (Top, centered horizontally at y = 12.5%):
                      Positioned(
                        top: sheetH * 0.125,
                        left: (sheetW - cardW) / 2,
                        child: _buildIdCardSlot(
                          draft: frontDraft,
                          width: cardW,
                          height: cardH,
                          radius: cardRadius,
                          isSelected: _selectedIdSideIndex == 0,
                          onTap: () {
                            setState(() => _selectedIdSideIndex = 0);
                            if (frontDraft != null) {
                              ref.read(customScanNotifierProvider.notifier).selectPage(scan.pages.indexOf(frontDraft));
                            }
                          },
                        ),
                      ),
                      // Back Card (Bottom, centered horizontally at y = 53.5%):
                      Positioned(
                        top: sheetH * 0.535,
                        left: (sheetW - cardW) / 2,
                        child: backDraft != null
                            ? _buildIdCardSlot(
                                draft: backDraft,
                                width: cardW,
                                height: cardH,
                                radius: cardRadius,
                                isSelected: _selectedIdSideIndex == 1,
                                onTap: () {
                                  setState(() => _selectedIdSideIndex = 1);
                                  ref.read(customScanNotifierProvider.notifier).selectPage(scan.pages.indexOf(backDraft));
                                },
                              )
                            : _buildIdCardPlaceholder(
                                context: context,
                                width: cardW,
                                height: cardH,
                                radius: cardRadius,
                              ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildIdCardSlot({
    required ScanPageDraft? draft,
    required double width,
    required double height,
    required double radius,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    if (draft == null) {
      return SizedBox(width: width, height: height);
    }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: isSelected ? _accent.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.10),
            width: isSelected ? 1.4 : 0.8,
          ),
          boxShadow: <BoxShadow>[
            if (isSelected)
              BoxShadow(
                color: _accent.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1.5,
                offset: const Offset(0, 2),
              ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.12 : 0.07),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 0.5),
          child: RotatedBox(
            quarterTurns: draft.rotationTurns,
            child: DocumentScanBeam(
              trigger: _scanTrigger,
              imagePath: draft.imagePath,
              previousImagePath: _previousPath ?? draft.rawPath,
              duration: const Duration(milliseconds: 1350),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdCardPlaceholder({
    required BuildContext context,
    required double width,
    required double height,
    required double radius,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(customScanNotifierProvider.notifier).prepareScanBackSide();
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: _accent.withValues(alpha: 0.55),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: _accent,
                  size: 16,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                '+ Scan Back Side',
                style: TextStyle(
                  color: Color(0xFF1E242B),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 1),
              const Text(
                'Tap here to capture',
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds full-screen width Document Page Card.
  Widget _buildDocumentPageCard({
    required ScanPageDraft page,
    required int index,
    required int totalPages,
    required bool scanBusy,
    required double aspectRatio,
  }) {
    final String pageImgPath = page.imagePath;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 0.7),
                    ),
                    child: Text(
                      '${index + 1} / $totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
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
                          color: Colors.black.withValues(alpha: 0.70),
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.70),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 0.7),
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  /// Builds a clean, full-size "+ Add Pages" sheet card with real document aspect ratio.
  Widget _buildAddPagesCard(CustomScanState scan, double aspectRatio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: GestureDetector(
            onTap: scan.busy ? null : _showAddPageSheet,
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              foregroundPainter: const _DashedBorderPainter(
                color: Color(0xCC00D2A0),
                strokeWidth: 1.8,
                dashLength: 7.0,
                gapLength: 5.0,
                borderRadius: 12.0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF14171E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _accent.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: _accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        'Photograph or import the next page\ninto this document',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // Camera Chip
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _accent.withValues(alpha: 0.45), width: 1.0),
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
                          const SizedBox(width: 10),

                          // Gallery Chip
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
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white12, width: 1.0),
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

    final double inset = strokeWidth / 2.0;
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
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
