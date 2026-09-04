import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/views/widgets/loading_overlay.dart';
import 'package:scanner_app/views/widgets/primary_button.dart';

/// Shared light layout for PDF tool screens.
class ToolScreenScaffold extends StatelessWidget {
  const ToolScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
    this.busy = false,
    this.busyMessage = 'Working…',
    this.actionEnabled = true,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool busy;
  final String busyMessage;
  final bool actionEnabled;

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      visible: busy,
      message: busyMessage,
      child: Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppTheme.scaffoldBg,
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.pagePadding,
                  AppConstants.spaceSm,
                  AppConstants.pagePadding,
                  AppConstants.spaceMd,
                ),
                child: Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            Expanded(child: body),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.pagePadding,
                  AppConstants.spaceSm,
                  AppConstants.pagePadding,
                  AppConstants.spaceLg,
                ),
                child: PrimaryButton(
                  label: actionLabel,
                  onPressed: actionEnabled && !busy ? onAction : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
