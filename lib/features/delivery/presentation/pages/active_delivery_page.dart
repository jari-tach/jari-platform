import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_address_block.dart';
import '../../../../shared/widgets/saeq_delivery_action_button.dart';
import '../../../../shared/widgets/saeq_delivery_timeline.dart';
import '../../../../shared/widgets/saeq_empty_state.dart';
import '../../../../shared/widgets/saeq_offline_banner.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../../../shared/widgets/saeq_secondary_button.dart';
import '../../../../shared/widgets/saeq_status_chip.dart';
import '../../../../shared/widgets/saeq_success_button.dart';
import '../../../../core/providers/home_ui_providers.dart';
import '../../domain/entities/delivery_assignment.dart';
import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/driver_workflow_stage.dart';
import '../../domain/policies/driver_workflow_transition_policy.dart';
import '../controllers/delivery_controller.dart';
import '../mappers/delivery_failure_messages.dart';
import '../providers/delivery_providers.dart';
import '../state/delivery_controller_state.dart';
import '../widgets/delivery_offer_loading_state.dart';
import 'delivery_workflow_labels.dart';

/// Active delivery stage machine UI (PHASE 2.6 Increment 2).
class ActiveDeliveryPage extends ConsumerWidget {
  const ActiveDeliveryPage({super.key});

  static const pageKey = Key('activeDeliveryPage');
  static const primaryActionKey = Key('activeDeliveryPrimaryAction');
  static const customerDetailsKey = Key('activeDeliveryCustomerDetails');
  static const customerDetailsHiddenKey = Key(
    'activeDeliveryCustomerDetailsHidden',
  );
  static const pendingSyncKey = Key('activeDeliveryPendingSync');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(deliveryControllerProvider);
    final offline = ref.watch(isOfflineProvider);
    final controller = ref.read(deliveryControllerProvider.notifier);

