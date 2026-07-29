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

/// P27 pickup states (115:581 / 115:637 / 115:693).
class BatchPickupScreen extends ConsumerWidget {
  const BatchPickupScreen({super.key, required this.batchId});

  final String batchId;

  static const pageKey = Key('batchPickupScreen');
  static const refreshKey = Key('batchPickupRefresh');
  static const verifyKey = Key('batchPickupVerify');
  static const confirmKey = Key('batchPickupConfirm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(batchControllerProvider);
    final controller = ref.read(batchControllerProvider.notifier);
    final batch = state.batch;

    ref.listen(batchControllerProvider, (previous, next) {
      if (next.pickupStatus == BatchPickupStatus.verification &&
          next.batch?.batchId == batchId) {
        context.go(AppRoutes.batchVerifyPath(batchId));
      }
      if (next.pickupStatus == BatchPickupStatus.pickupConfirmed &&
          next.batch?.batchId == batchId) {
        context.go(AppRoutes.batchRoutePath(batchId));
      }
    });

    return Scaffold(
      key: pageKey,
      body: BatchPage(
        title: l10n.batchPickupTitle,
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
    final pickup = BatchPickupViewData(batch: batch);
    final (title, message, tone) = switch (state.pickupStatus) {
      BatchPickupStatus.waiting => (
        l10n.batchPickupWaitingTitle,
        l10n.batchPickupWaitingMessage,
        P27BannerTone.information,
      ),
      BatchPickupStatus.partiallyReady => (
        l10n.batchPickupPartialTitle,
        l10n.batchPickupPartialMessage,
        P27BannerTone.warning,
      ),
      BatchPickupStatus.allReady => (
        l10n.batchPickupAllReadyTitle,
        l10n.batchPickupAllReadyMessage,
        P27BannerTone.success,
      ),
      BatchPickupStatus.processing => (
        l10n.batchVerifyProcessingLabel,
        l10n.batchPickupConfirmedMessage,
        P27BannerTone.information,
      ),
      BatchPickupStatus.pickupConfirmed => (
        l10n.batchPickupConfirmedTitle,
        l10n.batchPickupConfirmedMessage,
        P27BannerTone.success,
      ),
      _ => (
        l10n.batchPickupWaitingTitle,
        l10n.batchPickupWaitingMessage,
        P27BannerTone.information,
      ),
    };

    return [
      P27Banner(title: title, message: message, tone: tone),
      BatchProgressBar(
        resolved: pickup.readyCount,
        total: pickup.orderCount,
        label: l10n.batchPickupReadyCount(pickup.readyCount, pickup.orderCount),
      ),
      P27Field(label: l10n.batchStoreLabel, value: l10n.batchStoreName),
      P27Field(label: l10n.batchPickupLabel, value: l10n.batchPickupPointName),
      for (final order in batch.orders)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BatchOrderRow(order: order, l10n: l10n),
        ),
      if (state.pickupStatus == BatchPickupStatus.waiting ||
          state.pickupStatus == BatchPickupStatus.partiallyReady)
        _btn(
          key: refreshKey,
          primary: true,
          label: l10n.batchPickupRefreshAction,
          icon: Icons.refresh,
          loading: state.isProcessing,
          onPressed: state.isProcessing ? null : controller.refreshPickupStatus,
        ),
      if (state.pickupStatus == BatchPickupStatus.allReady)
        _btn(
          key: verifyKey,
          primary: true,
          label: l10n.batchPickupVerifyAction,
          icon: Icons.qr_code_scanner_outlined,
          onPressed: controller.beginVerification,
        ),
      if (state.pickupStatus == BatchPickupStatus.pickupConfirmed)
        _btn(
          primary: true,
          label: l10n.batchStartRouteAction,
          icon: Icons.navigation_outlined,
          onPressed: () => context.go(AppRoutes.batchRoutePath(batchId)),
        ),
    ];
  }

  Widget _btn({
    Key? key,
    required bool primary,
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      height: primary ? 56 : 48,
      child: primary
          ? SaeqPrimaryButton(
              key: key,
              label: label,
              icon: icon,
              onPressed: onPressed,
              isLoading: loading,
            )
          : SaeqSecondaryButton(
              key: key,
              label: label,
              icon: icon,
              onPressed: onPressed,
              isLoading: loading,
            ),
    );
  }
}
