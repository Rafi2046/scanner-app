/// Filter applied after crop, before a page is committed.
enum ScanFilter {
  original,
  color,
  bw,
  enhance,
}

extension ScanFilterX on ScanFilter {
  String get label => switch (this) {
        ScanFilter.original => 'Original',
        ScanFilter.color => 'Color',
        ScanFilter.bw => 'B&W',
        ScanFilter.enhance => 'Enhance',
      };
}
