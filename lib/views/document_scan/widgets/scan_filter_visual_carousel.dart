import 'package:flutter/material.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';

/// Horizontal visual filter selector with stylized miniature document cards.
/// Designed exclusively for our scanner app with a modern, high-contrast aesthetic.
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
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.pagePadding),
        itemCount: ScanFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          final ScanFilter filter = ScanFilter.values[index];
          final bool isSelected = filter == selected;
          return _FilterCard(
            filter: filter,
            isSelected: isSelected,
            onTap: () => onSelected(filter),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? accent : const Color(0xFF2C323B),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: accent.withValues(alpha: 0.35),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildThumbnailPreview(filter),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: isSelected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              filter.label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0F141A) : Colors.white70,
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPreview(ScanFilter filter) {
    return switch (filter) {
      ScanFilter.original => _renderDocPaper(
          background: const Color(0xFFDFD9C5),
          inkColor: const Color(0xFF423B30),
          badgeColor: const Color(0xFF8D7F67),
          badgeLabel: 'RAW',
          hasShadowGradient: true,
        ),
      ScanFilter.color => _renderDocPaper(
          background: Colors.white,
          inkColor: const Color(0xFF1E242B),
          badgeColor: accent,
          badgeLabel: 'AI PRO',
          isCrisp: true,
        ),
      ScanFilter.noShadow => _renderDocPaper(
          background: const Color(0xFFF6F8FA),
          inkColor: const Color(0xFF24292E),
          badgeColor: const Color(0xFF00A389),
          badgeLabel: 'CLEAN',
        ),
      ScanFilter.bw => _renderDocPaper(
          background: Colors.white,
          inkColor: Colors.black,
          badgeColor: const Color(0xFF1E2124),
          badgeLabel: 'B&W',
          isStark: true,
        ),
      ScanFilter.grayscale => _renderDocPaper(
          background: const Color(0xFFE9ECEF),
          inkColor: const Color(0xFF495057),
          badgeColor: const Color(0xFF6C757D),
          badgeLabel: 'GRAY',
        ),
      ScanFilter.lighten => _renderDocPaper(
          background: Colors.white,
          inkColor: const Color(0xFF868E96),
          badgeColor: const Color(0xFFADB5BD),
          badgeLabel: 'LITE',
        ),
      ScanFilter.invert => _renderDocPaper(
          background: const Color(0xFF14171C),
          inkColor: const Color(0xFFF1F3F5),
          badgeColor: const Color(0xFF343A40),
          badgeLabel: 'INV',
        ),
    };
  }

  Widget _renderDocPaper({
    required Color background,
    required Color inkColor,
    required Color badgeColor,
    required String badgeLabel,
    bool hasShadowGradient = false,
    bool isCrisp = false,
    bool isStark = false,
  }) {
    return Container(
      color: background,
      child: Stack(
        children: <Widget>[
          if (hasShadowGradient)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(4.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Document mini header: icon + badge
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.article_rounded,
                      size: 9,
                      color: isCrisp ? accent : inkColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 2.5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        badgeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 6.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3.5),
                // Stylized text skeleton lines
                _line(inkColor.withValues(alpha: isStark ? 1.0 : 0.75), 36),
                const SizedBox(height: 2),
                _line(inkColor.withValues(alpha: isStark ? 1.0 : 0.9), 46),
                const SizedBox(height: 2),
                _line(inkColor.withValues(alpha: isStark ? 1.0 : 0.65), 30),
                const SizedBox(height: 2),
                _line(inkColor.withValues(alpha: isStark ? 1.0 : 0.8), 40),
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
      height: 2.2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
