import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';

/// Bento-style card used across the dashboard and tools hub.
class BentoToolCard extends StatelessWidget {
  const BentoToolCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.tag,
    this.accentColor = AppTheme.primaryMint,
    this.iconBgColor,
    this.isHero = false,
    this.heroGradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? tag;
  final Color accentColor;
  final Color? iconBgColor;
  final bool isHero;
  final Gradient? heroGradient;

  @override
  Widget build(BuildContext context) {
    final Color effectiveIconBg =
        iconBgColor ?? accentColor.withValues(alpha: 0.15);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHero ? accentColor.withValues(alpha: 0.3) : AppTheme.cardBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isHero ? 18 : 14),
            child: isHero
                ? _buildHeroLayout(effectiveIconBg)
                : _buildCompactLayout(effectiveIconBg),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroLayout(Color effectiveIconBg) {
    return Row(
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: heroGradient ??
                LinearGradient(
                  colors: <Color>[accentColor, accentColor.withValues(alpha: 0.7)],
                ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.black, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (tag != null) ...<Widget>[
                    const SizedBox(width: 8),
                    _CardBadge(tag: tag!, color: accentColor),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
      ],
    );
  }

  Widget _buildCompactLayout(Color effectiveIconBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: effectiveIconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            if (tag != null) _CardBadge(tag: tag!, color: accentColor),
          ],
        ),
        const Spacer(),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
          maxLines: 1,
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          maxLines: 1,
        ),
      ],
    );
  }
}

class _CardBadge extends StatelessWidget {
  const _CardBadge({required this.tag, required this.color});
  final String tag;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
