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
import 'batch_ui_helpers.dart';
import 'batch_view_data.dart';

/// P27 batch summary (115:1142 / 115:1196).
class BatchSummaryScreen extends ConsumerWidget {
  const BatchSummaryScreen({super.key, required this.batchId});

  final String batchId;

  static const pageKey = Key('batchSummaryScreen');
  static const breakdownKey = Key('batchSummaryBreakdown');
  static const homeKey = Key('batchSummaryHome');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(batchControllerProvider);
    final controller = ref.read(batchControllerProvider.notifier);
    final batch = state.batch;

    ref.listen(batchControllerProvider, (previous, next) {
      if (next.summaryStatus == BatchSummaryStatus.returnHome) {
        context.go(AppRoutes.home);
      }
    });

    if (batch != null && !batch.allResolved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.finishBatchStatusOnly();
      });
    }

    return Scaffold(
      key: pageKey,
      body: BatchPage(
        title: l10n.batchSummaryTitle,
        onBack: () => context.go(AppRoutes.home),
        children: batch == null
            ? [const P27Skeleton(height: 360)]
            : _content(context, l10n, state, controller, batch),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    AppLocalizations l10n,
    BatchState state,
    BatchController controller,
    BatchOfferViewData batch,
  ) {
    final summary = BatchSummaryViewData(batch: batch);
    final showingBreakdown =
        state.summaryStatus == BatchSummaryStatus.earningsBreakdown;
    final (title, message, tone) = switch (state.summaryStatus) {
      BatchSummaryStatus.completed => (
        l10n.batchSummaryCompletedTitle,
        l10n.batchSummaryCompletedMessage,
        P27BannerTone.success,
      ),
      BatchSummaryStatus.cancelledOrderIncluded => (
        l10n.batchSummaryCancelledIncludedTitle,
        l10n.batchSummaryCancelledIncludedMessage,
        P27BannerTone.warning,
      ),
      BatchSummaryStatus.earningsBreakdown => (
        l10n.batchSummaryTitle,
        l10n.batchSummaryPartialMessage,
        P27BannerTone.information,
      ),
      _ => (
        l10n.batchSummaryPartialTitle,
        l10n.batchSummaryPartialMessage,
        P27BannerTone.warning,
      ),
    };

    return [
      P27Banner(title: title, message: message, tone: tone),
      BatchProgressBar(
        resolved: batch.resolvedCount,
        total: batch.orderCount,
        label: l10n.batchProgressLabel(batch.resolvedCount, batch.orderCount),
      ),
      P27Field(
        label: l10n.batchSummaryTotalLabel,
        value: l10n.batchEarningsValue(
          formatBatchEarnings(summary.totalEarnedSar),
        ),
      ),
      if (summary.completedOrders.isNotEmpty) ...[
        Text(
          l10n.batchSummaryCompletedSection,
          style: AppTextStyles.titleMedium.copyWith(
            color: SaeqSemanticColors.of(context).textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final order in summary.completedOrders)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BatchOrderRow(order: order, l10n: l10n),
          ),
      ],
      if (summary.incompleteOrders.isNotEmpty) ...[
        Text(
          l10n.batchSummaryIncompleteSection,
          style: AppTextStyles.titleMedium.copyWith(
            color: SaeqSemanticColors.of(context).textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        for (final order in summary.incompleteOrders)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BatchOrderRow(order: order, l10n: l10n),
          ),
      ],
      if (showingBreakdown)
        for (final order in batch.orders)
          P27Field(
            key: Key('batchEarning_${order.orderId}'),
            label: l10n.batchOrderLabel(order.maskedOrderId),
            value: order.isCompleted
                ? l10n.batchEarningsValue(
                    formatBatchEarnings(order.earningsSar),
                  )
                : batchOrderStateLabel(l10n, order.state),
          ),
      SizedBox(
        height: 48,
        child: SaeqSecondaryButton(
          key: breakdownKey,
          label: showingBreakdown
              ? l10n.batchSummaryHideBreakdownAction
              : l10n.batchSummaryBreakdownAction,
          onPressed: showingBreakdown
              ? controller.hideEarningsBreakdown
              : controller.showEarningsBreakdown,
        ),
      ),
      SizedBox(
        height: 56,
        child: SaeqPrimaryButton(
          key: homeKey,
          label: l10n.batchSummaryReturnHomeAction,
          icon: Icons.home_outlined,
          onPressed: controller.returnHome,
        ),
      ),
    ];
  }
}
