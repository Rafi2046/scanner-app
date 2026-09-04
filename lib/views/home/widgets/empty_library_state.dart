import 'package:flutter/material.dart';
import 'package:scanner_app/views/home/widgets/modern_empty_state.dart';

/// Placeholder empty state for an empty document library.
class EmptyLibraryState extends StatelessWidget {
  const EmptyLibraryState({super.key, this.onScan});

  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context) {
    return ModernEmptyState(onScan: onScan);
  }
}

