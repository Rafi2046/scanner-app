import 'package:flutter/material.dart';
import 'package:scanner_app/core/enums/custom_scan_mode.dart';
import 'package:scanner_app/views/document_scan/custom_scan_view.dart';

/// Legacy stub — use [CustomScanView] instead.
class DocumentScanView extends StatelessWidget {
  const DocumentScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScanView(mode: CustomScanMode.document);
  }
}
