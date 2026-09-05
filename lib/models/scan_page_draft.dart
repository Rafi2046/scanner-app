import 'package:scanner_app/core/enums/id_scan_side.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';

/// One committed page in the current custom-scan session.
class ScanPageDraft {
  const ScanPageDraft({
    required this.imagePath,
    this.filter = ScanFilter.original,
    this.idSide,
  });

  final String imagePath;
  final ScanFilter filter;
  final IdScanSide? idSide;

  ScanPageDraft copyWith({
    String? imagePath,
    ScanFilter? filter,
    IdScanSide? idSide,
  }) {
    return ScanPageDraft(
      imagePath: imagePath ?? this.imagePath,
      filter: filter ?? this.filter,
      idSide: idSide ?? this.idSide,
    );
  }
}
