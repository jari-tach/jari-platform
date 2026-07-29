import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routes/app_router.dart';
import '../../features/location/location_ui_helpers.dart';
import '../../shared/widgets/saeq_primary_button.dart';
import '../../shared/widgets/saeq_secondary_button.dart';
import 'batch_feature.dart';
import 'batch_offer_screen.dart';
import 'batch_ui_helpers.dart';
import 'batch_view_data.dart';

/// P27 pickup verification (115:693).
///
/// Verification never completes pickup and never opens the route. When every
/// required order is verified, the driver is sent to the distinct manual
/// pickup confirmation surface (Figma 138:2714).
class BatchVerifyScreen extends ConsumerWidget {
  const BatchVerifyScreen({super.key, required this.batchId});

  final String batchId;

  static const pageKey = Key('batchVerifyScreen');
  static const continueKey = Key('batchVerifyContinueToPickup');
  static const dismissErrorKey = Key('batchVerifyDismissError');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(batchControllerProvider);
    final controller = ref.read(batchControllerProvider.notifier);
    final batch = state.batch;

    ref.listen(batchControllerProvider, (previous, next) {
      if (next.pickupStatus == BatchPickupStatus.awaitingManualConfirmation &&
          next.batch?.batchId == batchId) {
        context.go(AppRoutes.batchManualPickupPath(batchId));
      }
    });

    return Scaffold(
      key: pageKey,
      body: BatchPage(
        title: l10n.batchVerifyTitle,
        confirmBack: state.tripStarted,
        onConfirmBack: () => confirmBatchLeave(context),
        onBack: () => context.go(AppRoutes.batchPickupPath(batchId)),
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
    final pickup = BatchPickupViewData(batch: batch);
    final next = pickup.nextUnverified;
    final canContinue = batch.canConfirmPickupManually && !state.isProcessing;

    return [
      if (state.pickupStatus == BatchPickupStatus.verificationError)
        P27Banner(
          title: l10n.batchVerifyErrorTitle,
          message: l10n.batchVerifyErrorMessage,
          tone: P27BannerTone.error,
        ),
      P27Banner(
        title: l10n.batchVerifyTitle,
        message: l10n.batchVerifyMessage,
        tone: P27BannerTone.information,
      ),
      BatchProgressBar(
        resolved: pickup.verifiedCount,
        total: pickup.orderCount,
        label: l10n.batchVerifiedCount(pickup.verifiedCount, pickup.orderCount),
      ),
      for (final order in batch.orders) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BatchOrderRow(
            order: order,
            l10n: l10n,
            highlight: next?.orderId == order.orderId,
          ),
        ),
        if (!order.isVerified) ...[
          SizedBox(
            height: 48,
            child: SaeqPrimaryButton(
              key: Key('batchVerify_${order.orderId}'),
              label: l10n.batchVerifyOrderAction,
              onPressed: state.isProcessing
                  ? null
                  : () => controller.verifyOrder(order.orderId),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: SaeqSecondaryButton(
              key: Key('batchMismatch_${order.orderId}'),
              label: l10n.batchVerifyMismatchAction,
              onPressed: state.isProcessing
                  ? null
                  : () => controller.reportVerificationMismatch(order.orderId),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
      if (state.pickupStatus == BatchPickupStatus.verificationError)
        SizedBox(
          height: 48,
          child: SaeqSecondaryButton(
            key: dismissErrorKey,
            label: l10n.batchRetryAction,
            onPressed: controller.dismissVerificationError,
          ),
        ),
      SizedBox(
        height: 56,
        child: SaeqPrimaryButton(
          key: continueKey,
          label: l10n.batchVerifyContinueAction,
          icon: Icons.arrow_forward,
          onPressed: canContinue
              ? controller.openManualPickupConfirmation
              : null,
        ),
      ),
    ];
  }
}
