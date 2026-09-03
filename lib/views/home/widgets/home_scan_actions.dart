import 'package:flutter/material.dart';

/// Scan entry cards (optional sheet / dashboard helper).
class HomeScanActions extends StatelessWidget {
  const HomeScanActions({
    super.key,
    this.onScanDocument,
    this.onScanIdCard,
  });

  final VoidCallback? onScanDocument;
  final VoidCallback? onScanIdCard;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ActionCard(
              icon: Icons.document_scanner_outlined,
              label: 'Scan Document',
              onTap: onScanDocument,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionCard(
              icon: Icons.badge_outlined,
              label: 'Scan ID Card',
              onTap: onScanIdCard,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
