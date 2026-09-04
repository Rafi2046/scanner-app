import 'package:flutter/material.dart';
import 'package:scanner_app/app/theme.dart';
import 'package:scanner_app/core/constants/app_constants.dart';
import 'package:scanner_app/core/enums/id_card_scan_step.dart';

class IdCardStepIndicator extends StatelessWidget {
  const IdCardStepIndicator({
    super.key,
    required this.step,
  });

  final IdCardScanStep step;

  @override
  Widget build(BuildContext context) {
    final int activeIndex = switch (step) {
      IdCardScanStep.idle => 0,
      IdCardScanStep.frontScanned => 1,
      IdCardScanStep.backScanned || IdCardScanStep.processing => 2,
    };

    return Row(
      children: <Widget>[
        Expanded(
          child: _StepChip(
            label: '1. Front',
            isActive: activeIndex >= 0,
            isComplete: activeIndex >= 1,
          ),
        ),
        const SizedBox(width: AppConstants.spaceSm),
        Expanded(
          child: _StepChip(
            label: '2. Back',
            isActive: activeIndex >= 1,
            isComplete: activeIndex >= 2,
          ),
        ),
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.isActive,
    required this.isComplete,
  });

  final String label;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final Color bg = isComplete
        ? AppTheme.primary.withValues(alpha: 0.22)
        : (isActive ? const Color(0xFF1A1D24) : const Color(0xFF16181E));
    final Color border =
        isComplete ? AppTheme.primary : const Color(0xFF2A2F3A);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd,
          vertical: AppConstants.spaceMd,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: isComplete ? AppTheme.primary : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: AppConstants.spaceSm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? Colors.white : const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
