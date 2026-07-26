import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';

/// Error body with retry — mirrors Profile `_MessageState` pattern.
class DeliveryOfferErrorState extends StatelessWidget {
  const DeliveryOfferErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  static const errorKey = Key('deliveryOfferError');
  static const retryKey = Key('deliveryOfferErrorRetry');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      key: errorKey,
      child: Semantics(
        liveRegion: true,
        label: l10n.deliverySemanticsFailure,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: AppTheme.spacingMD),
            Text(l10n.deliveryErrorTitle, style: AppTextStyles.headlineLarge),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLG),
            SaeqPrimaryButton(
              key: retryKey,
              label: l10n.deliveryRetry,
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
