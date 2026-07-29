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

/// Figma 138:2714 — Final/Batch/Pickup Confirmed Manual.
///
/// Distinct from verification: verification only unlocks this surface. The
/// route overview opens only after the manual confirmation succeeds.
class BatchManualPickupScreen extends ConsumerWidget {
  const BatchManualPickupScreen({super.key, required this.batchId});

  final String batchId;

  static const pageKey = Key('batchManualPickupScreen');
  static const confirmKey = Key('batchManualPickupConfirm');
  static const reviewKey = Key('batchManualPickupReview');
  static const figmaNodeKey = Key('figma_138_2714');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(batchControllerProvider);
    final controller = ref.read(batchControllerProvider.notifier);
    final batch = state.batch;

    ref.listen(batchControllerProvider, (previous, next) {
      if (next.pickupStatus == BatchPickupStatus.pickupConfirmed &&
          next.batch?.batchId == batchId) {
        context.go(AppRoutes.batchRoutePath(batchId));
      }
    });

    return Scaffold(
      key: pageKey,
      body: BatchPage(
        title: l10n.batchManualPickupTitle,
        confirmBack: state.tripStarted,
        onConfirmBack: () => confirmBatchLeave(context),
        onBack: () => context.go(AppRoutes.batchVerifyPath(batchId)),
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
    final colors = SaeqSemanticColors.of(context);
    final processing =
        state.isProcessing ||
        state.pickupStatus == BatchPickupStatus.processing;
    final canConfirm = state.canConfirmPickupManually;

    return [
      const SizedBox(key: figmaNodeKey, height: 0),
      BatchJourneyTimeline(
        activeStage: BatchJourneyStage.pickupAwaitingManualConfirmation,
      ),
      P27Banner(
        title: l10n.batchManualPickupBannerTitle,
        message: l10n.batchManualPickupBannerMessage,
        tone: P27BannerTone.success,
      ),
      for (final order in batch.orders)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _confirmedRow(context, l10n, colors, order),
        ),
      if (!canConfirm && !processing)
        Text(
          l10n.batchManualPickupGateHint,
          style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
        ),
      SizedBox(
        height: 56,
        child: SaeqPrimaryButton(
          key: confirmKey,
          label: processing
              ? l10n.batchManualPickupProcessingLabel
              : l10n.batchManualPickupAction,
          icon: Icons.check_circle_outline,
          onPressed: canConfirm ? controller.confirmPickupManually : null,
          isLoading: processing,
        ),
      ),
      SizedBox(
        height: 48,
        child: SaeqSecondaryButton(
          key: reviewKey,
          label: l10n.batchBackToVerifyAction,
          onPressed: processing
              ? null
              : () => context.go(AppRoutes.batchVerifyPath(batchId)),
        ),
      ),
    ];
  }

  Widget _confirmedRow(
    BuildContext context,
    AppLocalizations l10n,
    SaeqSemanticColors colors,
    BatchOrderViewData order,
  ) {
    return Container(
      key: ValueKey('batchManualPickupRow_${order.orderId}'),
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
              '${order.sequence}',
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
                  l10n.batchOrderLabel(order.maskedOrderId),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.batchOrderVerifiedSubtitle,
                  style: AppTextStyles.supporting.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.successContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              l10n.batchOrderConfirmedBadge,
              style: AppTextStyles.supporting.copyWith(
                color: colors.success,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
