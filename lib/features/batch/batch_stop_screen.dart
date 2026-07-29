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

/// P27 active stop — journey contract for Figma 125:402 / 125:370 / 125:464 /
/// 125:508 and the automatic-arrival status nodes 115:835 / 115:890 / 115:1000.
///
/// There is deliberately no "I arrived" button, gesture or Semantics action.
/// Arrival is produced only by [FakeBatchLocationController].
class BatchStopScreen extends ConsumerStatefulWidget {
  const BatchStopScreen({
    super.key,
    required this.batchId,
    required this.sequence,
  });

  final String batchId;
  final int sequence;

  static const pageKey = Key('batchStopScreen');
  static const deliverKey = Key('batchStopDeliver');
  static const issueKey = Key('batchStopIssue');
  static const retrySyncKey = Key('batchStopRetrySync');
  static const continueKey = Key('batchStopContinue');
  static const arrivedTitleKey = Key('batchStopArrivedTitle');
  static const nextStopKey = Key('batchStopNextHint');
  static const figmaArrivedKey = Key('figma_125_402');
  static const figmaClosedKey = Key('figma_125_508');
  static const figmaUnavailableKey = Key('figma_125_464');
  static const figmaLockedKey = Key('figma_125_370');

  @override
  ConsumerState<BatchStopScreen> createState() => _BatchStopScreenState();
}

