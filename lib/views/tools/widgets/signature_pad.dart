import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:signature/signature.dart';

class SignaturePad extends StatelessWidget {
  const SignaturePad({
    super.key,
    required this.controller,
  });

  final SignatureController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusLg),
            child: SizedBox(
              height: 160,
              child: Signature(
                controller: controller,
                backgroundColor: AppTheme.surfaceColor,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: controller.clear,
            child: const Text('Clear'),
          ),
        ),
      ],
    );
  }
}
