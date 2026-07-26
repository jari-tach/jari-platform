import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../domain/entities/delivery_assignment.dart';
import 'delivery_offer_formatters.dart';

/// Accepted-assignment summary with continue CTA (no map yet).
class DeliveryAssignmentSummary extends StatelessWidget {
  const DeliveryAssignmentSummary({
    super.key,
    required this.assignment,
    required this.onContinue,
  });

  final DeliveryAssignment assignment;
  final VoidCallback onContinue;

  static const summaryKey = Key('deliveryAssignmentSummary');
  static const continueKey = Key('deliveryContinueDelivery');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final order = assignment.order;

    return Semantics(
      container: true,
      label: l10n.deliverySemanticsAssignment,
      child: Container(
        key: summaryKey,
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deliveryAcceptedTitle,
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(l10n.deliveryAcceptedMessage, style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppTheme.spacingMD),
            _Row(
              label: l10n.deliveryOfferStoreLabel,
              value: DeliveryOfferFormatters.storeName(order, l10n),
            ),
            _Row(
              label: l10n.deliveryOfferPickupLabel,
              value: order.pickupLabel,
            ),
            _Row(
              label: l10n.deliveryOfferDropoffLabel,
              value: order.dropoffLabel,
            ),
            _Row(
              label: l10n.deliveryAssignmentIdLabel,
              value: assignment.assignmentId,
            ),
            _Row(label: l10n.deliveryOrderIdLabel, value: order.orderId),
            const SizedBox(height: AppTheme.spacingLG),
            SaeqPrimaryButton(
              key: continueKey,
              label: l10n.deliveryContinueDelivery,
              icon: Icons.local_shipping_outlined,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Expanded(flex: 3, child: Text(value, style: AppTextStyles.bodyLarge)),
        ],
      ),
    );
  }
}
