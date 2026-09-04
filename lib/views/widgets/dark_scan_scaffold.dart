import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

/// Dark shell used for scan / ID capture flows.
class DarkScanScaffold extends StatelessWidget {
  const DarkScanScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomBar,
    this.actions,
  });

  final String title;
  final Widget body;
  final Widget? bottomBar;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkScan(),
      child: Scaffold(
        backgroundColor: const Color(0xFF12141A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF12141A),
          foregroundColor: Colors.white,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          actions: actions,
        ),
        body: body,
        bottomNavigationBar: bottomBar == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.pagePadding,
                    AppConstants.spaceSm,
                    AppConstants.pagePadding,
                    AppConstants.spaceLg,
                  ),
                  child: bottomBar,
                ),
              ),
      ),
    );
  }
}
