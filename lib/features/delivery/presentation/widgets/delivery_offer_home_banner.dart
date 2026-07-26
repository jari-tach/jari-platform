import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../pages/active_delivery_page.dart';
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
    final colors = SaeqSemanticColors.of(context);

    return Semantics(
      container: true,
      button: true,
      label: title,
      child: Material(
        key: bannerKey,
        color: isAssignment ? colors.primaryContainer : colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: InkWell(
          key: openKey,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          onTap: () => _openSurface(context, isAssignment: isAssignment),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
              border: Border.all(
                color: isAssignment
                    ? colors.primary.withValues(alpha: 0.35)
                    : colors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAssignment
                      ? Icons.local_shipping_outlined
                      : Icons.notifications_active_outlined,
                  color: colors.primary,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        action,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left
                      : Icons.chevron_right,
                  color: colors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSurface(BuildContext context, {required bool isAssignment}) {
    final route = isAssignment
        ? AppRoutes.deliveryActive
        : AppRoutes.deliveryOffer;
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.push(route);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => isAssignment
            ? const ActiveDeliveryPage()
            : const IncomingDeliveryOfferPage(),
      ),
    );
  }
}