    return Scaffold(
      key: pageKey,
      appBar: AppBar(title: Text(l10n.activeDeliveryScreenTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: _buildBody(context, ref, l10n, state, controller, offline),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DeliveryControllerState state,
    DeliveryController controller,
    bool offline,
  ) {
    if (state.status == DeliveryViewStatus.initial ||
        state.status == DeliveryViewStatus.loading) {
      return const DeliveryOfferLoadingState();
    }

    final assignment = state.activeAssignment;
    if (assignment == null) {
      return Column(
        children: [
          Expanded(
            child: SaeqEmptyState(
              title: l10n.activeDeliveryScreenTitle,
              message: l10n.shellPlaceholderMessage,
              icon: Icons.local_shipping_outlined,
            ),
          ),
          SaeqPrimaryButton(
            label: l10n.navHome,
            icon: Icons.home_outlined,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      );
    }

    final stage = assignment.workflowStage;
    final processing = state.isProcessing;
    final failure = state.failure;
    final colors = SaeqSemanticColors.of(context);
    final customerDetailsVisible =
        state.isCustomerContactVisible ||
        (assignment.status == DeliveryStatus.pickedUp &&
            !assignment.pendingSync);
    final customerDetailsClosed =
        assignment.status == DeliveryStatus.delivered ||
        assignment.workflowStage == DriverWorkflowStage.summary;
    final contact = state.customerContact;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SaeqOfflineBanner(
                  message: l10n.offlineBannerMessage,
                  visible: offline,
                ),
                SaeqOfflineBanner(
                  key: pendingSyncKey,
                  message: l10n.deliveryPendingSyncMessage,
                  visible: assignment.pendingSync,
                ),
                if (assignment.pendingSync) ...[
                  SaeqSecondaryButton(
                    label: l10n.deliveryRetrySync,
                    onPressed: processing ? null : controller.retryPendingSync,
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                ],
                if (state.isRestored) ...[
                  SaeqStatusChip(
                    label: l10n.deliveryRestoredMessage,
                    tone: SaeqStatusTone.neutral,
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                ],
                SaeqStatusChip(
                  label: deliveryWorkflowStageLabel(l10n, stage),
                  tone: stage == DriverWorkflowStage.issueOpen
                      ? SaeqStatusTone.warning
                      : SaeqStatusTone.success,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                SaeqDeliveryTimeline(
                  labels: deliveryWorkflowTimelineLabels(l10n),
                  activeIndex: deliveryWorkflowTimelineIndex(stage),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                SaeqAddressBlock(
                  title: l10n.deliveryOfferPickupLabel,
                  address: assignment.order.pickupLabel,
                ),
                const SizedBox(height: AppTheme.spacingMD),
                if (customerDetailsVisible)
                  Column(
                    key: customerDetailsKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SaeqAddressBlock(
                        title: l10n.deliveryOfferDropoffLabel,
                        address: assignment.order.dropoffLabel,
                      ),
                      if (contact != null) ...[
                        const SizedBox(height: AppTheme.spacingSM),
                        Text(
                          key: const Key('activeDeliveryCustomerContactName'),
                          contact.name,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          key: const Key('activeDeliveryCustomerContactPhone'),
                          contact.phoneNumber,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  Text(
                    key: customerDetailsHiddenKey,
                    customerDetailsClosed
                        ? l10n.deliveryCustomerDetailsClosed
                        : l10n.deliveryCustomerDetailsLocked,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                if (state.activeBatch?.currentStop != null) ...[
                  const SizedBox(height: AppTheme.spacingMD),
                  SaeqStatusChip(
                    key: const Key('activeDeliveryBatchCurrentStop'),
                    label: state.activeBatch!.currentStop!.label,
                    tone: SaeqStatusTone.neutral,
                  ),
                ],
                const SizedBox(height: AppTheme.spacingLG),
                SaeqContactActionsRow(
                  mapsLabel: l10n.deliveryMapsAction,
                  query: _mapsQuery(assignment, stage),
                  mapsCopiedMessage: l10n.deliveryMapsCopied,
                  helpLabel:
                      stage == DriverWorkflowStage.arrivedPickup ||
                          stage == DriverWorkflowStage.navToCustomer
                      ? l10n.deliveryReportIssueAction
                      : null,
                  onHelp:
                      stage == DriverWorkflowStage.arrivedPickup ||
                          stage == DriverWorkflowStage.navToCustomer
                      ? () => context.push(AppRoutes.deliveryIssue)
                      : null,
                ),
                // Manual arrival is forbidden — automatic geofence only (STEP 5D-1).
                if (failure != null) ...[
                  const SizedBox(height: AppTheme.spacingMD),
                  Text(
                    deliveryFailureMessage(failure, l10n),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ..._bottomActions(
          context,
          ref,
          l10n,
          assignment,
          controller,
          processing,
        ),
      ],
    );
  }

  List<Widget> _bottomActions(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DeliveryAssignment assignment,
    DeliveryController controller,
    bool processing,
  ) {
    final stage = assignment.workflowStage;
    if (stage == DriverWorkflowStage.issueOpen) {
      return [
        SaeqDeliveryActionButton(
          key: primaryActionKey,
          label: l10n.deliveryResumeIssueAction,
          isLoading: processing,
          onPressed: processing
              ? null
              : () => controller.advanceWorkflow(
                  DriverWorkflowCommand.resumeAfterIssue,
                ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
      ];
    }
    if (stage == DriverWorkflowStage.verifying) {
      return [
        SaeqDeliveryActionButton(
          key: primaryActionKey,
          label: l10n.deliveryActionStartVerify,
          onPressed: processing
              ? null
              : () => context.push(AppRoutes.deliveryVerify),
        ),
        const SizedBox(height: AppTheme.spacingSM),
      ];
    }
    if (stage == DriverWorkflowStage.summary) {
      return [
        SaeqSuccessButton(
          key: primaryActionKey,
          label: l10n.deliveryDismissSummary,
          isLoading: processing,
          onPressed: processing
              ? null
              : () async {
                  await controller.completeDeliverySummary();
                  if (!context.mounted) return;
                  final next = ref.read(deliveryControllerProvider);
                  final completedSuccessfully =
                      next.failure == null &&
                      next.activeAssignment == null &&
                      next.status == DeliveryViewStatus.ready;
                  if (completedSuccessfully) {
                    context.go(AppRoutes.home);
                  }
                },
        ),
        const SizedBox(height: AppTheme.spacingSM),
      ];
    }
    if (stage == DriverWorkflowStage.arrivedCustomer) {
      return [
        SaeqDeliveryActionButton(
          key: primaryActionKey,
          label: l10n.deliveryActionStartVerify,
          isLoading: processing,
          onPressed: processing
              ? null
              : () async {
                  await controller.advanceWorkflow(
                    DriverWorkflowCommand.startVerify,
                  );
                  if (context.mounted) {
                    context.push(AppRoutes.deliveryVerify);
                  }
                },
        ),
        const SizedBox(height: AppTheme.spacingSM),
      ];
    }

    final command = deliveryPrimaryCommand(stage);
    if (command == null) {
      return [
        SaeqSecondaryButton(
          label: l10n.navHome,
          onPressed: () => context.go(AppRoutes.home),
        ),
        const SizedBox(height: AppTheme.spacingSM),
      ];
    }

    return [
      SaeqDeliveryActionButton(
        key: primaryActionKey,
        label: deliveryPrimaryActionLabel(l10n, command),
        isLoading: processing,
        onPressed: processing
            ? null
            : () => controller.advanceWorkflow(command),
      ),
      const SizedBox(height: AppTheme.spacingSM),
    ];
  }

  String _mapsQuery(DeliveryAssignment assignment, DriverWorkflowStage stage) {
    final toCustomer =
        stage == DriverWorkflowStage.collected ||
        stage == DriverWorkflowStage.navToCustomer ||
        stage == DriverWorkflowStage.arrivedCustomer ||
        stage == DriverWorkflowStage.verifying ||
        stage == DriverWorkflowStage.delivered ||
        stage == DriverWorkflowStage.summary;
    return toCustomer
        ? assignment.order.dropoffLabel
        : assignment.order.pickupLabel;
  }
}
