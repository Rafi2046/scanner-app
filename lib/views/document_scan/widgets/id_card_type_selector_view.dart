import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/core/enums/id_card_category.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_mode_carousel.dart';

/// Full-screen ID card category selector matching the CamScanner reference UI.
/// Features realistic A4 paper mockup, watermark, category chips, and "Make it now" CTA.
class IdCardTypeSelectorView extends StatelessWidget {
  const IdCardTypeSelectorView({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onMakeItNow,
    required this.onClose,
    required this.onToggleFlash,
    required this.isFlashOn,
    required this.tabMode,
    required this.onTabModeChanged,
    required this.onOpenFeatures,
  });

  final IdCardCategory selectedCategory;
  final ValueChanged<IdCardCategory> onCategorySelected;
  final VoidCallback onMakeItNow;
  final VoidCallback onClose;
  final VoidCallback onToggleFlash;
  final bool isFlashOn;
  final ScanTabMode tabMode;
  final ValueChanged<ScanTabMode> onTabModeChanged;
  final VoidCallback onOpenFeatures;

  static const Color accentTeal = Color(0xFF00C292);

  void _showPrivacyInfo(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF181B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: <Widget>[
                    Icon(LucideIcons.shieldCheck, color: accentTeal, size: 26),
                    SizedBox(width: 12),
                    Text(
                      '100% Local & Secure',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Your privacy is our priority. All scanned ID documents and sensitive data are processed strictly on your local device. Nothing is ever uploaded to external servers or cloud storage without your explicit permission.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
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
    return Container(
      color: Colors.black,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            // 1. Top Bar (Close, Flash, HD toggle, More)
            _buildTopBar(context),

            // 2. Middle Content: A4 Paper Preview & Disclaimer
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // A4 Paper Mockup
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 8),
                      child: _A4PaperPreview(category: selectedCategory),
                    ),
                  ),

                  // Security disclaimer text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Text.rich(
                      TextSpan(
                        text:
                            'Scan ID documents anytime and export copies in one tap. Your ID info will not be synced and will be safely stored on your device. ',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.35,
                        ),
                        children: <InlineSpan>[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => _showPrivacyInfo(context),
                              child: const Text(
                                'Learn more >',
                                style: TextStyle(
                                  color: accentTeal,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Category Chips Row
            _buildCategoryChips(),

            const SizedBox(height: 14),

            // 4. "Make it now" CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onMakeItNow();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Make it now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 5. Scan Mode Carousel
            ScanModeCarousel(
              selectedMode: tabMode,
              onModeSelected: onTabModeChanged,
            ),

            // 6. Bottom Features / Grid button bar
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 16, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: onOpenFeatures,
                  icon: const Icon(LucideIcons.layoutGrid, color: Colors.white, size: 24),
                  tooltip: 'All Features',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            onPressed: onClose,
            icon: const Icon(LucideIcons.x, color: Colors.white, size: 24),
          ),
          Row(
            children: <Widget>[
              IconButton(
                onPressed: onToggleFlash,
                icon: Icon(
                  isFlashOn ? LucideIcons.zap : LucideIcons.zapOff,
                  color: isFlashOn ? Colors.amber : Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 4),
              // HD badge with indicator dot
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white54, width: 1.2),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'HD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 2),
                    Text(
                      '0',
                      style: TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _showPrivacyInfo(context),
                icon: const Icon(LucideIcons.moreHorizontal, color: Colors.white, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: IdCardCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final IdCardCategory cat = IdCardCategory.values[index];
          final bool isSelected = cat == selectedCategory;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onCategorySelected(cat);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF262626),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                cat.title,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Realistic A4 Paper container with dynamic mockup cards and subtle diagonal watermark.
class _A4PaperPreview extends StatelessWidget {
  const _A4PaperPreview({required this.category});

  final IdCardCategory category;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / 1.38,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // Diagonal watermark pattern across sheet
              const _WatermarkOverlay(),

              // Top-left badge "A4 paper example"
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'A4 paper example',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Mockup Card(s) in center
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
                child: category.isSingleSide
                    ? Center(child: _SingleCardMockup(category: category))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(child: _DualCardMockupSlot(category: category, isFront: true)),
                          const SizedBox(height: 12),
                          Expanded(child: _DualCardMockupSlot(category: category, isFront: false)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Diagonal repeating watermark ("For xxx purpose only")
class _WatermarkOverlay extends StatelessWidget {
  const _WatermarkOverlay();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(
        painter: _WatermarkPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  const _WatermarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-28 * math.pi / 180);

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: 'For xxx purpose only',
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.08),
          fontSize: 9.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const double stepY = 32.0;
    final double stepX = tp.width + 28.0;
    final double maxDim = math.sqrt(size.width * size.width + size.height * size.height);

    for (double y = -maxDim; y < maxDim; y += stepY) {
      final double xOffset = ((y / stepY).floor() % 2 == 0) ? 0 : (stepX / 2);
      for (double x = -maxDim; x < maxDim; x += stepX) {
        tp.paint(canvas, Offset(x + xOffset, y));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Front or back slot for 2-sided cards (General, Driver Licence, ID Card, Bank Card, etc.)
class _DualCardMockupSlot extends StatelessWidget {
  const _DualCardMockupSlot({
    required this.category,
    required this.isFront,
  });

  final IdCardCategory category;
  final bool isFront;

  @override
  Widget build(BuildContext context) {
    final String cardHeader = switch (category) {
      IdCardCategory.autoInsurance => 'INSURANCE IDENTIFICATION CARD',
      IdCardCategory.driverLicense => 'DRIVER LICENSE',
      IdCardCategory.idCard => 'NATIONAL IDENTITY CARD',
      IdCardCategory.bankCard => 'BANKING CARD',
      IdCardCategory.ssn => 'SOCIAL SECURITY',
      _ => 'IDENTIFICATION CARD',
    };

    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: isFront
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Header band
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      cardHeader,
                      style: const TextStyle(
                        fontSize: 6,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  // Content: Photo + lines
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        // Avatar photo box
                        Container(
                          width: 26,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Icon(
                            LucideIcons.user,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Field lines
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              _line(widthFraction: 0.7, color: const Color(0xFFCBD5E1)),
                              _line(widthFraction: 0.9, color: const Color(0xFFE2E8F0)),
                              _line(widthFraction: 0.5, color: const Color(0xFFE2E8F0)),
                              _line(widthFraction: 0.8, color: const Color(0xFFE2E8F0)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Signature line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Container(width: 40, height: 1, color: const Color(0xFF94A3B8)),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Magnetic strip or disclaimer header
                  Container(
                    width: double.infinity,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Signature band
                  Container(
                    width: double.infinity,
                    height: 8,
                    color: const Color(0xFFF1F5F9),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(width: 24, height: 1, color: const Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 6),
                  // Back lines
                  _line(widthFraction: 0.9, color: const Color(0xFFCBD5E1)),
                  const SizedBox(height: 3),
                  _line(widthFraction: 0.7, color: const Color(0xFFE2E8F0)),
                  const Spacer(),
                  // Barcode placeholder
                  Row(
                    children: List<Widget>.generate(14, (int idx) {
                      return Container(
                        width: idx % 3 == 0 ? 2 : 1,
                        height: 8,
                        margin: const EdgeInsets.only(right: 2),
                        color: const Color(0xFF64748B),
                      );
                    }),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _line({required double widthFraction, required Color color}) {
    return FractionallySizedBox(
      widthFactor: widthFraction,
      child: Container(
        height: 3.5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1.5),
        ),
      ),
    );
  }
}

/// Single card / document mockup for Passport or Certificate
class _SingleCardMockup extends StatelessWidget {
  const _SingleCardMockup({required this.category});

  final IdCardCategory category;

  @override
  Widget build(BuildContext context) {
    final bool isPassport = category == IdCardCategory.passport;

    return AspectRatio(
      aspectRatio: isPassport ? 1.4 : 1.3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPassport ? const Color(0xFF0F172A) : const Color(0xFFD97706),
            width: 1.5,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  isPassport ? LucideIcons.globe : LucideIcons.award,
                  size: 14,
                  color: isPassport ? const Color(0xFF0F172A) : const Color(0xFFD97706),
                ),
                const SizedBox(width: 4),
                Text(
                  isPassport ? 'PASSPORT' : 'OFFICIAL CERTIFICATE',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: isPassport ? const Color(0xFF0F172A) : const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Content
            Expanded(
              child: Row(
                children: <Widget>[
                  // Photo / Seal
                  Container(
                    width: 38,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      isPassport ? LucideIcons.user : LucideIcons.stamp,
                      size: 20,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Details lines
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Container(height: 4, width: 80, color: const Color(0xFF94A3B8)),
                        Container(height: 3, width: 100, color: const Color(0xFFCBD5E1)),
                        Container(height: 3, width: 70, color: const Color(0xFFE2E8F0)),
                        Container(height: 3, width: 90, color: const Color(0xFFE2E8F0)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // MRZ code lines for passport or seal for certificate
            if (isPassport)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                color: const Color(0xFFF8FAFC),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'P<USAEXAMPLE<<CARD<<<<<<<<<<<<<<<<<<<<<<<<<<',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 4.8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    Text(
                      '9999999990USA9001018M3001014<<<<<<<<<<<<<<<4',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 4.8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(width: 40, height: 1, color: const Color(0xFFD97706)),
                  const Icon(LucideIcons.stamp, size: 14, color: Color(0xFFD97706)),
                  Container(width: 40, height: 1, color: const Color(0xFFD97706)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
