import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';

/// Clean, sleek visual filter selector with refined miniature document cards.
/// Perfectly proportioned to look lightweight, sharp, and non-bulky.
class ScanFilterVisualCarousel extends StatelessWidget {
  const ScanFilterVisualCarousel({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ScanFilter selected;
  final ValueChanged<ScanFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
        itemCount: ScanFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final ScanFilter filter = ScanFilter.values[index];
          final bool isSelected = filter == selected;
          return _FilterCard(
            filter: filter,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(filter);
            },
          );
        },
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  final ScanFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  static const Color accent = Color(0xFF00D2A0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isSelected ? accent : const Color(0xFF282D35),
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: isSelected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: _buildThumbnailPreview(filter),
              ),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? accent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                filter.label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF0A1017) : Colors.white60,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailPreview(ScanFilter filter) {
    return switch (filter) {
      ScanFilter.original => _renderDocPaper(
          background: const Color(0xFFE8E2D0),
          inkColor: const Color(0xFF383226),
          badgeColor: const Color(0xFF7A6D56),
          badgeLabel: 'RAW',
          hasNaturalShadow: true,
        ),
      ScanFilter.color => _renderDocPaper(
          background: Colors.white,
          inkColor: const Color(0xFF161A20),
          badgeColor: accent,
          badgeLabel: 'MAGIC',
          isColorAi: true,
        ),
      ScanFilter.noShadow => _renderDocPaper(
          background: const Color(0xFFF8FAFC),
          inkColor: const Color(0xFF1E293B),
          badgeColor: const Color(0xFF0EA5E9),
          badgeLabel: 'CLEAN',
        ),
      ScanFilter.bw => _renderDocPaper(
          background: Colors.white,
          inkColor: Colors.black,
          badgeColor: const Color(0xFF0F172A),
          badgeLabel: 'B&W',
          isPureBw: true,
        ),
      ScanFilter.grayscale => _renderDocPaper(
          background: const Color(0xFFE2E8F0),
          inkColor: const Color(0xFF334155),
          badgeColor: const Color(0xFF64748B),
          badgeLabel: 'GRAY',
          hasMonoPhoto: true,
        ),
      ScanFilter.lighten => _renderDocPaper(
          background: Colors.white,
          inkColor: const Color(0xFF94A3B8),
          badgeColor: const Color(0xFFCBD5E1),
          badgeLabel: 'LITE',
        ),
      ScanFilter.invert => _renderDocPaper(
          background: const Color(0xFF0F172A),
          inkColor: const Color(0xFFF8FAFC),
          badgeColor: const Color(0xFF334155),
          badgeLabel: 'INV',
        ),
    };
  }

  Widget _renderDocPaper({
    required Color background,
    required Color inkColor,
    required Color badgeColor,
    required String badgeLabel,
    bool hasNaturalShadow = false,
    bool isColorAi = false,
    bool isPureBw = false,
    bool hasMonoPhoto = false,
  }) {
    return Container(
      color: background,
      child: Stack(
        children: <Widget>[
          if (hasNaturalShadow)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Document header: badge
                Row(
                  children: <Widget>[
                    if (isColorAi)
                      const Icon(
                        Icons.auto_awesome,
                        size: 7,
                        color: accent,
                      )
                    else
                      Icon(
                        Icons.description_rounded,
                        size: 7,
                        color: inkColor.withValues(alpha: 0.7),
                      ),
                    const SizedBox(width: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: isColorAi ? const Color(0xFF0A1017) : Colors.white,
                          fontSize: 5.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Skeleton body
                if (hasMonoPhoto)
                  Row(
                    children: <Widget>[
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(right: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF94A3B8),
                          borderRadius: BorderRadius.circular(1),
                        ),
                        child: const Icon(Icons.person, size: 7, color: Colors.white70),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _line(inkColor, 24),
                            const SizedBox(height: 1.5),
                            _line(inkColor.withValues(alpha: 0.7), 18),
                          ],
                        ),
                      ),
                    ],
                  )
                else if (isColorAi)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _line(const Color(0xFF2563EB), 26),
                      const SizedBox(height: 1.8),
                      _line(inkColor.withValues(alpha: 0.85), 36),
                      const SizedBox(height: 1.8),
                      _line(inkColor.withValues(alpha: 0.65), 28),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _line(inkColor, isPureBw ? 34 : 28),
                      const SizedBox(height: 1.8),
                      _line(inkColor.withValues(alpha: isPureBw ? 1.0 : 0.75), isPureBw ? 38 : 34),
                      const SizedBox(height: 1.8),
                      _line(inkColor.withValues(alpha: isPureBw ? 1.0 : 0.60), 22),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(Color color, double width) {
    return Container(
      width: width,
      height: 1.8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
