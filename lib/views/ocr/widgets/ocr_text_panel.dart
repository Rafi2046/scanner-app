import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

class OcrTextPanel extends StatelessWidget {
  const OcrTextPanel({
    super.key,
    required this.text,
    this.onCopy,
  });

  final String? text;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppConstants.pagePadding,
          AppConstants.spaceSm,
          AppConstants.pagePadding,
          AppConstants.spaceLg,
        ),
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceLg,
                AppConstants.spaceSm,
                AppConstants.spaceSm,
                0,
              ),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Extracted text',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded),
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spaceLg,
                  0,
                  AppConstants.spaceLg,
                  AppConstants.spaceLg,
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    text ?? 'Extracted text will appear here.',
                    style: TextStyle(
                      color: text == null
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
