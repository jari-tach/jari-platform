import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

/// Empty offers body with optional refresh action.
class DeliveryOfferEmptyState extends StatelessWidget {
  const DeliveryOfferEmptyState({super.key, this.onRefresh});

  final VoidCallback? onRefresh;

  static const emptyKey = Key('deliveryOfferEmpty');
  static const refreshKey = Key('deliveryOfferEmptyRefresh');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      key: emptyKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: AppColors.secondary,
            semanticLabel: l10n.deliveryEmptyTitle,
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text(l10n.deliveryEmptyTitle, style: AppTextStyles.headlineLarge),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            l10n.deliveryEmptyMessage,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: AppTheme.spacingLG),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: refreshKey,
                onPressed: onRefresh,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.deliveryRetry),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
