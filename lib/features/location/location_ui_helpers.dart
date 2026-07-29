import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../shared/widgets/saeq_status_chip.dart';
import 'location_feature.dart';
import 'map_preview_feature.dart';

String locationAccuracyLabel(
  AppLocalizations l10n,
  LocationAccuracyLevel level,
) {
  return switch (level) {
    LocationAccuracyLevel.high => l10n.locationAccuracyHigh,
    LocationAccuracyLevel.weak => l10n.locationAccuracyWeak,
    LocationAccuracyLevel.unknown => l10n.locationAccuracyUnknown,
  };
}

/// Accuracy indicator text — level wording plus the fake radius, so meaning
/// never depends on color alone.
String locationAccuracyChipLabel(
  AppLocalizations l10n,
  LocationAccuracyLevel level,
  int? accuracyMeters,
) {
  final label = locationAccuracyLabel(l10n, level);
  if (accuracyMeters == null) return label;
  return '$label · ${l10n.locationAccuracyMeters(accuracyMeters)}';
}

SaeqStatusTone locationAccuracyTone(LocationAccuracyLevel level) {
  return switch (level) {
    LocationAccuracyLevel.high => SaeqStatusTone.success,
    LocationAccuracyLevel.weak => SaeqStatusTone.warning,
    LocationAccuracyLevel.unknown => SaeqStatusTone.neutral,
  };
}

IconData locationAccuracyIcon(LocationAccuracyLevel level) {
  return switch (level) {
    LocationAccuracyLevel.high => Icons.gps_fixed,
    LocationAccuracyLevel.weak => Icons.gps_not_fixed,
    LocationAccuracyLevel.unknown => Icons.gps_off,
  };
}

String locationScenarioLabel(
  AppLocalizations l10n,
  FakeLocationScenario scenario,
) {
  return switch (scenario) {
    FakeLocationScenario.permissionGranted => l10n.locationTrialGranted,
    FakeLocationScenario.permissionDenied => l10n.locationTrialDenied,
    FakeLocationScenario.permissionPermanentlyDenied =>
      l10n.locationTrialBlocked,
    FakeLocationScenario.gpsDisabled => l10n.locationTrialGpsOff,
    FakeLocationScenario.weakAccuracy => l10n.locationTrialWeakAccuracy,
    FakeLocationScenario.offline => l10n.locationTrialOffline,
  };
}

String mapScenarioLabel(AppLocalizations l10n, FakeMapScenario scenario) {
  return switch (scenario) {
    FakeMapScenario.seeded => l10n.mapPreviewTrialNormal,
    FakeMapScenario.error => l10n.mapPreviewTrialError,
    FakeMapScenario.offline => l10n.locationTrialOffline,
  };
}
