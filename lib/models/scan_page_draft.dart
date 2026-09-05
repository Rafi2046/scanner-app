import 'package:scanner_app/core/enums/id_scan_side.dart';
import 'package:scanner_app/core/enums/scan_filter.dart';

/// One committed page in the current custom-scan session.
class ScanPageDraft {
  const ScanPageDraft({
    required this.imagePath,
    this.rawPath,
    this.filter = ScanFilter.original,
    this.rotationTurns = 0,
    this.idSide,
  });

  final String imagePath;
  final String? rawPath;
  final ScanFilter filter;
  final int rotationTurns;
  final IdScanSide? idSide;

  ScanPageDraft copyWith({
    String? imagePath,
    String? rawPath,
    ScanFilter? filter,
    int? rotationTurns,
    IdScanSide? idSide,
  }) {
    return ScanPageDraft(
      imagePath: imagePath ?? this.imagePath,
      rawPath: rawPath ?? this.rawPath,
      filter: filter ?? this.filter,
      rotationTurns: rotationTurns ?? this.rotationTurns,
      idSide: idSide ?? this.idSide,
    );
  }
}
