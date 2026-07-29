import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';
import '../../shared/widgets/saeq_primary_button.dart';
import '../../shared/widgets/saeq_secondary_button.dart';
import '../../shared/widgets/saeq_status_chip.dart';
import 'location_ui_helpers.dart';
import 'map_preview_feature.dart';

/// Widget-composed fake map preview: driver, pickup and dropoff markers, a
/// painted route line, the accuracy indicator, and the trial actions.
///
/// No map SDK, no tiles, no API key, no navigation intent.
class FakeMapPlaceholder extends StatelessWidget {
  const FakeMapPlaceholder({
    super.key,
    required this.snapshot,
    required this.isProcessing,
    required this.onRetry,
    required this.onOpenExternalNavigation,
    required this.onBack,
    this.externalNavigationUnavailable = false,
  });

  final FakeMapSnapshot snapshot;
  final bool isProcessing;
  final VoidCallback onRetry;
  final VoidCallback onOpenExternalNavigation;
  final VoidCallback onBack;
  final bool externalNavigationUnavailable;

  static const mapKey = Key('fakeMapPlaceholder');
  static const routeKey = Key('fakeMapRouteLine');
  static const driverMarkerKey = Key('fakeMapDriverMarker');
  static const pickupMarkerKey = Key('fakeMapPickupMarker');
  static const dropoffMarkerKey = Key('fakeMapDropoffMarker');
  static const accuracyKey = Key('fakeMapAccuracyIndicator');
  static const retryKey = Key('fakeMapRetryAction');
  static const externalNavigationKey = Key('fakeMapExternalNavigationAction');
  static const externalNavigationNoticeKey = Key(
    'fakeMapExternalNavigationNotice',
  );
  static const backKey = Key('fakeMapBackAction');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l10n.mapPreviewRouteSemantics,
          child: Container(
            key: mapKey,
            decoration: BoxDecoration(
              color: colors.elevatedSurface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              border: Border.all(color: colors.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLG),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        key: routeKey,
                        painter: _FakeRoutePainter(
                          snapshot: snapshot,
                          gridColor: colors.border,
                          routeColor: colors.primary,
                          accuracyColor: colors.information,
                        ),
                      ),
                    ),
                    _MapMarker(
                      key: driverMarkerKey,
                      point: snapshot.driver,
                      icon: Icons.person_pin_circle,
                      label: l10n.mapPreviewDriverMarker,
                      background: colors.informationContainer,
                      foreground: colors.information,
                    ),
                    _MapMarker(
                      key: pickupMarkerKey,
                      point: snapshot.pickup,
                      icon: Icons.place,
                      label: l10n.mapPreviewPickupMarker,
                      background: colors.primaryContainer,
                      foreground: colors.primary,
                    ),
                    _MapMarker(
                      key: dropoffMarkerKey,
                      point: snapshot.dropoff,
                      icon: Icons.flag,
                      label: l10n.mapPreviewDropoffMarker,
                      background: colors.successContainer,
                      foreground: colors.success,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMD),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SaeqStatusChip(
            key: accuracyKey,
            label: locationAccuracyChipLabel(
              l10n,
              snapshot.accuracy,
              snapshot.accuracyMeters,
            ),
            tone: locationAccuracyTone(snapshot.accuracy),
            icon: locationAccuracyIcon(snapshot.accuracy),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          l10n.mapPreviewPlaceholderNote,
          style: AppTextStyles.supporting.copyWith(color: colors.textSecondary),
        ),
        if (externalNavigationUnavailable) ...[
          const SizedBox(height: AppTheme.spacingMD),
          _ExternalNavigationNotice(
            key: externalNavigationNoticeKey,
            title: l10n.mapPreviewExternalNavigationUnavailableTitle,
            message: l10n.mapPreviewExternalNavigationUnavailableMessage,
          ),
        ],
        const SizedBox(height: AppTheme.spacingLG),
        SaeqPrimaryButton(
          key: externalNavigationKey,
          label: l10n.mapPreviewOpenExternalNavigationAction,
          icon: Icons.navigation_outlined,
          onPressed: isProcessing ? null : onOpenExternalNavigation,
          isLoading: isProcessing,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        SaeqSecondaryButton(
          key: retryKey,
          label: l10n.profileRetry,
          icon: Icons.refresh,
          onPressed: isProcessing ? null : onRetry,
        ),
        if (externalNavigationUnavailable) ...[
          const SizedBox(height: AppTheme.spacingSM),
          SaeqSecondaryButton(
            key: backKey,
            label: l10n.mapPreviewBackAction,
            icon: Icons.arrow_back,
            onPressed: onBack,
          ),
        ],
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    super.key,
    required this.point,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final FakeMapPoint point;
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Align(
      // Map geometry is absolute: markers must not mirror in RTL.
      alignment: Alignment(point.dx * 2 - 1, point.dy * 2 - 1),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: foreground.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.status.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExternalNavigationNotice extends StatelessWidget {
  const _ExternalNavigationNotice({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: colors.warningContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_outlined, color: colors.warning, size: 20),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
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
      ),
    );
  }
}

class _FakeRoutePainter extends CustomPainter {
  const _FakeRoutePainter({
    required this.snapshot,
    required this.gridColor,
    required this.routeColor,
    required this.accuracyColor,
  });

  final FakeMapSnapshot snapshot;
  final Color gridColor;
  final Color routeColor;
  final Color accuracyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = AppTheme.borderWidthThin;
    for (var i = 1; i < 5; i++) {
      final dx = size.width * i / 5;
      final dy = size.height * i / 5;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    canvas.drawCircle(
      _offsetOf(snapshot.driver, size),
      size.shortestSide * 0.16,
      Paint()..color = accuracyColor.withValues(alpha: 0.18),
    );

    if (snapshot.route.isEmpty) return;
    final routePaint = Paint()
      ..color = routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    final start = _offsetOf(snapshot.route.first, size);
    path.moveTo(start.dx, start.dy);
    for (final point in snapshot.route.skip(1)) {
      final offset = _offsetOf(point, size);
      path.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(path, routePaint);
  }

  static Offset _offsetOf(FakeMapPoint point, Size size) =>
      Offset(point.dx * size.width, point.dy * size.height);

  @override
  bool shouldRepaint(_FakeRoutePainter oldDelegate) {
    return oldDelegate.snapshot != snapshot ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.routeColor != routeColor ||
        oldDelegate.accuracyColor != accuracyColor;
  }
}
