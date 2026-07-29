import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';
import '../../features/location/location_ui_helpers.dart';
import '../../shared/widgets/saeq_primary_button.dart';
import '../../shared/widgets/saeq_secondary_button.dart';
import 'batch_feature.dart';
import 'batch_offer_screen.dart';
import 'batch_ui_helpers.dart';
import 'batch_view_data.dart';

/// P27 active stop states (115:786 / 115:837 / 115:955 / 115:892).
class BatchStopScreen extends ConsumerWidget {
  const BatchStopScreen({
    super.key,
    required this.batchId,
    required this.sequence,
  });

  final String batchId;
  final int sequence;

  static const pageKey = Key('batchStopScreen');
  static const arriveKey = Key('batchStopArrive');
  static const deliverKey = Key('batchStopDeliver');
  static const issueKey = Key('batchStopIssue');
  static const retrySyncKey = Key('batchStopRetrySync');
  static const continueKey = Key('batchStopContinue');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(batchControllerProvider);
    final controller = ref.read(batchControllerProvider.notifier);
    final batch = state.batch;
    final order = batch?.orderBySequence(sequence);

    ref.listen(batchControllerProvider, (previous, next) {
      if (next.routeStatus == BatchRouteStatus.offlineQueue &&
          next.currentSequence == sequence) {
        return;
      }
      if (next.routeStatus == BatchRouteStatus.orderCancelledContinue ||
          next.routeStatus == BatchRouteStatus.customerUnavailable) {
        return;
      }
      if (previous?.routeStatus == BatchRouteStatus.processing &&
          next.routeStatus == BatchRouteStatus.overview &&
          next.batch?.orderBySequence(sequence)?.isResolved == true) {
        final nextStop = next.batch?.actionableStops.firstOrNull;
        if (nextStop != null && nextStop.sequence != sequence) {
          context.go(AppRoutes.batchStopPath(batchId, nextStop.sequence));
          return;
        }
        if (next.batch?.allResolved == true) {
          context.go(AppRoutes.batchSummaryPath(batchId));
          return;
        }
        context.go(AppRoutes.batchRoutePath(batchId));
      }
    });

    if (batch == null || order == null) {
      return Scaffold(
        key: pageKey,
        body: BatchPage(
          title: l10n.batchRouteTitle,
          onBack: () => context.go(AppRoutes.batchRoutePath(batchId)),
          children: [const P27Skeleton(height: 360)],
        ),
      );
    }

    final stop = BatchStopViewData(
      batch: batch,
      sequence: sequence,
      order: order,
      nextSequence: _nextSequence(batch, sequence),
    );

