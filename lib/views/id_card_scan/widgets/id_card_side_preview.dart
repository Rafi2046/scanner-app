import 'dart:io';

import 'package:flutter/material.dart';

class IdCardSidePreview extends StatelessWidget {
  const IdCardSidePreview({
    super.key,
    required this.label,
    this.imagePath,
  });

  final String label;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 1.6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: _buildImage(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    final String? path = imagePath;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      return const Center(
        child: Icon(Icons.image_outlined, size: 40),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
    );
  }
}
