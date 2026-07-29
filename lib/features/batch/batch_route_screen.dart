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

/// P27 route overview + restored banner (115:737 / 115:1078).
class BatchRouteScreen extends ConsumerWidget {
  const BatchRouteScreen({super.key, required this.batchId});

  final String batchId;

  static const pageKey = Key('batchRouteScreen');
  static const startKey = Key('batchRouteStart');
  static const finishKey = Key('batchRouteFinish');
  static const resumeKey = Key('batchRouteResume');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(batchControllerProvider);
    final controller = ref.read(batchControllerProvider.notifier);
    final batch = state.batch;

    ref.listen(batchControllerProvider, (previous, next) {
      if (next.summaryStatus == BatchSummaryStatus.completed ||
          next.summaryStatus == BatchSummaryStatus.partial ||
          next.summaryStatus == BatchSummaryStatus.cancelledOrderIncluded) {
        if (next.batch?.allResolved == true) {
          context.go(AppRoutes.batchSummaryPath(batchId));
        }
      }
    });

    return Scaffold(
      key: pageKey,
      body: BatchPage(
        title: l10n.batchRouteTitle,
        confirmBack: state.tripStarted,
        onConfirmBack: () => confirmBatchLeave(context),
        onBack: () => _back(context),
        children: batch == null
            ? [const P27Skeleton(height: 360)]
            : _content(context, l10n, state, controller, batch),
      ),
    );
  }

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.deliveryOffer);
  }

  List<Widget> _content(
    BuildContext context,
    AppLocalizations l10n,
    BatchState state,
    BatchController controller,
    BatchOfferViewData batch,
  ) {
    final colors = SaeqSemanticColors.of(context);
    final actionable = batch.actionableStops;
    final nextStop = actionable.isEmpty ? null : actionable.first;

    return [
      if (state.restoredFromSnapshot ||
          state.routeStatus == BatchRouteStatus.restoredAfterRestart)
        P27Banner(
          title: l10n.batchRestoredTitle,
          message: l10n.batchRestoredMessage,
          tone: P27BannerTone.information,
        ),
      if (!state.isPickedUp)
        P27Banner(
          title: l10n.batchRouteLockedTitle,
          message: l10n.batchRouteLockedMessage,
          tone: P27BannerTone.warning,
        )
      else
        P27Banner(
          title: l10n.batchRouteOverviewTitle,
          message: l10n.batchRouteOverviewMessage,
          tone: P27BannerTone.information,
        ),
      BatchJourneyTimeline(activeStage: state.journeyStage),
      BatchMultiStopMap(
        stopCount: batch.orderCount,
        activeSequence: state.currentSequence,
      ),
      BatchProgressBar(
        resolved: batch.resolvedCount,
        total: batch.orderCount,
        label: l10n.batchProgressLabel(batch.resolvedCount, batch.orderCount),
      ),
      for (final order in batch.orders)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BatchOrderRow(
            order: order,
            l10n: l10n,
            highlight: order.sequence == state.currentSequence,
          ),
        ),
      if (state.restoredFromSnapshot)
        SizedBox(
          height: 56,
          child: SaeqPrimaryButton(
            key: resumeKey,
            label: l10n.batchResumeAction,
            icon: Icons.play_arrow_outlined,
            onPressed: controller.resumeAfterRestore,
          ),
        )
      else if (nextStop != null && state.canStartRoute)
        SizedBox(
          height: 56,
          child: SaeqPrimaryButton(
            key: startKey,
            label: l10n.batchOpenStopAction(nextStop.sequence),
            icon: Icons.navigation_outlined,
            onPressed: () {
              controller.openStop(nextStop.sequence);
              context.go(AppRoutes.batchStopPath(batchId, nextStop.sequence));
            },
          ),
        ),
      if (!state.canFinishBatch)
        Text(
          l10n.batchFinishDisabledHint,
          style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
        ),
      SizedBox(
        height: 56,
        child: SaeqPrimaryButton(
          key: finishKey,
          label: l10n.batchFinishAction,
          onPressed: state.canFinishBatch
              ? () {
                  controller.finishBatch();
                  context.go(AppRoutes.batchSummaryPath(batchId));
                }
              : null,
        ),
      ),
      if (state.routeStatus == BatchRouteStatus.orderCancelledContinue ||
          state.routeStatus == BatchRouteStatus.customerUnavailable)
        SizedBox(
          height: 48,
          child: SaeqSecondaryButton(
            label: l10n.batchContinueRemainingAction,
            onPressed: () {
              controller.continueBatch();
              final next = state.batch?.actionableStops.firstOrNull;
              if (next != null) {
                context.go(AppRoutes.batchStopPath(batchId, next.sequence));
              }
            },
          ),
        ),
    ];
  }
}