    return Scaffold(
      key: pageKey,
      body: BatchPage(
        title: l10n.batchStopLabel(sequence),
        confirmBack: state.tripStarted,
        onConfirmBack: () => confirmBatchLeave(context),
        onBack: () => context.go(AppRoutes.batchRoutePath(batchId)),
        children: _content(context, l10n, state, controller, stop),
      ),
    );
  }

  int? _nextSequence(BatchOfferViewData batch, int sequence) {
    for (final order in batch.actionableStops) {
      if (order.sequence > sequence) return order.sequence;
    }
    return null;
  }

  List<Widget> _content(
    BuildContext context,
    AppLocalizations l10n,
    BatchState state,
    BatchController controller,
    BatchStopViewData stop,
  ) {
    final colors = SaeqSemanticColors.of(context);
    final order = stop.order;
    final customer = l10n.batchCustomerFirstName(order.labelIndex);
    final district = l10n.batchDistrictName(order.labelIndex);
    final arrived =
        order.state == BatchOrderState.arrived ||
        order.state == BatchOrderState.delivered ||
        order.state == BatchOrderState.deliveredPendingSync;
    final isFinal = stop.isFinalStop;
    final remaining = stop.batch.actionableStops.length - 1;

    return [
      if (state.routeStatus == BatchRouteStatus.offlineQueue)
        P27Banner(
          title: l10n.batchOfflineQueueTitle,
          message: l10n.batchOfflineQueueMessage,
          tone: P27BannerTone.warning,
        ),
      if (state.routeStatus == BatchRouteStatus.orderCancelledContinue)
        P27Banner(
          title: l10n.batchOrderCancelledTitle,
          message: l10n.batchOrderCancelledMessage,
          tone: P27BannerTone.warning,
        ),
      if (state.routeStatus == BatchRouteStatus.customerUnavailable)
        P27Banner(
          title: l10n.batchCustomerUnavailableTitle,
          message: l10n.batchCustomerUnavailableMessage,
          tone: P27BannerTone.warning,
        ),
      BatchMultiStopMap(
        stopCount: stop.orderCount,
        activeSequence: stop.sequence,
        height: 180,
      ),
      BatchProgressBar(
        resolved: stop.resolvedCount,
        total: stop.orderCount,
        label: l10n.batchProgressLabel(stop.resolvedCount, stop.orderCount),
      ),
      P27Field(label: l10n.batchStopCustomerLabel, value: customer),
      P27Field(label: l10n.batchStopAreaLabel, value: district),
      P27Field(
        label: l10n.batchOrderLabel(order.maskedOrderId),
        value: batchOrderStateLabel(l10n, order.state),
      ),
      P27Field(
        label: l10n.batchStopDistanceLabel,
        value: l10n.batchDistanceValue(formatBatchDistance(order.distanceKm)),
      ),
      P27Field(
        label: l10n.batchStopEarningsLabel,
        value: l10n.batchEarningsValue(formatBatchEarnings(order.earningsSar)),
      ),
      Text(
        isFinal
            ? l10n.batchStopFinalHint
            : l10n.batchStopNextHint(remaining.clamp(0, 99)),
        style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
      ),
      Text(
        l10n.batchPrivacyNote,
        style: AppTextStyles.supporting.copyWith(color: colors.textSecondary),
      ),
      if (state.routeStatus == BatchRouteStatus.offlineQueue)
        SizedBox(
          height: 56,
          child: SaeqPrimaryButton(
            key: retrySyncKey,
            label: l10n.batchRetrySyncAction,
            icon: Icons.sync_outlined,
            onPressed: controller.retryQueuedSync,
          ),
        ),
      if (state.routeStatus == BatchRouteStatus.orderCancelledContinue ||
          state.routeStatus == BatchRouteStatus.customerUnavailable)
        SizedBox(
          height: 48,
          child: SaeqSecondaryButton(
            key: continueKey,
            label: l10n.batchContinueRemainingAction,
            onPressed: () {
              controller.continueBatch();
              context.go(AppRoutes.batchRoutePath(batchId));
            },
          ),
        ),
      if (order.isActionable &&
          state.routeStatus != BatchRouteStatus.offlineQueue)
        SizedBox(
          height: 56,
          child: SaeqPrimaryButton(
            key: arriveKey,
            label: l10n.batchArriveAction,
            icon: Icons.place_outlined,
            onPressed: arrived || state.isProcessing
                ? null
                : controller.markArrived,
          ),
        ),
      if (order.isActionable && arrived)
        SizedBox(
          height: 56,
          child: SaeqPrimaryButton(
            key: deliverKey,
            label: state.isProcessing
                ? l10n.batchProcessingLabel
                : l10n.batchDeliverAction,
            icon: Icons.check_circle_outline,
            onPressed: state.isProcessing ? null : controller.confirmDelivery,
            isLoading: state.isProcessing,
          ),
        ),
      if (order.isActionable)
        SizedBox(
          height: 48,
          child: SaeqSecondaryButton(
            key: issueKey,
            label: l10n.batchReportIssueAction,
            onPressed: state.isProcessing
                ? null
                : () => context.go(
                    AppRoutes.batchIssuePath(batchId, order.orderId),
                  ),
          ),
        ),
    ];
  }
}
