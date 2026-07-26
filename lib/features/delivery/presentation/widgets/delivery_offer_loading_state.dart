import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

/// Centered loading body for delivery offer UI.
class DeliveryOfferLoadingState extends StatelessWidget {
  const DeliveryOfferLoadingState({super.key});

  static const progressKey = Key('deliveryOfferLoading');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      key: progressKey,
      child: Semantics(
        label: l10n.deliverySemanticsProgress,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppTheme.spacingMD),
            Text(l10n.deliveryLoadingTitle, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              l10n.deliveryLoadingMessage,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
