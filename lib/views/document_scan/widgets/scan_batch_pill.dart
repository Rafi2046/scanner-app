import 'package:flutter/material.dart';

/// Segmented Single/Batch toggle pill floating above the bottom viewfinder.
class ScanBatchPill extends StatelessWidget {
  const ScanBatchPill({
    super.key,
    required this.isBatch,
    required this.onToggle,
  });

  final bool isBatch;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x9912141A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _PillOption(
            title: 'Single',
            isSelected: !isBatch,
            onTap: () => onToggle(false),
          ),
          const SizedBox(width: 2),
          _PillOption(
            title: 'Batch',
            isSelected: isBatch,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _PillOption extends StatelessWidget {
  const _PillOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A505C) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
