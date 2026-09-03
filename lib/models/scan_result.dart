/// Raw output from a single ML Kit document-scanner session.
///
/// Paths point at temporary cache files and must be persisted via
/// [StorageService] before they are discarded by the OS.
class ScanResult {
  const ScanResult({
    this.imagePaths = const <String>[],
    this.pdfPath,
  });

  final List<String> imagePaths;
  final String? pdfPath;

  bool get isEmpty => imagePaths.isEmpty && (pdfPath == null || pdfPath!.isEmpty);

  bool get hasImages => imagePaths.isNotEmpty;

  bool get hasPdf => pdfPath != null && pdfPath!.isNotEmpty;

  int get pageCount =>
      imagePaths.isNotEmpty ? imagePaths.length : (hasPdf ? 1 : 0);
}
