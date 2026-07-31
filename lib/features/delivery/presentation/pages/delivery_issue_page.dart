import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_bottom_sheet_scaffold.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../../../shared/widgets/saeq_secondary_button.dart';
import '../../domain/entities/driver_workflow_stage.dart';
import '../mappers/delivery_failure_messages.dart';
import '../providers/delivery_providers.dart';

/// Issue category + report (Fake) — PHASE 2.6.
class DeliveryIssuePage extends ConsumerStatefulWidget {
  const DeliveryIssuePage({super.key});

  static const pageKey = Key('deliveryIssuePage');

  @override
  ConsumerState<DeliveryIssuePage> createState() => _DeliveryIssuePageState();
}

class _DeliveryIssuePageState extends ConsumerState<DeliveryIssuePage> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final state = ref.watch(deliveryControllerProvider);
    final delivery = ref.read(deliveryControllerProvider.notifier);
    final processing = state.isProcessing;

    final categories = <String>[
      l10n.deliveryIssueCategoryDelay,
      l10n.deliveryIssueCategoryMerchant,
      l10n.deliveryIssueCategoryCustomer,
      l10n.deliveryIssueCategoryOther,
    ];

    return Scaffold(
      key: DeliveryIssuePage.pageKey,
      appBar: AppBar(title: Text(l10n.deliveryIssueScreenTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.deliveryReportIssueAction,
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              for (final category in categories)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingXS),
                  child: Material(
                    color: _category == category
                        ? colors.primaryContainer
                        : colors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      side: BorderSide(
                        color: _category == category
                            ? colors.primary
                            : colors.border,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        category,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: _category == category
                              ? colors.primary
                              : colors.textPrimary,
                          fontWeight: _category == category
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      leading: Icon(
                        _category == category
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _category == category
                            ? colors.primary
                            : colors.textSecondary,
                      ),
                      onTap: processing
                          ? null
                          : () => setState(() => _category = category),
                    ),
                  ),
                ),
              if (state.failure != null) ...[
                const SizedBox(height: AppTheme.spacingMD),
                Text(
                  deliveryFailureMessage(state.failure!, l10n),
                  style: AppTextStyles.bodyMedium.copyWith(color: colors.error),
                ),
              ],
              const Spacer(),
              SaeqPrimaryButton(
                label: l10n.deliveryIssueSubmit,
                isLoading: processing,
                onPressed: processing || _category == null
                    ? null
                    : () async {
                        await delivery.reportIssueRemote(code: _category!);
                        if (!context.mounted) return;
                        final next = ref.read(deliveryControllerProvider);
                        final reported =
                            next.failure == null &&
                            next.activeAssignment?.workflowStage ==
                                DriverWorkflowStage.issueOpen;
                        if (reported) {
                          context.go(AppRoutes.deliveryActive);
                        }
                      },
              ),
              const SizedBox(height: AppTheme.spacingSM),
              SaeqSecondaryButton(
                label: l10n.cancelAction,
                onPressed: processing
                    ? null
                    : () async {
                        await delivery.cancelActiveDelivery();
                        if (context.mounted) {
                          final next = ref.read(deliveryControllerProvider);
                          if (next.activeAssignment == null) {
                            context.go(AppRoutes.home);
                          } else {
                            context.pop();
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Optional sheet helper for category pick (reuse scaffold).
Future<String?> showDeliveryIssueCategorySheet(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return SaeqBottomSheetScaffold.show<String>(
    context: context,
    title: l10n.deliveryIssueScreenTitle,
    child: Column(
      children: [
        for (final label in [
          l10n.deliveryIssueCategoryDelay,
          l10n.deliveryIssueCategoryMerchant,
          l10n.deliveryIssueCategoryCustomer,
          l10n.deliveryIssueCategoryOther,
        ])
          ListTile(
            title: Text(label),
            onTap: () => Navigator.of(context).pop(label),
          ),
      ],
    ),
  );
}
