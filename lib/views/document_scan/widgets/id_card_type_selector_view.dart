import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/core/enums/id_card_category.dart';
import 'package:scanner_app/views/document_scan/widgets/scan_mode_carousel.dart';

/// Full-screen ID card category selector matching the app's premium dark glassmorphism design.
///
/// Features:
/// - Distinctive, authentic real-world preview for all 8 categories (Driver License, National ID,
///   Passport booklet, Bank Card, Certificate, SSN, Auto Insurance, General).
/// - Dynamic animated A4 paper mockup with realistic watermarks and shadows.
/// - Vibrant category chips with custom icons and glowing active states.
/// - Premium "Make it now" action button.
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
      backgroundColor: const Color(0xFF141822),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                  'Your privacy is our utmost priority. All scanned ID documents and sensitive data are processed strictly on your local device. Nothing is ever uploaded to external servers or cloud storage without your explicit permission.',
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
                      foregroundColor: const Color(0xFF052016),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0E121A),
            Color(0xFF05070A),
            Colors.black,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            // 1. Top Bar (Close, Flash, HD indicator, Privacy info)
            _buildTopBar(context),

            // 2. Middle Content: Dynamic A4 Paper Preview & Disclaimer
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // A4 Paper Mockup with dynamic category preview
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 6),
                      child: _A4PaperPreview(category: selectedCategory),
                    ),
                  ),

                  // Security disclaimer card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121620).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(LucideIcons.shieldCheck, color: accentTeal, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text:
                                  'Scan ID documents anytime. Your data stays safe on device. ',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
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
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Category Chips Carousel
            _buildCategoryChips(),

            const SizedBox(height: 12),

            // 4. "Make it now" CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF00D2A0), Color(0xFF00A87E)],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: accentTeal.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onMakeItNow();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: const Color(0xFF052016),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(LucideIcons.camera, size: 18, color: Color(0xFF052016)),
                        SizedBox(width: 8),
                        Text(
                          'Make it now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                            color: Color(0xFF052016),
                          ),
                        ),
                      ],
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

  IconData _getCategoryIcon(IdCardCategory cat) {
    return switch (cat) {
      IdCardCategory.general => LucideIcons.fileText,
      IdCardCategory.driverLicense => LucideIcons.car,
      IdCardCategory.idCard => LucideIcons.contact2,
      IdCardCategory.passport => LucideIcons.globe,
      IdCardCategory.bankCard => LucideIcons.creditCard,
      IdCardCategory.certificate => LucideIcons.award,
      IdCardCategory.ssn => LucideIcons.shieldCheck,
      IdCardCategory.autoInsurance => LucideIcons.shield,
    };
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 44,
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
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: <Color>[Color(0xFF00D2A0), Color(0xFF00A87E)],
                      )
                    : null,
                color: isSelected ? null : const Color(0xFF161A24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00D2A0) : Colors.white.withValues(alpha: 0.12),
                  width: isSelected ? 1.4 : 0.8,
                ),
                boxShadow: isSelected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: accentTeal.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _getCategoryIcon(cat),
                    size: 15,
                    color: isSelected ? const Color(0xFF052016) : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.title,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF052016) : Colors.white,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
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
              color: const Color(0xFF00C292).withValues(alpha: 0.14),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 18,
              offset: const Offset(0, 10),
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
                    color: const Color(0xFF475569).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'A4 paper example',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              // Mockup Card(s) in center - Smoothly transitions per category
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 32, 14, 14),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<IdCardCategory>(category),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 250,
                          height: 350,
                          child: _buildCategoryMockup(category),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryMockup(IdCardCategory cat) {
    return switch (cat) {
      IdCardCategory.driverLicense => const _DriverLicenseMockup(),
      IdCardCategory.idCard => const _NationalIdMockup(),
      IdCardCategory.passport => const _PassportBookletMockup(),
      IdCardCategory.bankCard => const _BankCardMockup(),
      IdCardCategory.certificate => const _CertificateMockup(),
      IdCardCategory.ssn => const _SsnCardMockup(),
      IdCardCategory.autoInsurance => const _AutoInsuranceMockup(),
      IdCardCategory.general => const _GeneralDocumentMockup(),
    };
  }
}

