import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';
import '../../features/location/location_ui_helpers.dart';
import '../../shared/widgets/saeq_confirm_dialog.dart';
import '../../shared/widgets/saeq_primary_button.dart';
import '../../shared/widgets/saeq_secondary_button.dart';
import 'batch_feature.dart';
import 'batch_ui_helpers.dart';

/// P27 batch offer states (115:412 / 115:461 / 115:518 / 115:534).
class BatchOfferScreen extends ConsumerStatefulWidget {
  const BatchOfferScreen({super.key, required this.batchId});

  final String batchId;

  static const pageKey = Key('batchOfferScreen');
  static const acceptKey = Key('batchOfferAccept');
  static const rejectKey = Key('batchOfferReject');
  static const retryKey = Key('batchOfferRetry');
  static const backKey = Key('batchOfferBack');

  @override
  ConsumerState<BatchOfferScreen> createState() => _BatchOfferScreenState();
}

class _BatchOfferScreenState extends ConsumerState<BatchOfferScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(batchControllerProvider);
      if (current.hasBatch ||
          current.offerStatus != BatchOfferViewStatus.loading) {
        return;
      }
      ref.read(batchControllerProvider.notifier).loadOffer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(batchControllerProvider);
    final controller = ref.read(batchControllerProvider.notifier);

    ref.listen(batchControllerProvider, (previous, next) {
      if (next.offerStatus == BatchOfferViewStatus.accepted &&
          next.batch != null) {
        context.go(AppRoutes.batchPickupPath(next.batch!.batchId));
      }
      if (next.offerStatus == BatchOfferViewStatus.rejected) {
        context.go(AppRoutes.deliveryOffer);
      }
    });

    return Scaffold(
      key: BatchOfferScreen.pageKey,
      body: BatchPage(
        title: l10n.batchOfferTitle,
        onBack: () => _leave(context),
        children: _content(context, l10n, state, controller),
      ),
    );
  }

  Future<void> _leave(BuildContext context) async {
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
  ) {
    if (state.serviceUnavailable) {
      return [
        P27Banner(
          title: l10n.batchUnavailableTitle,
          message: l10n.batchUnavailableMessage,
          tone: P27BannerTone.error,
        ),
        const P27Skeleton(height: 360),
      ];
    }

    return switch (state.offerStatus) {
      BatchOfferViewStatus.loading => [
        P27Banner(
          title: l10n.batchOfferLoadingTitle,
          message: l10n.batchOfferLoadingMessage,
          tone: P27BannerTone.information,
        ),
        const P27Skeleton(height: 220),
        const P27Skeleton(height: 180),
      ],
      BatchOfferViewStatus.error => [
        P27Banner(
          title: l10n.batchOfferErrorTitle,
          message: l10n.batchOfferErrorMessage,
          tone: P27BannerTone.error,
        ),
        _primary(
          key: BatchOfferScreen.retryKey,
          label: l10n.batchRetryAction,
          icon: Icons.refresh,
          onPressed: state.isProcessing ? null : () => controller.loadOffer(),
        ),
      ],
      BatchOfferViewStatus.offline => [
        P27Banner(
          title: l10n.batchOfferOfflineTitle,
          message: l10n.batchOfferOfflineMessage,
          tone: P27BannerTone.warning,
        ),
        _primary(
          key: BatchOfferScreen.retryKey,
          label: l10n.batchRetryAction,
          onPressed: state.isProcessing ? null : () => controller.loadOffer(),
        ),
      ],
      BatchOfferViewStatus.expired => [
        P27Banner(
          title: l10n.batchOfferExpiredTitle,
          message: l10n.batchOfferExpiredMessage,
          tone: P27BannerTone.warning,
        ),
        _secondary(
          key: BatchOfferScreen.backKey,
          label: l10n.batchBackToOffersAction,
          onPressed: () => context.go(AppRoutes.deliveryOffer),
        ),
      ],
      BatchOfferViewStatus.threeOrders ||
      BatchOfferViewStatus.fourOrders ||
      BatchOfferViewStatus.acceptProcessing ||
      BatchOfferViewStatus.rejectProcessing => _offerBody(
        context,
        l10n,
        state,
        controller,
      ),
      _ => [
        _secondary(
          label: l10n.batchBackToOffersAction,
          onPressed: () => context.go(AppRoutes.deliveryOffer),
        ),
      ],
    };
  }

  List<Widget> _offerBody(
    BuildContext context,
    AppLocalizations l10n,
    BatchState state,
    BatchController controller,
  ) {
    final batch = state.batch;
    if (batch == null) {
      return [const P27Skeleton(height: 360)];
    }
    final colors = SaeqSemanticColors.of(context);
    final accepting =
        state.offerStatus == BatchOfferViewStatus.acceptProcessing;
    final rejecting =
        state.offerStatus == BatchOfferViewStatus.rejectProcessing;
    final deciding = state.canDecideOffer;

    return [
      BatchMultiStopMap(stopCount: batch.orderCount, activeSequence: 1),
      const SizedBox(height: 4),
      P27Field(label: l10n.batchStoreLabel, value: l10n.batchStoreName),
      P27Field(label: l10n.batchPickupLabel, value: l10n.batchPickupPointName),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 150,
            child: BatchMetricChip(
              label: l10n.batchOrdersLabel,
              value: l10n.batchOrdersValue(batch.orderCount),
              icon: Icons.layers_outlined,
            ),
          ),
          SizedBox(
            width: 150,
            child: BatchMetricChip(
              label: l10n.batchDistanceLabel,
              value: l10n.batchDistanceValue(
                formatBatchDistance(batch.totalDistanceKm),
              ),
              icon: Icons.route_outlined,
            ),
          ),
          SizedBox(
            width: 150,
            child: BatchMetricChip(
              label: l10n.batchEtaLabel,
              value: l10n.batchEtaValue(batch.etaMinutes),
              icon: Icons.schedule_outlined,
            ),
          ),
          SizedBox(
            width: 150,
            child: BatchMetricChip(
              label: l10n.batchEarningsLabel,
              value: l10n.batchEarningsValue(
                formatBatchEarnings(batch.totalEarningsSar),
              ),
              icon: Icons.payments_outlined,
            ),
          ),
          SizedBox(
            width: 150,
            child: BatchMetricChip(
              label: l10n.batchCountdownLabel,
              value: batch.remainingSeconds <= 0
                  ? l10n.batchCountdownExpired
                  : l10n.batchCountdownValue(batch.remainingSeconds),
              icon: Icons.timer_outlined,
            ),
          ),
        ],
      ),
      Text(
        l10n.batchWholeBatchNote,
        style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
      ),
      Semantics(
        label: l10n.batchSemanticsOrders,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final order in batch.orders)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BatchOrderRow(order: order, l10n: l10n),
              ),
          ],
        ),
      ),
      _primary(
        key: BatchOfferScreen.acceptKey,
        label: accepting ? l10n.batchAcceptingLabel : l10n.batchAcceptAction,
        icon: Icons.check_circle_outline,
        loading: accepting,
        onPressed: deciding ? controller.acceptBatch : null,
      ),
      _secondary(
        key: BatchOfferScreen.rejectKey,
        label: rejecting ? l10n.batchRejectingLabel : l10n.batchRejectAction,
        loading: rejecting,
        onPressed: deciding ? controller.rejectBatch : null,
      ),
    ];
  }

  Widget _primary({
    Key? key,
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      height: 56,
      child: SaeqPrimaryButton(
        key: key,
        label: label,
        icon: icon,
        onPressed: onPressed,
        isLoading: loading,
      ),
    );
  }

  Widget _secondary({
    Key? key,
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      height: 48,
      child: SaeqSecondaryButton(
        key: key,
        label: label,
        icon: icon,
        onPressed: onPressed,
        isLoading: loading,
      ),
    );
  }
}

Future<bool> confirmBatchLeave(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final result = await SaeqConfirmDialog.show(
    context,
    title: l10n.batchLeaveTitle,
    message: l10n.batchLeaveMessage,
    confirmLabel: l10n.batchLeaveConfirm,
    cancelLabel: l10n.batchLeaveCancel,
  );
  return result == true;
}
