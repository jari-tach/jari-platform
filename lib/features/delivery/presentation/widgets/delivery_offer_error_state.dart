import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/saeq_error_state.dart';

/// Error body with retry — mirrors Profile `_MessageState` pattern.
class DeliveryOfferErrorState extends StatelessWidget {
  const DeliveryOfferErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  static const errorKey = SaeqErrorState.errorKey;
  static const retryKey = SaeqErrorState.retryKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SaeqErrorState(
      title: l10n.deliveryErrorTitle,
      message: message,
      retryLabel: l10n.deliveryRetry,
      onRetry: onRetry,
      semanticsLabel: l10n.deliverySemanticsFailure,
    );
  }
}
