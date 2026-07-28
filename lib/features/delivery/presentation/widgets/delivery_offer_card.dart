import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../../../shared/widgets/saeq_secondary_button.dart';
import '../../domain/entities/delivery_offer.dart';
import '../controllers/delivery_controller.dart';
import '../state/delivery_controller_state.dart';
import 'delivery_offer_countdown.dart';
import 'delivery_offer_formatters.dart';

/// Full offer summary with Accept / Reject actions (ADR-026).
///
/// Passive view — delegates actions to [DeliveryController] only.
class DeliveryOfferCard extends StatelessWidget {
  const DeliveryOfferCard({
    super.key,
    required this.offer,
    required this.state,
    required this.controller,
    this.now,
  });

  final DeliveryOffer offer;
  final DeliveryControllerState state;
  final DeliveryController controller;
  final DateTime Function()? now;

  static const acceptKey = Key('deliveryOfferAccept');
  static const rejectKey = Key('deliveryOfferReject');
  static const progressKey = Key('deliveryOfferCardProgress');
  static const cardKey = Key('deliveryOfferCard');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final order = offer.order;
    final accepting =
        state.processingAction == DeliveryProcessingAction.accepting;
    final rejecting =
        state.processingAction == DeliveryProcessingAction.rejecting;
    final showProgress = state.isProcessing;
    final expired = offer.isExpiredAt(now?.call() ?? DateTime.now());
    final canAccept = state.canAccept && !expired;
    final canReject = state.canReject && !expired;

    return Semantics(
      container: true,
      label: l10n.deliverySemanticsOffer,
      child: Container(
        key: cardKey,
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showProgress) ...[
              Semantics(
                label: l10n.deliverySemanticsProgress,
                child: const LinearProgressIndicator(
                  key: progressKey,
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
            ],
            Text(
              DeliveryOfferFormatters.storeName(order, l10n),
              style: AppTextStyles.headlineLarge.copyWith(
                color: colors.textPrimary,
              ),
              softWrap: true,
            ),
            const SizedBox(height: AppTheme.spacingMD),
            _LabeledValue(
              label: l10n.deliveryOfferPickupLabel,
              value: order.pickupLabel,
            ),
            _LabeledValue(
              label: l10n.deliveryOfferDropoffLabel,
              value: order.dropoffLabel,
            ),
            _LabeledValue(
              label: l10n.deliveryOfferDistanceLabel,
              value: DeliveryOfferFormatters.distance(order, l10n),
            ),
            _LabeledValue(
              label: l10n.deliveryOfferEarningsLabel,
              value: DeliveryOfferFormatters.earnings(l10n),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            DeliveryOfferCountdown(expiresAt: offer.expiresAt, now: now),
            const SizedBox(height: AppTheme.spacingLG),
            Semantics(
              button: true,
              enabled: canAccept,
              label: l10n.deliverySemanticsAccept,
              child: SaeqPrimaryButton(
                key: acceptKey,
                label: accepting ? l10n.deliveryAccepting : l10n.deliveryAccept,
                icon: Icons.check_circle_outline,
                isLoading: accepting,
                onPressed: canAccept
                    ? () => controller.acceptCurrentOffer()
                    : null,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Semantics(
              button: true,
              enabled: canReject,
              label: l10n.deliverySemanticsReject,
              child: SaeqSecondaryButton(
                key: rejectKey,
                label: rejecting ? l10n.deliveryRejecting : l10n.deliveryReject,
                icon: Icons.close,
                isLoading: rejecting,
                onPressed: canReject
                    ? () => controller.rejectCurrentOffer()
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
              softWrap: true,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colors.textPrimary,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
