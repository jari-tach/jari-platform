import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';
import '../../shared/widgets/saeq_status_chip.dart';
import 'location_feature.dart';
import 'map_preview_feature.dart';

enum P27BannerTone { information, success, warning, error }

class P27Page extends StatelessWidget {
  const P27Page({
    super.key,
    required this.title,
    required this.children,
    this.onBack,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                BackButton(onPressed: onBack),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  key: const Key('p27PageTitle'),
                  style: AppTextStyles.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class P27Banner extends StatelessWidget {
  const P27Banner({
    super.key,
    required this.title,
    required this.message,
    required this.tone,
  });

  final String title;
  final String message;
  final P27BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final (foreground, background, icon) = switch (tone) {
      P27BannerTone.information => (
        colors.information,
        colors.informationContainer,
        Icons.info_outline,
      ),
      P27BannerTone.success => (
        colors.success,
        colors.successContainer,
        Icons.check_circle_outline,
      ),
      P27BannerTone.warning => (
        colors.warning,
        colors.warningContainer,
        Icons.warning_amber_outlined,
      ),
      P27BannerTone.error => (
        colors.error,
        colors.errorContainer,
        Icons.error_outline,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: foreground.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class P27Field extends StatelessWidget {
  const P27Field({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.supporting.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class P27Skeleton extends StatelessWidget {
  const P27Skeleton({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: colors.border.withValues(alpha: .7),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            const SizedBox(height: 8),
            FractionallySizedBox(
              widthFactor: .68,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: colors.border.withValues(alpha: .5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class P27FakeMap extends StatelessWidget {
  const P27FakeMap({
    super.key,
    this.height = 300,
    this.snapshot = FakeMapPreviewService.defaultSnapshot,
  });

  final double height;
  final FakeMapSnapshot snapshot;

  static const mapKey = Key('p27FakeMap');
  static const driverMarkerKey = Key('p27DriverMarker');
  static const pickupMarkerKey = Key('p27PickupMarker');
  static const dropoffMarkerKey = Key('p27DropoffMarker');

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      key: mapKey,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? colors.elevatedSurface.withValues(alpha: .78)
            : colors.primaryContainer.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _P27MapPainter(
                  snapshot: snapshot,
                  roadColor: isDark
                      ? colors.border.withValues(alpha: .9)
                      : colors.surface.withValues(alpha: .95),
                  routeColor: colors.primary,
                ),
              ),
            ),
            _P27Marker(
              key: driverMarkerKey,
              point: snapshot.driver,
              color: colors.information,
              icon: Icons.navigation,
            ),
            _P27Marker(
              key: pickupMarkerKey,
              point: snapshot.pickup,
              color: colors.warning,
              icon: Icons.place,
            ),
            _P27Marker(
              key: dropoffMarkerKey,
              point: snapshot.dropoff,
              color: colors.success,
              icon: Icons.flag,
            ),
          ],
        ),
      ),
    );
  }
}

class _P27Marker extends StatelessWidget {
  const _P27Marker({
    super.key,
    required this.point,
    required this.color,
    required this.icon,
  });

  final FakeMapPoint point;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment(point.dx * 2 - 1, point.dy * 2 - 1),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

class _P27MapPainter extends CustomPainter {
  const _P27MapPainter({
    required this.snapshot,
    required this.roadColor,
    required this.routeColor,
  });

  final FakeMapSnapshot snapshot;
  final Color roadColor;
  final Color routeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = roadColor
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-20, size.height * .28),
      Offset(size.width + 20, size.height * .68),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .18, -20),
      Offset(size.width * .62, size.height + 20),
      road,
    );
    canvas.drawLine(
      Offset(-20, size.height * .82),
      Offset(size.width + 20, size.height * .38),
      road,
    );

    if (snapshot.route.isEmpty) return;
    final route = Paint()
      ..color = routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    final first = snapshot.route.first;
    path.moveTo(first.dx * size.width, first.dy * size.height);
    for (final point in snapshot.route.skip(1)) {
      path.lineTo(point.dx * size.width, point.dy * size.height);
    }
    canvas.drawPath(path, route);
  }

  @override
  bool shouldRepaint(_P27MapPainter oldDelegate) =>
      oldDelegate.snapshot != snapshot ||
      oldDelegate.roadColor != roadColor ||
      oldDelegate.routeColor != routeColor;
}

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
