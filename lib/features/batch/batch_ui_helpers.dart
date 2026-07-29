import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';
import '../../shared/widgets/saeq_status_chip.dart';
import 'batch_view_data.dart';

/// P27 batch screen shell — reuses the same spacing rhythm as STEP 2B.
class BatchPage extends StatelessWidget {
  const BatchPage({
    super.key,
    required this.title,
    required this.children,
    this.onBack,
    this.confirmBack = false,
    this.onConfirmBack,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;
  final bool confirmBack;
  final Future<bool> Function()? onConfirmBack;

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
                BackButton(
                  onPressed: () async {
                    if (confirmBack && onConfirmBack != null) {
                      final leave = await onConfirmBack!();
                      if (!leave) return;
                    }
                    onBack!();
                  },
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  key: const Key('batchPageTitle'),
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

/// Figma 115:370 — Batch/Order Row.
class BatchOrderRow extends StatelessWidget {
  const BatchOrderRow({
    super.key,
    required this.order,
    required this.l10n,
    this.trailing,
    this.highlight = false,
  });

  static const rowKey = Key('batchOrderRow');

  final BatchOrderViewData order;
  final AppLocalizations l10n;
  final Widget? trailing;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final customer = l10n.batchCustomerFirstName(order.labelIndex);
    final district = l10n.batchDistrictName(order.labelIndex);
    return Semantics(
      key: ValueKey('batchOrderRow_${order.orderId}'),
      label:
          '${l10n.batchStopLabel(order.sequence)}. ${l10n.batchOrderLabel(order.maskedOrderId)}. $customer. ${batchOrderStateLabel(l10n, order.state)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: highlight ? colors.primaryContainer : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? colors.primary : colors.border,
            width: highlight ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            _StopBadge(sequence: order.sequence, highlight: highlight),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.batchOrderLabel(order.maskedOrderId),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$customer · $district',
                    style: AppTextStyles.supporting.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SaeqStatusChip(
              label: batchOrderStateLabel(l10n, order.state),
              tone: batchOrderStateTone(order.state),
              icon: batchOrderStateIcon(order.state),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

class _StopBadge extends StatelessWidget {
  const _StopBadge({required this.sequence, required this.highlight});

  final int sequence;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlight ? colors.primary : colors.elevatedSurface,
        shape: BoxShape.circle,
        border: Border.all(color: highlight ? colors.primary : colors.border),
      ),
      child: Text(
        '$sequence',
        style: AppTextStyles.label.copyWith(
          color: highlight ? Colors.white : colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Figma 115:379 — Batch/Metric Chip.
class BatchMetricChip extends StatelessWidget {
  const BatchMetricChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.semanticsKey,
  });

  static const chipKey = Key('batchMetricChip');

  final String label;
  final String value;
  final IconData? icon;
  final Key? semanticsKey;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return Semantics(
      key: semanticsKey,
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.elevatedSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.supporting.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma 115:399 — Batch/Progress.
class BatchProgressBar extends StatelessWidget {
  const BatchProgressBar({
    super.key,
    required this.resolved,
    required this.total,
    required this.label,
  });

  static const progressKey = Key('batchProgressBar');

  final int resolved;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final fraction = total == 0 ? 0.0 : resolved / total;
    return Semantics(
      key: progressKey,
      label: label,
      value: '${(fraction * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              backgroundColor: colors.border,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma 115:383 — Batch/Multi Stop Map (custom-painted, no map SDK).
class BatchMultiStopMap extends StatelessWidget {
  const BatchMultiStopMap({
    super.key,
    required this.stopCount,
    required this.activeSequence,
    this.height = 220,
  });

  static const mapKey = Key('batchMultiStopMap');

  final int stopCount;
  final int activeSequence;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      key: mapKey,
      label: 'Batch stops preview',
      child: Container(
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
          child: CustomPaint(
            painter: _BatchMapPainter(
              stopCount: stopCount,
              activeSequence: activeSequence,
              roadColor: isDark
                  ? colors.border.withValues(alpha: .9)
                  : colors.surface.withValues(alpha: .95),
              routeColor: colors.primary,
              pickupColor: colors.warning,
              stopColor: colors.information,
              activeColor: colors.success,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _BatchMapPainter extends CustomPainter {
  const _BatchMapPainter({
    required this.stopCount,
    required this.activeSequence,
    required this.roadColor,
    required this.routeColor,
    required this.pickupColor,
    required this.stopColor,
    required this.activeColor,
  });

  final int stopCount;
  final int activeSequence;
  final Color roadColor;
  final Color routeColor;
  final Color pickupColor;
  final Color stopColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = roadColor
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-10, size.height * .3),
      Offset(size.width + 10, size.height * .7),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .2, -10),
      Offset(size.width * .65, size.height + 10),
      road,
    );

    final pickup = Offset(size.width * .18, size.height * .28);
    final stops = <Offset>[
      for (var i = 0; i < stopCount; i++)
        Offset(
          size.width * (.35 + i * .14),
          size.height * (.45 + (i.isEven ? .08 : -.04)),
        ),
    ];

    final route = Paint()
      ..color = routeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pickup.dx, pickup.dy);
    for (final stop in stops) {
      path.lineTo(stop.dx, stop.dy);
    }
    canvas.drawPath(path, route);

    _drawMarker(canvas, pickup, pickupColor);
    for (var i = 0; i < stops.length; i++) {
      final color = i + 1 == activeSequence ? activeColor : stopColor;
      _drawMarker(canvas, stops[i], color);
    }
  }

  void _drawMarker(Canvas canvas, Offset center, Color color) {
    canvas.drawCircle(center, 10, Paint()..color = color);
    canvas.drawCircle(
      center,
      10,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_BatchMapPainter oldDelegate) =>
      oldDelegate.stopCount != stopCount ||
      oldDelegate.activeSequence != activeSequence;
}

String batchOrderStateLabel(AppLocalizations l10n, BatchOrderState state) {
  return switch (state) {
    BatchOrderState.offered => l10n.batchOrderStateOffered,
    BatchOrderState.preparing => l10n.batchOrderStatePreparing,
    BatchOrderState.readyForPickup => l10n.batchOrderStateReady,
    BatchOrderState.pickedUp => l10n.batchOrderStatePickedUp,
    BatchOrderState.verified => l10n.batchOrderStateVerified,
    BatchOrderState.headingToCustomer => l10n.batchOrderStateHeading,
    BatchOrderState.arrived => l10n.batchOrderStateArrived,
    BatchOrderState.delivered => l10n.batchOrderStateDelivered,
    BatchOrderState.deliveredPendingSync => l10n.batchOrderStatePendingSync,
    BatchOrderState.customerUnavailable => l10n.batchOrderStateUnavailable,
    BatchOrderState.cancelled => l10n.batchOrderStateCancelled,
    BatchOrderState.expired => l10n.batchOrderStateExpired,
  };
}

SaeqStatusTone batchOrderStateTone(BatchOrderState state) {
  return switch (state) {
    BatchOrderState.delivered ||
    BatchOrderState.verified ||
    BatchOrderState.readyForPickup => SaeqStatusTone.success,
    BatchOrderState.preparing ||
    BatchOrderState.pickedUp ||
    BatchOrderState.headingToCustomer ||
    BatchOrderState.arrived => SaeqStatusTone.neutral,
    BatchOrderState.deliveredPendingSync => SaeqStatusTone.warning,
    BatchOrderState.customerUnavailable ||
    BatchOrderState.cancelled ||
    BatchOrderState.expired => SaeqStatusTone.danger,
    _ => SaeqStatusTone.neutral,
  };
}

IconData batchOrderStateIcon(BatchOrderState state) {
  return switch (state) {
    BatchOrderState.delivered => Icons.check_circle_outline,
    BatchOrderState.verified => Icons.verified_outlined,
    BatchOrderState.readyForPickup => Icons.inventory_2_outlined,
    BatchOrderState.deliveredPendingSync => Icons.cloud_off_outlined,
    BatchOrderState.customerUnavailable => Icons.person_off_outlined,
    BatchOrderState.cancelled => Icons.cancel_outlined,
    BatchOrderState.expired => Icons.timer_off_outlined,
    BatchOrderState.arrived => Icons.place_outlined,
    BatchOrderState.headingToCustomer => Icons.local_shipping_outlined,
    _ => Icons.circle_outlined,
  };
}

String formatBatchDistance(double km) => km.toStringAsFixed(1);

String formatBatchEarnings(double sar) {
  final rounded = sar == sar.roundToDouble() ? sar.toInt() : sar;
  return '$rounded';
}
