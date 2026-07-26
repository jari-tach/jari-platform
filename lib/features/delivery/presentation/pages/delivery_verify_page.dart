import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../../../shared/widgets/saeq_secondary_button.dart';
import '../../domain/entities/driver_workflow_stage.dart';
import '../../domain/usecases/verify_delivery_code.dart';
import '../mappers/delivery_failure_messages.dart';
import '../providers/delivery_providers.dart';

/// Delivery code verification (Fake trial code) — PHASE 2.6.
class DeliveryVerifyPage extends ConsumerStatefulWidget {
  const DeliveryVerifyPage({super.key});

  static const pageKey = Key('deliveryVerifyPage');
  static const codeFieldKey = Key('deliveryVerifyCodeField');
  static const submitKey = Key('deliveryVerifySubmit');

  @override
  ConsumerState<DeliveryVerifyPage> createState() => _DeliveryVerifyPageState();
}

class _DeliveryVerifyPageState extends ConsumerState<DeliveryVerifyPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final state = ref.watch(deliveryControllerProvider);
    final delivery = ref.read(deliveryControllerProvider.notifier);
    final stage = state.activeAssignment?.workflowStage;
    final processing = state.isProcessing;
    final hasError = state.failure != null;
    final fieldEnabled = !processing && stage == DriverWorkflowStage.verifying;

    return Scaffold(
      key: DeliveryVerifyPage.pageKey,
      appBar: AppBar(title: Text(l10n.deliveryVerifyScreenTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.deliveryVerifyHintMessage,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              TextField(
                key: DeliveryVerifyPage.codeFieldKey,
                controller: _controller,
                keyboardType: TextInputType.number,
                enabled: fieldEnabled,
                decoration: InputDecoration(
                  labelText: l10n.deliveryVerifyCodeLabel,
                  hintText: FakeDeliveryVerificationCodes.trialCode,
                  labelStyle: TextStyle(color: colors.textSecondary),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(
                      color: colors.primary,
                      width: AppTheme.borderWidthMedium,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(color: colors.error),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    borderSide: BorderSide(
                      color: colors.error,
                      width: AppTheme.borderWidthMedium,
                    ),
                  ),
                  errorText: hasError
                      ? deliveryFailureMessage(state.failure!, l10n)
                      : null,
                  errorStyle: AppTextStyles.bodyMedium.copyWith(
                    color: colors.error,
                  ),
                  filled: true,
                  fillColor: fieldEnabled
                      ? colors.surface
                      : colors.elevatedSurface,
                ),
              ),
              const Spacer(),
              SaeqPrimaryButton(
                key: DeliveryVerifyPage.submitKey,
                label: l10n.deliveryVerifySubmit,
                isLoading: processing,
                onPressed: processing || stage != DriverWorkflowStage.verifying
                    ? null
                    : () async {
                        await delivery.verifyDeliveryCode(_controller.text);
                        final next = ref.read(deliveryControllerProvider);
                        if (next.failure == null &&
                            next.activeAssignment?.workflowStage ==
                                DriverWorkflowStage.summary &&
                            context.mounted) {
                          context.go(AppRoutes.deliveryActive);
                        }
                      },
              ),
              const SizedBox(height: AppTheme.spacingSM),
              SaeqSecondaryButton(
                label: l10n.cancelAction,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