// ---------------------------------------------------------------------------
// 1. DRIVER LICENSE MOCKUP (Realistic Front & Back)
// ---------------------------------------------------------------------------
class _DriverLicenseMockup extends StatelessWidget {
  const _DriverLicenseMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Front Side
        Expanded(
          child: _mockupCardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Blue State Header with Gold Star
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'STATE DRIVER LICENSE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          Icon(Icons.star, color: Color(0xFFFBBF24), size: 8),
                          SizedBox(width: 2),
                          Text(
                            'REAL ID',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                // Driver photo and fields
                Expanded(
                  child: Row(
                    children: <Widget>[
                      // Photo box
                      Container(
                        width: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF93C5FD), width: 0.8),
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.user, size: 16, color: Color(0xFF2563EB)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Fields
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            const Text(
                              'DL: D9410294-A',
                              style: TextStyle(
                                fontSize: 6.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            const Text(
                              'DOB: 08/24/1992 • EXP: 08/24/2028',
                              style: TextStyle(fontSize: 5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                            ),
                            const Text(
                              'DOE, JONATHAN MICHAEL',
                              style: TextStyle(fontSize: 5.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const Text(
                              'CLASS: C  SEX: M  HGT: 5-11',
                              style: TextStyle(fontSize: 4.8, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                            Container(
                              width: 36,
                              height: 1,
                              color: const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Back Side
        Expanded(
          child: _mockupCardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Magnetic Swipe Stripe
                Container(
                  width: double.infinity,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 5),
                // Organ donor & 2D Barcode grid
                Expanded(
                  child: Row(
                    children: <Widget>[
                      // Left info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            const Row(
                              children: <Widget>[
                                Icon(Icons.favorite, color: Color(0xFFDC2626), size: 8),
                                SizedBox(width: 3),
                                Text(
                                  'ORGAN DONOR',
                                  style: TextStyle(fontSize: 5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                                ),
                              ],
                            ),
                            const Text(
                              'RESTRICTIONS: NONE\nENDORSEMENTS: PASSENGER',
                              style: TextStyle(fontSize: 4.5, color: Color(0xFF64748B), height: 1.2),
                            ),
                            // Linear 1D barcode
                            Row(
                              children: List<Widget>.generate(16, (int i) {
                                return Container(
                                  width: i % 3 == 0 ? 1.8 : 1,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 1.2),
                                  color: const Color(0xFF334155),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // 2D PDF417 dense barcode
                      Container(
                        width: 34,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 0.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List<Widget>.generate(6, (int i) {
                            return Container(
                              height: 1.8,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              color: const Color(0xFF334155),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. NATIONAL ID CARD MOCKUP (Front & Back with Chip, Crest, MRZ)
// ---------------------------------------------------------------------------
class _NationalIdMockup extends StatelessWidget {
  const _NationalIdMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Front Side
        Expanded(
          child: _mockupCardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Teal National Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Row(
                    children: <Widget>[
                      Icon(LucideIcons.shield, color: Colors.white, size: 7),
                      SizedBox(width: 4),
                      Text(
                        'NATIONAL IDENTITY CARD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6.2,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                // Photo + Chip + Citizen info
                Expanded(
                  child: Row(
                    children: <Widget>[
                      // Photo
                      Container(
                        width: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.user, size: 16, color: Color(0xFF059669)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Fields + Gold Chip
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text(
                                  'ID: 840 291 049 11',
                                  style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                                // Smart EMV Chip
                                Container(
                                  width: 14,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFBBF24),
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(color: const Color(0xFFD97706), width: 0.5),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 6,
                                      height: 4,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'NAME: SARAH J. CONNER',
                              style: TextStyle(fontSize: 5.5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                            ),
                            const Text(
                              'DOB: 12 NOV 1990  •  NATIONALITY: USA',
                              style: TextStyle(fontSize: 4.8, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  'VALID: 2024 - 2034',
                                  style: TextStyle(fontSize: 4.8, color: Color(0xFF059669), fontWeight: FontWeight.w700),
                                ),
                                Icon(LucideIcons.fingerprint, size: 10, color: Color(0xFF059669)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Back Side (with 3-line MRZ)
        Expanded(
          child: _mockupCardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'RESIDENCE ADDRESS:',
                      style: TextStyle(fontSize: 5, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
                    ),
                    Text(
                      'ISSUED: 12/04/2024',
                      style: TextStyle(fontSize: 5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const Text(
                  '1204 LINCOLN AVE, SUITE 4B, LOS ANGELES, CA 90024',
                  style: TextStyle(fontSize: 4.8, color: Color(0xFF475569)),
                ),
                const Spacer(),
                // 3-line Machine Readable Zone (MRZ)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'I<USA84029104911<<<<<<<<<<<<<<<',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 4.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '9011124M2811125USA<<<<<<<<<<<4',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 4.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'CONNER<<SARAH<J<<<<<<<<<<<<<<<<',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 4.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. PASSPORT BOOKLET MOCKUP (Full opened 2-page passport spread)
// ---------------------------------------------------------------------------
class _PassportBookletMockup extends StatelessWidget {
  const _PassportBookletMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Top Page: Official Navy Blue Cover / Inside Seal Page
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            padding: const EdgeInsets.all(8),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(LucideIcons.shield, color: Color(0xFFFBBF24), size: 16),
                SizedBox(height: 3),
                Text(
                  'PASSPORT',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'UNITED STATES OF AMERICA',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Booklet Center Fold Divider
        Container(
          width: double.infinity,
          height: 3,
          color: const Color(0xFF334155),
        ),
        // Bottom Page: Biometric Data Page
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'PASSPORT / PASSEPORT',
                        style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'No. E92830114',
                      style: TextStyle(fontSize: 6, fontWeight: FontWeight.w900, color: Color(0xFFDC2626)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Portrait + details
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                        ),
                        child: const Center(
                          child: Icon(LucideIcons.user, size: 18, color: Color(0xFFB45309)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Text('Surname: HARRISON', style: TextStyle(fontSize: 5.5, fontWeight: FontWeight.w800)),
                            Text('Given Names: EMILY GRACE', style: TextStyle(fontSize: 5, fontWeight: FontWeight.w700)),
                            Text('Nationality: UNITED STATES OF AMERICA', style: TextStyle(fontSize: 4.8)),
                            Text('Date of Birth: 15 MAR 1994', style: TextStyle(fontSize: 4.8)),
                            Text('Authority: DEPT OF STATE', style: TextStyle(fontSize: 4.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // 2-line ICAO MRZ Code
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 0.6),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'P<USAHARRISON<<EMILY<GRACE<<<<<<<<<<<<<<<<<<',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 4.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'E928301147USA9403158F3201114<<<<<<<<<<<<<<04',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 4.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. BANK CARD MOCKUP (Metallic Titanium Card with Chip & CVV)
// ---------------------------------------------------------------------------
class _BankCardMockup extends StatelessWidget {
  const _BankCardMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Front Side (Titanium Obsidian finish)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'PLATINUM ELITE',
                      style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                    Icon(LucideIcons.wifi, color: Colors.white.withValues(alpha: 0.8), size: 9),
                  ],
                ),
                // Gold EMV Chip
                Container(
                  width: 15,
                  height: 11,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Center(
                    child: Container(width: 7, height: 4, color: const Color(0xFFD97706)),
                  ),
                ),
                // 16-Digit Card Number
                const Text(
                  '4532  8910  2341  9821',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.white,
                    fontSize: 7.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('VALID 11/29', style: TextStyle(color: Colors.white60, fontSize: 4)),
                        Text('ALEXANDER WRIGHT', style: TextStyle(color: Colors.white, fontSize: 5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    // Interlocking card logo
                    Row(
                      children: <Widget>[
                        Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFEB001B), shape: BoxShape.circle)),
                        Transform.translate(
                          offset: const Offset(-3, 0),
                          child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Color(0xFFF79E1B), shape: BoxShape.circle)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Back Side (Magnetic Strip & CVV)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E2430),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 6),
                // Black magnetic strip
                Container(width: double.infinity, height: 11, color: Colors.black),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: <Widget>[
                      // White signature strip
                      Expanded(
                        child: Container(
                          height: 10,
                          color: Colors.white,
                          padding: const EdgeInsets.only(right: 4),
                          alignment: Alignment.centerRight,
                          child: Container(width: 24, height: 1, color: const Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // CVV box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        color: const Color(0xFF334155),
                        child: const Text(
                          '782',
                          style: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 6, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('24/7 CUSTOMER SUPPORT: 1-800-555-CARD', style: TextStyle(color: Colors.white38, fontSize: 4)),
                      Icon(LucideIcons.creditCard, size: 8, color: Colors.white38),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. OFFICIAL CERTIFICATE MOCKUP (Ornate Diploma with Gold Seal)
// ---------------------------------------------------------------------------
class _CertificateMockup extends StatelessWidget {
  const _CertificateMockup();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD97706), width: 1.4),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          // Ornamental Border Inner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFFBBF24), width: 0.8),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(LucideIcons.award, color: Color(0xFFD97706), size: 9),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'CERTIFICATE OF ACHIEVEMENT',
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: Color(0xFF92400E),
                      fontSize: 6.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'THIS ACKNOWLEDGES THAT',
            style: TextStyle(fontSize: 4.8, letterSpacing: 0.8, color: Color(0xFF64748B)),
          ),
          const Text(
            'VICTORIA L. CHEN',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Has successfully fulfilled all accreditation standards and demonstrated outstanding competence.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 4.8, color: Color(0xFF475569), height: 1.25),
            ),
          ),
          // Seal + Signatures row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              // Gold Seal Badge with Ribbons
              Column(
                children: <Widget>[
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(LucideIcons.award, size: 10, color: Colors.white),
                    ),
                  ),
                  Container(width: 6, height: 4, color: const Color(0xFFDC2626)),
                ],
              ),
              // Signature 1
              Column(
                children: <Widget>[
                  Container(width: 38, height: 1, color: const Color(0xFF334155)),
                  const SizedBox(height: 1),
                  const Text('REGISTRAR', style: TextStyle(fontSize: 4, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                ],
              ),
              // Signature 2
              Column(
                children: <Widget>[
                  Container(width: 38, height: 1, color: const Color(0xFF334155)),
                  const SizedBox(height: 1),
                  const Text('DEAN OF FACULTY', style: TextStyle(fontSize: 4, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. SOCIAL SECURITY CARD (SSN) MOCKUP
// ---------------------------------------------------------------------------
class _SsnCardMockup extends StatelessWidget {
  const _SsnCardMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Front Side (Banknote pastel Guilloche format)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF86EFAC), width: 1.0),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(LucideIcons.shield, color: Color(0xFF15803D), size: 7),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'SOCIAL SECURITY',
                        style: TextStyle(
                          fontFamily: 'serif',
                          color: Color(0xFF166534),
                          fontSize: 7.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'THIS NUMBER HAS BEEN ESTABLISHED FOR',
                  style: TextStyle(fontSize: 4.5, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                ),
                const Text(
                  'DAVID B. KAUFMAN',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Text(
                  '*** - ** - 4892',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFDC2626),
                    letterSpacing: 1.2,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('SIGNATURE: David B. Kaufman', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 4.8, color: Color(0xFF334155))),
                    Container(width: 14, height: 14, decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Back Side (Official Instructions)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 0.8),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                const Text(
                  'OFFICIAL SOCIAL SECURITY ADMINISTRATION NOTICE',
                  style: TextStyle(fontSize: 5, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
                const Text(
                  'This card is the property of the Social Security Administration and must be returned upon request.',
                  style: TextStyle(fontSize: 4.5, color: Color(0xFF475569), height: 1.2),
                ),
                const Text(
                  'Social Security Administration • Baltimore, MD 21235',
                  style: TextStyle(fontSize: 4.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                // Validation Barcode
                Row(
                  children: List<Widget>.generate(22, (int i) {
                    return Container(
                      width: i % 4 == 0 ? 2 : 1,
                      height: 7,
                      margin: const EdgeInsets.only(right: 1.5),
                      color: const Color(0xFF1E293B),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 7. AUTO INSURANCE CARD MOCKUP
// ---------------------------------------------------------------------------
class _AutoInsuranceMockup extends StatelessWidget {
  const _AutoInsuranceMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Front Side (Policy Details)
        Expanded(
          child: _mockupCardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'STATE MOTOR VEHICLE INSURANCE ID',
                          style: TextStyle(color: Colors.white, fontSize: 5.5, fontWeight: FontWeight.w900),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(LucideIcons.car, size: 7, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                const Text('INSURER: GUARDIAN MUTUAL INSURANCE CO.', style: TextStyle(fontSize: 5.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const Text('POLICY: POL-AUTO-892184-01', style: TextStyle(fontSize: 5.2, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                const Text('EFFECTIVE: 01/15/2026  EXP: 07/15/2026', style: TextStyle(fontSize: 4.8, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                const Text('INSURED: MARCUS & ELIZABETH VANCE', style: TextStyle(fontSize: 5, fontWeight: FontWeight.w700)),
                const Text('VEHICLE: 2024 HONDA CR-V EX-L | VIN: 5J6RW2H82LA09****', style: TextStyle(fontSize: 4.5, color: Color(0xFF475569))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Back Side (Emergency Checklist & Warning)
        Expanded(
          child: _mockupCardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(3),
                  color: const Color(0xFFFEE2E2),
                  child: const Text(
                    'WARNING: THIS CARD MUST BE KEPT IN VEHICLE AT ALL TIMES',
                    style: TextStyle(fontSize: 4.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                  ),
                ),
                const SizedBox(height: 3),
                const Text('IN CASE OF ACCIDENT:', style: TextStyle(fontSize: 4.8, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                const Text('1. Call police and exchange driver information\n2. Do not admit liability at accident scene\n3. File claim: 1-800-555-CLAIM (24/7)', style: TextStyle(fontSize: 4.4, color: Color(0xFF475569), height: 1.2)),
                const Spacer(),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text('CLAIMS HOTLINE: 1-800-555-HELP', style: TextStyle(fontSize: 4.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                    Icon(LucideIcons.phone, size: 7, color: Color(0xFF0284C7)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 8. GENERAL DOCUMENT MOCKUP
// ---------------------------------------------------------------------------
class _GeneralDocumentMockup extends StatelessWidget {
  const _GeneralDocumentMockup();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Front
        Expanded(
          child: _mockupCardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text('IDENTIFICATION DOCUMENT', style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Center(child: Icon(LucideIcons.user, size: 16, color: Color(0xFF4F46E5))),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            Text('DOC ID: US-2026-9921', style: TextStyle(fontSize: 6, fontWeight: FontWeight.w800)),
                            Text('HOLDER: ALEXANDER MORGAN', style: TextStyle(fontSize: 5.2, fontWeight: FontWeight.w700)),
                            Text('ISSUED: 01/2024 • EXPIRES: 01/2029', style: TextStyle(fontSize: 4.8, color: Color(0xFF64748B))),
                            Text('STATUS: VERIFIED CITIZEN', style: TextStyle(fontSize: 4.8, color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Back
        Expanded(
          child: _mockupCardShell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('TERMS & VERIFICATION CONDITIONS:', style: TextStyle(fontSize: 5, fontWeight: FontWeight.w800)),
                const Text('This credential is non-transferable and subject to validation.\nFor online verification visit official portal.', style: TextStyle(fontSize: 4.5, color: Color(0xFF64748B), height: 1.2)),
                const Spacer(),
                Row(
                  children: List<Widget>.generate(18, (int i) {
                    return Container(
                      width: i % 3 == 0 ? 1.8 : 1,
                      height: 8,
                      margin: const EdgeInsets.only(right: 1.2),
                      color: const Color(0xFF334155),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable Card Container Shell
// ---------------------------------------------------------------------------
Widget _mockupCardShell({required Widget child}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    padding: const EdgeInsets.all(7),
    child: child,
  );
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
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double stepX = tp.width + 48;
    final double stepY = tp.height + 34;

    for (double y = -size.height * 1.5; y < size.height * 1.5; y += stepY) {
      final double xOffset = ((y / stepY).floor() % 2 == 0) ? 0 : stepX / 2;
      for (double x = -size.width * 1.5 + xOffset; x < size.width * 1.5; x += stepX) {
        tp.paint(canvas, Offset(x, y));
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
