import 'dart:io';

import 'package:flutter/material.dart';
import 'package:scanner_app/core/constants/app_constants.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppConstants.spaceSm),
        AspectRatio(
          aspectRatio: 1.6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D24),
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
              border: Border.all(color: const Color(0xFF2A2F3A)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusLg),
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
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: Color(0xFF6B7280),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
    );
  }
}
