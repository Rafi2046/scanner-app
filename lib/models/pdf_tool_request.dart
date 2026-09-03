import 'package:scanner_app/core/enums/tool_type.dart';

/// Placeholder request payload for PDF tools (Milestone 2+).
class PdfToolRequest {
  const PdfToolRequest({
    required this.toolType,
    required this.inputPaths,
    this.options = const <String, Object?>{},
  });

  final ToolType toolType;
  final List<String> inputPaths;
  final Map<String, Object?> options;
}
