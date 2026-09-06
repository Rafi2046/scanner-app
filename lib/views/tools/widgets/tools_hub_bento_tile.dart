import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanner_app/app/theme.dart';

/// Minimalist white bento tile (radius 20) for Tools Hub.
enum ToolsHubTileSize { hero, medium, compact }

class ToolsHubBentoTile extends StatelessWidget {
  const ToolsHubBentoTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.size = ToolsHubTileSize.medium,
    this.accent = AppTheme.primary,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final ToolsHubTileSize size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bool isHero = size == ToolsHubTileSize.hero;
    final bool isCompact = size == ToolsHubTileSize.compact;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEF0F3)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isHero ? 16 : (isCompact ? 14 : 16),
              vertical: isHero ? 14 : (isCompact ? 14 : 16),
            ),
            child: isHero
                ? _HeroBody(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    accent: accent,
                  )
                : _CompactBody(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    accent: accent,
                    tight: isCompact,
                  ),
          ),
        ),
      ),
    );
  }
}

class _HeroBody extends StatelessWidget {
  const _HeroBody({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppTheme.textSecondary.withValues(alpha: 0.7),
        ),
      ],
    );
  }
}

class _CompactBody extends StatelessWidget {
  const _CompactBody({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.tight,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: tight ? 36 : 40,
          height: tight ? 36 : 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: tight ? 18 : 20),
        ),
        const Spacer(),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: tight ? 13.5 : 14.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: tight ? 11 : 11.5,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