class _BatchStopScreenState extends ConsumerState<BatchStopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _armFakeLocation());
  }

  @override
  void didUpdateWidget(covariant BatchStopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sequence != widget.sequence) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _armFakeLocation());
    }
  }

  void _armFakeLocation() {
    if (!mounted) return;
    final state = ref.read(batchControllerProvider);
    final order = state.batch?.orderBySequence(widget.sequence);
    if (order == null || !order.isActionable) return;
    if (order.state == BatchOrderState.arrived) return;
    if (order.state != BatchOrderState.headingToCustomer &&
        order.state != BatchOrderState.pickedUp) {
      return;
    }
    if (!state.isPickedUp) return;
    ref
        .read(fakeBatchLocationControllerProvider.notifier)
        .startApproach(widget.sequence);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(batchControllerProvider);
    final controller = ref.read(batchControllerProvider.notifier);
    final batch = state.batch;
    final order = batch?.orderBySequence(widget.sequence);

    ref.listen(batchControllerProvider, (previous, next) {
      if (next.routeStatus == BatchRouteStatus.offlineQueue &&
          next.currentSequence == widget.sequence) {
        return;
      }
      if (next.routeStatus == BatchRouteStatus.orderCancelledContinue ||
          next.routeStatus == BatchRouteStatus.customerUnavailable) {
        return;
      }
      if (previous?.routeStatus == BatchRouteStatus.processing &&
          next.routeStatus == BatchRouteStatus.overview &&
          next.batch?.orderBySequence(widget.sequence)?.isResolved == true) {
        final nextStop = next.batch?.actionableStops.firstOrNull;
        if (nextStop != null && nextStop.sequence != widget.sequence) {
          context.go(
            AppRoutes.batchStopPath(widget.batchId, nextStop.sequence),
          );
          return;
        }
        if (next.batch?.allResolved == true) {
          context.go(AppRoutes.batchSummaryPath(widget.batchId));
          return;
        }
        context.go(AppRoutes.batchRoutePath(widget.batchId));
      }
    });

    if (batch == null || order == null) {
      return Scaffold(
        key: BatchStopScreen.pageKey,
        body: BatchPage(
          title: l10n.batchRouteTitle,
          onBack: () => context.go(AppRoutes.batchRoutePath(widget.batchId)),
          children: [const P27Skeleton(height: 360)],
        ),
      );
    }

    final stop = BatchStopViewData(
      batch: batch,
      sequence: widget.sequence,
      order: order,
      nextSequence: _nextSequence(batch, widget.sequence),
    );

    return Scaffold(
      key: BatchStopScreen.pageKey,
      body: BatchPage(
        title: _title(l10n, state, stop),
        confirmBack: state.tripStarted,
        onConfirmBack: () => confirmBatchLeave(context),
        onBack: () => context.go(AppRoutes.batchRoutePath(widget.batchId)),
        children: _content(context, l10n, state, controller, stop),
      ),
    );
  }

  String _title(
    AppLocalizations l10n,
    BatchState state,
    BatchStopViewData stop,
  ) {
    if (stop.order.isResolved &&
        stop.order.state != BatchOrderState.customerUnavailable) {
      return l10n.batchDeliveredTitle;
    }
    if (state.routeStatus == BatchRouteStatus.customerUnavailable ||
        stop.order.state == BatchOrderState.customerUnavailable) {
      return l10n.batchCustomerUnavailableTitle;
    }
    if (state.hasArrivedAtCurrentStop &&
        stop.order.sequence == state.currentSequence) {
      return l10n.batchArrivedAutomaticallyTitle(
        stop.sequence,
        stop.orderCount,
      );
    }
    return l10n.batchStopLabel(stop.sequence);
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
    final contact = state.currentSequence == stop.sequence
        ? state.currentContact
        : BatchCustomerContactViewData(
            visibility: order.isResolved
                ? BatchCustomerContactVisibility.closed
                : BatchCustomerContactVisibility.locked,
            labelIndex: order.labelIndex,
          );
    final arrived = order.state == BatchOrderState.arrived;
    final closed =
        order.isResolved && order.state != BatchOrderState.customerUnavailable;
    final unavailable =
        order.state == BatchOrderState.customerUnavailable ||
        state.routeStatus == BatchRouteStatus.customerUnavailable;
    final nextDistrict = stop.nextSequence == null
        ? null
        : l10n.batchDistrictName(
            stop.batch.orderBySequence(stop.nextSequence!)?.labelIndex ?? 1,
          );

    return [
      if (arrived)
        const SizedBox(key: BatchStopScreen.figmaArrivedKey, height: 0),
      if (closed)
        const SizedBox(key: BatchStopScreen.figmaClosedKey, height: 0),
      if (unavailable)
        const SizedBox(key: BatchStopScreen.figmaUnavailableKey, height: 0),
      if (contact.visibility == BatchCustomerContactVisibility.locked)
        const SizedBox(key: BatchStopScreen.figmaLockedKey, height: 0),
      BatchJourneyTimeline(activeStage: state.journeyStage),
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
      if (unavailable)
        P27Banner(
          title: l10n.batchCustomerUnavailableTitle,
          message: l10n.batchCustomerUnavailableContactNote,
          tone: P27BannerTone.warning,
        ),
      if (closed)
        P27Banner(
          title: l10n.batchStopCompletedTitle(stop.sequence),
          message: l10n.batchContactHiddenAfterCloseMessage,
          tone: P27BannerTone.success,
        ),
      if (!arrived && !closed && !unavailable)
        P27Banner(
          title: l10n.batchEnRouteTitle,
          message: l10n.batchEnRouteMessage,
          tone: P27BannerTone.information,
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
      // Read-only automatic arrival status — never an interactive control.
      const BatchAutomaticArrivalStatus(),
      if (arrived)
        Text(
          key: BatchStopScreen.arrivedTitleKey,
          l10n.batchArrivedAutomaticallyTitle(stop.sequence, stop.orderCount),
          style: AppTextStyles.titleMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      BatchCustomerContactCard(
        contact: contact,
        l10n: l10n,
        onCall: contact.isRevealed ? controller.recordCallAttempt : null,
        onWhatsapp: contact.isRevealed
            ? controller.recordWhatsappAttempt
            : null,
      ),
      if (nextDistrict != null && !closed)
        Container(
          key: BatchStopScreen.nextStopKey,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${stop.nextSequence}',
                  style: AppTextStyles.label.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.batchNextStopTitle(nextDistrict),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.batchNextStopHiddenMessage,
                      style: AppTextStyles.supporting.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.informationContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.batchNextStopBadge,
                  style: AppTextStyles.supporting.copyWith(
                    color: colors.information,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      P27Field(
        label: l10n.batchOrderLabel(order.maskedOrderId),
        value: batchOrderStateLabel(l10n, order.state),
      ),
      P27Field(
        label: l10n.batchStopDistanceLabel,
        value: l10n.batchDistanceValue(formatBatchDistance(order.distanceKm)),
      ),
      if (!arrived && order.isActionable)
        Text(
          l10n.batchDeliveryLockedHint,
          style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
        ),
      if (state.routeStatus == BatchRouteStatus.offlineQueue)
        SizedBox(
          height: 56,
          child: SaeqPrimaryButton(
            key: BatchStopScreen.retrySyncKey,
            label: l10n.batchRetrySyncAction,
            icon: Icons.sync_outlined,
            onPressed: controller.retryQueuedSync,
          ),
        ),
      if (state.routeStatus == BatchRouteStatus.orderCancelledContinue ||
          unavailable)
        SizedBox(
          height: 48,
          child: SaeqSecondaryButton(
            key: BatchStopScreen.continueKey,
            label: l10n.batchContinueRemainingAction,
            onPressed: () {
              controller.continueBatch();
              context.go(AppRoutes.batchRoutePath(widget.batchId));
            },
          ),
        ),
      if (order.isActionable && arrived)
        SizedBox(
          height: 56,
          child: SaeqPrimaryButton(
            key: BatchStopScreen.deliverKey,
            label: state.isProcessing
                ? l10n.batchManualDeliveryProcessingLabel
                : l10n.batchManualDeliveryAction,
            icon: Icons.check_circle_outline,
            onPressed: state.canConfirmDeliveryManually
                ? controller.confirmDeliveryManually
                : null,
            isLoading: state.isProcessing,
          ),
        ),
      if (order.isActionable)
        SizedBox(
          height: 48,
          child: SaeqSecondaryButton(
            key: BatchStopScreen.issueKey,
            label: l10n.batchReportIssueAction,
            onPressed: state.isProcessing
                ? null
                : () => context.go(
                    AppRoutes.batchIssuePath(widget.batchId, order.orderId),
                  ),
          ),
        ),
    ];
  }
}
