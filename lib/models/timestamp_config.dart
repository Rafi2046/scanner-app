import 'dart:ui';

/// Distinctive templates for the camera timestamp mode.
enum TimestampTemplateType {
  minimal(
    title: 'Minimal Clean',
    subtitle: 'Bold time, date & location pin',
  ),
  onSite(
    title: 'On-Site Pro',
    subtitle: 'Work inspection badge & data grid',
  ),
  clockIn(
    title: 'Clock-In',
    subtitle: 'Shift attendance calendar card',
  ),
  digitalLcd(
    title: 'Digital Clock',
    subtitle: 'Glowing 7-segment retro LCD display',
  ),
  officialStamp(
    title: 'Verified Stamp',
    subtitle: 'Gold notarized audit seal',
  ),
  travelPin(
    title: 'Travel & Weather',
    subtitle: 'Compact weather & location pin',
  );

  const TimestampTemplateType({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

/// Configuration model for live camera timestamp overlay and stamped photos.
class TimestampConfig {
  const TimestampConfig({
    this.template = TimestampTemplateType.minimal,
    this.is24Hour = false,
    this.showSeconds = true,
    this.locationText = 'Shikdar Pharmacy',
    this.showLocation = true,
    this.customTag = 'Verified on-site',
    this.showTag = true,
    this.verifiedBy = 'Verified by Scanner Pro',
    this.showVerified = true,
    this.scale = 1.0,
    this.positionRatio = const Offset(0.04, 0.72),
  });

  final TimestampTemplateType template;
  final bool is24Hour;
  final bool showSeconds;
  final String locationText;
  final bool showLocation;
  final String customTag;
  final bool showTag;
  final String verifiedBy;
  final bool showVerified;

  /// Scale factor for overlay card (0.6x to 2.2x).
  final double scale;

  /// Normalized position coordinate (0.0 to 1.0) on the viewfinder.
  final Offset positionRatio;

  TimestampConfig copyWith({
    TimestampTemplateType? template,
    bool? is24Hour,
    bool? showSeconds,
    String? locationText,
    bool? showLocation,
    String? customTag,
    bool? showTag,
    String? verifiedBy,
    bool? showVerified,
    double? scale,
    Offset? positionRatio,
  }) {
    return TimestampConfig(
      template: template ?? this.template,
      is24Hour: is24Hour ?? this.is24Hour,
      showSeconds: showSeconds ?? this.showSeconds,
      locationText: locationText ?? this.locationText,
      showLocation: showLocation ?? this.showLocation,
      customTag: customTag ?? this.customTag,
      showTag: showTag ?? this.showTag,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      showVerified: showVerified ?? this.showVerified,
      scale: scale ?? this.scale,
      positionRatio: positionRatio ?? this.positionRatio,
    );
  }
}

