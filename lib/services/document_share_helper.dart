import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/scanned_document.dart';

/// Centralized helper for sharing documents, PDF files, and scanned page images.
class DocumentShareHelper {
  const DocumentShareHelper._();

  /// Shares a scanned document (its PDF if available, or its page images).
  static Future<void> shareDocument(
    BuildContext context,
    ScannedDocument doc,
  ) async {
    HapticFeedback.lightImpact();
    try {
      if (doc.hasPdf && File(doc.pdfPath!).existsSync()) {
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[XFile(doc.pdfPath!)],
            text: doc.title,
          ),
        );
      } else if (doc.imagePaths.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(
            files: doc.imagePaths.map((String p) => XFile(p)).toList(),
            text: doc.title,
          ),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No files available to share.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, e);
      }
    }
  }

  /// Shares a single page image file.
  static Future<void> shareSingleImage(
    BuildContext context, {
    required String imagePath,
    String? title,
  }) async {
    HapticFeedback.lightImpact();
    try {
      if (File(imagePath).existsSync()) {
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[XFile(imagePath)],
            text: title,
          ),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Page image not found.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, e);
      }
    }
  }

  /// Shares a single PDF file.
  static Future<void> sharePdfFile(
    BuildContext context, {
    required String pdfPath,
    required String title,
  }) async {
    HapticFeedback.lightImpact();
    try {
      if (File(pdfPath).existsSync()) {
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[XFile(pdfPath)],
            text: title,
          ),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF file not found.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showError(context, e);
      }
    }
  }

  static void _showError(BuildContext context, Object error) {
    final String message = error is MissingPluginException
        ? 'Native module not initialized. Please stop (⏹) and Run (▶) the app in Android Studio.'
        : 'Failed to share: $error';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
