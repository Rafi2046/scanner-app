/// Front and back image paths captured during ID card mode.
class IdCardSides {
  const IdCardSides({
    this.frontPath,
    this.backPath,
  });

  final String? frontPath;
  final String? backPath;

  bool get hasFront => frontPath != null && frontPath!.isNotEmpty;

  bool get hasBack => backPath != null && backPath!.isNotEmpty;

  bool get isComplete => hasFront && hasBack;

  IdCardSides copyWith({
    String? frontPath,
    String? backPath,
    bool clearFront = false,
    bool clearBack = false,
  }) {
    return IdCardSides(
      frontPath: clearFront ? null : (frontPath ?? this.frontPath),
      backPath: clearBack ? null : (backPath ?? this.backPath),
    );
  }
}
