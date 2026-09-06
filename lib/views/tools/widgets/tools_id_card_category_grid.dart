import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/id_card_category.dart';
import 'package:scanner_app/views/tools/widgets/tools_hub_bento_tile.dart';

/// Quality-only ID categories wired to the real offline scan engine.
const List<IdCardCategory> kToolsIdCardCategories = <IdCardCategory>[
  IdCardCategory.idCard,
  IdCardCategory.driverLicense,
  IdCardCategory.passport,
  IdCardCategory.bankCard,
];

/// 2-column grid of ID card type tiles for Tools Hub.
class ToolsIdCardCategoryGrid extends StatelessWidget {
  const ToolsIdCardCategoryGrid({
    super.key,
    required this.onIdCategory,
  });

  final ValueChanged<IdCardCategory> onIdCategory;

  static IconData _iconFor(IdCardCategory cat) {
    return switch (cat) {
      IdCardCategory.idCard => LucideIcons.contact2,
      IdCardCategory.driverLicense => LucideIcons.car,
      IdCardCategory.passport => LucideIcons.globe,
      IdCardCategory.bankCard => LucideIcons.creditCard,
      IdCardCategory.general => LucideIcons.fileText,
      IdCardCategory.certificate => LucideIcons.award,
      IdCardCategory.ssn => LucideIcons.shieldCheck,
      IdCardCategory.autoInsurance => LucideIcons.shield,
    };
  }

  static Color _accentFor(IdCardCategory cat) {
    return switch (cat) {
      IdCardCategory.idCard => AppTheme.accentBlue,
      IdCardCategory.driverLicense => AppTheme.accentOrange,
      IdCardCategory.passport => AppTheme.accentTeal,
      IdCardCategory.bankCard => AppTheme.accentPurple,
      IdCardCategory.general => AppTheme.primary,
      IdCardCategory.certificate => AppTheme.accentGold,
      IdCardCategory.ssn => AppTheme.accentBrown,
      IdCardCategory.autoInsurance => AppTheme.accentPink,
    };
  }

  static String _subtitleFor(IdCardCategory cat) {
    return cat.isSingleSide ? '1 side · A4 PDF' : 'Front & back · A4 PDF';
  }

  @override
  Widget build(BuildContext context) {
    const List<IdCardCategory> cats = kToolsIdCardCategories;
    return Column(
      children: <Widget>[
        for (int i = 0; i < cats.length; i += 2) ...<Widget>[
          if (i > 0) const SizedBox(height: AppConstants.spaceMd),
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 112,
                  child: ToolsHubBentoTile(
                    title: cats[i].title,
                    subtitle: _subtitleFor(cats[i]),
                    icon: _iconFor(cats[i]),
                    size: ToolsHubTileSize.compact,
                    accent: _accentFor(cats[i]),
                    onTap: () => onIdCategory(cats[i]),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: i + 1 < cats.length
                    ? SizedBox(
                        height: 112,
                        child: ToolsHubBentoTile(
                          title: cats[i + 1].title,
                          subtitle: _subtitleFor(cats[i + 1]),
                          icon: _iconFor(cats[i + 1]),
                          size: ToolsHubTileSize.compact,
                          accent: _accentFor(cats[i + 1]),
                          onTap: () => onIdCategory(cats[i + 1]),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
