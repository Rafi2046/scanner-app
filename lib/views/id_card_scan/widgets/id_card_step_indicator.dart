import 'package:flutter/material.dart';
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
            label: '1. Front Side',
            isActive: activeIndex >= 0,
            isComplete: activeIndex >= 1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StepChip(
            label: '2. Back Side',
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
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color bg = isComplete
        ? colors.primaryContainer
        : (isActive ? colors.surfaceContainerHighest : colors.surface);

    return Material(
      color: bg,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(
              isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: isComplete ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
