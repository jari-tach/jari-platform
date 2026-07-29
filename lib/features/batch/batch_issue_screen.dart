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

/// P27 issue screen — current order only (115:1002 / 115:1034).
class BatchIssueScreen extends ConsumerWidget {
  const BatchIssueScreen({
    super.key,
    required this.batchId,
    required this.orderId,
  });

  final String batchId;
  final String orderId;

  static const pageKey = Key('batchIssueScreen');
  static const confirmKey = Key('batchIssueConfirm');
  static const backKey = Key('batchIssueBack');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(batchControllerProvider);
    final controller = ref.read(batchControllerProvider.notifier);
    final order = state.batch?.orderById(orderId);

    ref.listen(batchControllerProvider, (previous, next) {
      if (previous?.isProcessing == true &&
          !next.isProcessing &&
          next.issueOrderId == null &&
          (next.routeStatus == BatchRouteStatus.orderCancelledContinue ||
              next.routeStatus == BatchRouteStatus.customerUnavailable)) {
        context.go(AppRoutes.batchStopPath(batchId, state.currentSequence));
      }
    });

    return Scaffold(
      key: pageKey,
      body: BatchPage(
        title: l10n.batchIssueTitle,
        confirmBack: state.tripStarted,
        onConfirmBack: () => confirmBatchLeave(context),
        onBack: () {
          controller.cancelIssue();
          context.go(AppRoutes.batchStopPath(batchId, state.currentSequence));
        },
        children: order == null
            ? [const P27Skeleton(height: 360)]
            : _content(context, l10n, state, controller, order),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    AppLocalizations l10n,
    BatchState state,
    BatchController controller,
    BatchOrderViewData order,
  ) {
    final colors = SaeqSemanticColors.of(context);
    final customer = l10n.batchCustomerFirstName(order.labelIndex);
    final district = l10n.batchDistrictName(order.labelIndex);

    return [
      P27Banner(
        title: l10n.batchIssueTitle,
        message: l10n.batchIssueMessage,
        tone: P27BannerTone.warning,
      ),
      P27Field(label: l10n.batchStopCustomerLabel, value: customer),
      P27Field(label: l10n.batchStopAreaLabel, value: district),
      P27Field(
        label: l10n.batchOrderLabel(order.maskedOrderId),
        value: batchOrderStateLabel(l10n, order.state),
      ),
      Text(
        l10n.batchIssueSelectReasonHint,
        style: AppTextStyles.bodyMedium.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      _ReasonTile(
        key: const Key('batchIssueReasonUnavailable'),
        label: l10n.batchIssueReasonCustomerUnavailable,
        selected:
            state.selectedIssueReason ==
            BatchOrderIssueReason.customerUnavailable,
        onTap: () => controller.selectIssueReason(
          BatchOrderIssueReason.customerUnavailable,
        ),
      ),
      _ReasonTile(
        key: const Key('batchIssueReasonCancelled'),
        label: l10n.batchIssueReasonMerchantCancelled,
        selected:
            state.selectedIssueReason ==
            BatchOrderIssueReason.merchantCancelled,
        onTap: () => controller.selectIssueReason(
          BatchOrderIssueReason.merchantCancelled,
        ),
      ),
      _ReasonTile(
        key: const Key('batchIssueReasonAddress'),
        label: l10n.batchIssueReasonAddressUnreachable,
        selected:
            state.selectedIssueReason ==
            BatchOrderIssueReason.addressUnreachable,
        onTap: () => controller.selectIssueReason(
          BatchOrderIssueReason.addressUnreachable,
        ),
      ),
      SizedBox(
        height: 56,
        child: SaeqPrimaryButton(
          key: confirmKey,
          label: state.isProcessing
              ? l10n.batchProcessingLabel
              : l10n.batchIssueConfirmAction,
          onPressed:
              state.selectedIssueReason != BatchOrderIssueReason.none &&
                  !state.isProcessing
              ? controller.submitIssue
              : null,
          isLoading: state.isProcessing,
        ),
      ),
      SizedBox(
        height: 48,
        child: SaeqSecondaryButton(
          key: backKey,
          label: l10n.batchIssueBackAction,
          onPressed: state.isProcessing
              ? null
              : () {
                  controller.cancelIssue();
                  context.go(
                    AppRoutes.batchStopPath(batchId, state.currentSequence),
                  );
                },
        ),
      ),
    ];
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: AppTheme.minTouchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? colors.primary : colors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? colors.primary : colors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
