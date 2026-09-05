import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/models/scanned_document.dart';
import 'package:scanner_app/providers/library_provider.dart';
import 'package:scanner_app/providers/ocr_provider.dart';
import 'package:scanner_app/views/widgets/error_snackbar.dart';

/// Ultra-premium full-screen AI OCR Reader & Tool View.
class OcrResultView extends ConsumerStatefulWidget {
  const OcrResultView({super.key});

  @override
  ConsumerState<OcrResultView> createState() => _OcrResultViewState();
}

class _OcrResultViewState extends ConsumerState<OcrResultView> {
  static const Color _bgDark = Color(0xFF101318);
  static const Color _surfaceDark = Color(0xFF191D26);
  static const Color _accentMint = Color(0xFF00D2A0);

  double _fontSize = 15.0;
  bool _copied = false;

  void _onCopy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E2430),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: <Widget>[
            Icon(Icons.check_circle_rounded, color: _accentMint, size: 20),
            SizedBox(width: 10),
            Text(
              'Extracted text copied to clipboard!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _showDocumentPickerSheet(List<ScannedDocument> docs) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF161A22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Choose Scanned Document',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white54),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No scanned pages available in library.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final ScannedDocument doc = docs[index];
                        return ListTile(
                          tileColor: const Color(0xFF202633),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _accentMint.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.document_scanner_rounded,
                              color: _accentMint,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            doc.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${doc.pageCount} page(s)',
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white38,
                            size: 14,
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            ref
                                .read(ocrNotifierProvider.notifier)
                                .extractTextFromImage(doc.imagePaths.first);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    listenAsyncError(ref, ocrNotifierProvider, context);
    final AsyncValue<String?> ocr = ref.watch(ocrNotifierProvider);
    final String? text = ocr.valueOrNull?.trim();
    final bool hasText = text != null && text.isNotEmpty && text != 'No text found.';
    final bool isLoading = ocr.isLoading;

    final List<ScannedDocument> withImages = ref
            .watch(libraryNotifierProvider)
            .valueOrNull
            ?.where((ScannedDocument d) => d.imagePaths.isNotEmpty)
            .toList() ??
        const <ScannedDocument>[];

    final int wordCount = hasText
        ? text.split(RegExp(r'\s+')).where((String s) => s.isNotEmpty).length
        : 0;
    final int charCount = hasText ? text.length : 0;

    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: _bgDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Flexible(
              child: Text(
                'AI OCR Text',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 17,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF00E6B0), Color(0xFF009688)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'AI',
                style: TextStyle(
                  color: Color(0xFF0A1015),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          if (hasText) ...<Widget>[
            // Compact Font Size Control Pill
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2430),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    InkWell(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      onTap: () {
                        if (_fontSize > 11) {
                          setState(() => _fontSize -= 2);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        child: Text(
                          'A-',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    Container(width: 1, height: 14, color: Colors.white24),
                    InkWell(
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
                      onTap: () {
                        if (_fontSize < 24) {
                          setState(() => _fontSize += 2);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        child: Text(
                          'A+',
                          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            tooltip: 'Choose another image',
            icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white70, size: 22),
            onPressed: isLoading
                ? null
                : () => ref.read(ocrNotifierProvider.notifier).pickImageAndExtract(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Extraction In Progress State
            if (isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accentMint.withValues(alpha: 0.1),
                          border: Border.all(color: _accentMint.withValues(alpha: 0.4), width: 1.5),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: _accentMint.withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.8,
                          color: _accentMint,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Extracting Text with On-Device AI…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Accurately recognizing characters, words & numbers',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            // Extracted Text Present - HERO FULL SCREEN READER
            else if (hasText)
              Expanded(
                child: Column(
                  children: <Widget>[
                    // Quick Stats Pill Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: <Widget>[
                            _StatsChip(
                              icon: Icons.text_snippet_outlined,
                              label: '$wordCount Words',
                            ),
                            const SizedBox(width: 8),
                            _StatsChip(
                              icon: Icons.sort_by_alpha_rounded,
                              label: '$charCount Characters',
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B222E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _accentMint.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(Icons.bolt_rounded, color: _accentMint, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    '100% Offline',
                                    style: TextStyle(
                                      color: _accentMint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Full-Screen Scrollable Selectable Text Card
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: _surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            physics: const BouncingScrollPhysics(),
                            child: SelectableText(
                              text,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: _fontSize,
                                height: 1.6,
                                letterSpacing: 0.2,
                                fontWeight: FontWeight.w400,
                              ),
                              selectionControls: MaterialTextSelectionControls(),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Floating Bottom Action Bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFF14171E),
                        border: Border(
                          top: BorderSide(color: Color(0xFF222834), width: 1),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          // Option to pick from existing scanned pages
                          OutlinedButton.icon(
                            onPressed: () => _showDocumentPickerSheet(withImages),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                            icon: const Icon(Icons.folder_open_outlined, color: Colors.white70, size: 18),
                            label: const Text(
                              'Library',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Primary Glow "Copy All Text" Button
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _onCopy(text),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: <Color>[Color(0xFF00E6B0), Color(0xFF00B388)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: _accentMint.withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(
                                          _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                          color: const Color(0xFF0A1015),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _copied ? 'Copied!' : 'Copy All Text',
                                          style: const TextStyle(
                                            color: Color(0xFF0A1015),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            // Empty / Initial State (If user opened from Tools without prior scan)
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accentMint.withValues(alpha: 0.12),
                          border: Border.all(color: _accentMint.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: const Icon(
                          Icons.document_scanner_outlined,
                          color: _accentMint,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No Text Extracted Yet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pick an image or choose a scanned document to instantly recognize and extract all text.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13.5, height: 1.4),
                      ),
                      const SizedBox(height: 28),
                      // Primary Button to pick from gallery / files
                      ElevatedButton.icon(
                        onPressed: () => ref.read(ocrNotifierProvider.notifier).pickImageAndExtract(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentMint,
                          foregroundColor: const Color(0xFF0A1015),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.add_photo_alternate_rounded, size: 20),
                        label: const Text(
                          'Pick Image from Files',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (withImages.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _showDocumentPickerSheet(withImages),
                          icon: const Icon(Icons.history_rounded, color: Colors.white70, size: 18),
                          label: const Text(
                            'Or choose from scanned library',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatsChip extends StatelessWidget {
  const _StatsChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B222E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: Colors.white60, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
