import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../pages/incoming_delivery_offer_page.dart';
import '../providers/delivery_providers.dart';

/// Home entry to the full-screen offer surface (ADR-026).
///
/// Visible only when an offer or active assignment is present — does not
/// invent navigation when idle.
class DeliveryOfferHomeBanner extends ConsumerWidget {
  const DeliveryOfferHomeBanner({super.key});

  static const bannerKey = Key('deliveryOfferHomeBanner');
  static const openKey = Key('deliveryOfferHomeOpen');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(deliveryControllerProvider);

    if (!state.hasOffer && !state.hasActiveAssignment) {
      return const SizedBox.shrink();
    }

    final isAssignment = state.hasActiveAssignment && !state.hasOffer;
    final title = isAssignment
        ? l10n.deliveryHomeAssignmentBannerTitle
        : l10n.deliveryHomeOfferBannerTitle;
    final action = isAssignment
        ? l10n.deliveryHomeAssignmentBannerAction
        : l10n.deliveryHomeOfferBannerAction;

    return Semantics(
      container: true,
      button: true,
      label: title,
      child: Material(
        key: bannerKey,
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: InkWell(
          key: openKey,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          onTap: () => _openOffer(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  isAssignment
                      ? Icons.local_shipping_outlined
                      : Icons.notifications_active_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleMedium),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(action, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: AppColors.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openOffer(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.push(AppRoutes.deliveryOffer);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const IncomingDeliveryOfferPage(),
      ),
    );
  }
}
