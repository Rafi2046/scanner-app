import 'package:flutter/material.dart';

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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: SizedBox(
        height: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: <Widget>[
                  const Expanded(child: Text('Extracted text')),
                  IconButton(
                    tooltip: 'Copy',
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SingleChildScrollView(
                  child: SelectableText(
                    text ?? 'Extracted text will appear here.',
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
