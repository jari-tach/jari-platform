import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/saeq_loading_skeleton.dart';

/// Centered loading body for delivery offer UI.
class DeliveryOfferLoadingState extends StatelessWidget {
  const DeliveryOfferLoadingState({super.key});

  static const progressKey = SaeqLoadingSkeleton.progressKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SaeqLoadingSkeleton(
      title: l10n.deliveryLoadingTitle,
      message: l10n.deliveryLoadingMessage,
      semanticsLabel: l10n.deliverySemanticsProgress,
    );
  }
}
