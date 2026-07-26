import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/saeq_empty_state.dart';

/// Empty offers body with optional refresh action.
class DeliveryOfferEmptyState extends StatelessWidget {
  const DeliveryOfferEmptyState({super.key, this.onRefresh});

  final VoidCallback? onRefresh;

  static const emptyKey = SaeqEmptyState.emptyKey;
  static const refreshKey = SaeqEmptyState.actionKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SaeqEmptyState(
      title: l10n.deliveryEmptyTitle,
      message: l10n.deliveryEmptyMessage,
      icon: Icons.inbox_outlined,
      actionLabel: onRefresh == null ? null : l10n.deliveryRetry,
      onAction: onRefresh,
    );
  }
}
