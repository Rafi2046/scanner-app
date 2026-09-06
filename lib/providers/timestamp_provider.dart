import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanner_app/models/timestamp_config.dart';

/// Notifier managing camera timestamp overlay configuration.
class TimestampConfigNotifier extends StateNotifier<TimestampConfig> {
  TimestampConfigNotifier() : super(const TimestampConfig());

  void setTemplate(TimestampTemplateType template) {
    state = state.copyWith(template: template);
  }

  void toggle24Hour(bool value) {
    state = state.copyWith(is24Hour: value);
  }

  void toggleShowSeconds(bool value) {
    state = state.copyWith(showSeconds: value);
  }

  void setLocationText(String location) {
    state = state.copyWith(locationText: location.trim());
  }

  void toggleShowLocation(bool value) {
    state = state.copyWith(showLocation: value);
  }

  void setCustomTag(String tag) {
    state = state.copyWith(customTag: tag.trim());
  }

  void toggleShowTag(bool value) {
    state = state.copyWith(showTag: value);
  }

  void setVerifiedBy(String verifiedBy) {
    state = state.copyWith(verifiedBy: verifiedBy.trim());
  }

  void toggleShowVerified(bool value) {
    state = state.copyWith(showVerified: value);
  }

  void setScale(double scale) {
    state = state.copyWith(scale: scale.clamp(0.65, 1.80));
  }

  void setPositionRatio(Offset positionRatio) {
    state = state.copyWith(
      positionRatio: Offset(
        positionRatio.dx.clamp(0.0, 1.0),
        positionRatio.dy.clamp(0.0, 1.0),
      ),
    );
  }

  void resetPositionAndScale() {
    state = state.copyWith(
      scale: 1.0,
      positionRatio: const Offset(0.04, 0.72),
    );
  }
}

final timestampConfigProvider =
    StateNotifierProvider<TimestampConfigNotifier, TimestampConfig>((ref) {
  return TimestampConfigNotifier();
});
