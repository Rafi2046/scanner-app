/// Filters applied after crop, matching CamScanner's signature palette.
enum ScanFilter {
  original,
  magicEnhance,
  grayscale,
  bw,
  noShadow,
  lighten,
  invert;

  /// Alias for backward compatibility with existing code
  static const ScanFilter color = magicEnhance;

  String get label => switch (this) {
        ScanFilter.original => 'Original',
        ScanFilter.magicEnhance => 'Magic Enhance',
        ScanFilter.grayscale => 'Grayscale',
        ScanFilter.bw => 'Pure B&W',
        ScanFilter.noShadow => 'No Shadow',
        ScanFilter.lighten => 'Lighten',
        ScanFilter.invert => 'Invert',
      };
}
