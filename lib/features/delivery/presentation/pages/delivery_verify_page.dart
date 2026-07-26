import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
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
    final state = ref.watch(deliveryControllerProvider);
    final delivery = ref.read(deliveryControllerProvider.notifier);
    final stage = state.activeAssignment?.workflowStage;
    final processing = state.isProcessing;

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
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingMD),
              TextField(
                key: DeliveryVerifyPage.codeFieldKey,
                controller: _controller,
                keyboardType: TextInputType.number,
                enabled: !processing && stage == DriverWorkflowStage.verifying,
                decoration: InputDecoration(
                  labelText: l10n.deliveryVerifyCodeLabel,
                  hintText: FakeDeliveryVerificationCodes.trialCode,
                ),
              ),
              if (state.failure != null) ...[
                const SizedBox(height: AppTheme.spacingMD),
                Text(
                  deliveryFailureMessage(state.failure!, l10n),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
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
