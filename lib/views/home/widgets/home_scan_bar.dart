import 'package:flutter/material.dart';

class HomeScanBar extends StatelessWidget {
  const HomeScanBar({
    super.key,
    required this.onScanDocument,
    required this.onScanIdCard,
    this.enabled = true,
  });

  final VoidCallback onScanDocument;
  final VoidCallback onScanIdCard;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextButton.icon(
              onPressed: enabled ? onScanDocument : null,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan Document'),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: enabled ? onScanIdCard : null,
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Scan ID Card'),
            ),
          ),
        ],
      ),
    );
  }
}
