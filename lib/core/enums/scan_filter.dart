/// Filters applied after crop, matching CamScanner's palette.
enum ScanFilter {
  original,
  color,
  noShadow,
  bw,
  grayscale,
  lighten,
  invert,
}

extension ScanFilterX on ScanFilter {
  String get label => switch (this) {
        ScanFilter.original => 'Original',
        ScanFilter.color => 'Magic Color',
        ScanFilter.noShadow => 'No Shadow',
        ScanFilter.bw => 'B&W',
        ScanFilter.grayscale => 'Grayscale',
        ScanFilter.lighten => 'Lighten',
        ScanFilter.invert => 'Invert',
      };
}
