import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/delivery_controller.dart';
import '../mappers/delivery_failure_messages.dart';
import '../providers/delivery_providers.dart';
import '../state/delivery_controller_state.dart';
import '../widgets/delivery_assignment_summary.dart';
import '../widgets/delivery_offer_card.dart';
import '../widgets/delivery_offer_empty_state.dart';
import '../widgets/delivery_offer_error_state.dart';
import '../widgets/delivery_offer_loading_state.dart';
import '../../../batch/batch_feature.dart';
import '../../../batch/widgets/batch_offer_entry_card.dart';

/// Full-screen delivery offer / assignment surface (ADR-026).
///
/// Consumes [deliveryControllerProvider] only — no repositories/datasources.
class IncomingDeliveryOfferPage extends ConsumerWidget {
  const IncomingDeliveryOfferPage({super.key, this.now});

  /// Injectable clock for countdown tests.
  final DateTime Function()? now;

  static const pageKey = Key('incomingDeliveryOfferPage');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(deliveryControllerProvider);
    final controller = ref.read(deliveryControllerProvider.notifier);

    return Scaffold(
      key: pageKey,
      appBar: AppBar(
        title: Text(
          state.hasActiveAssignment && !state.hasOffer
              ? l10n.deliveryAcceptedTitle
              : l10n.deliveryOfferTitle,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: _buildBody(context, ref, l10n, state, controller),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    DeliveryControllerState state,
    DeliveryController controller,
  ) {
    if (state.status == DeliveryViewStatus.initial ||
        state.status == DeliveryViewStatus.loading) {
      return const DeliveryOfferLoadingState();
    }

    if (state.status == DeliveryViewStatus.failure &&
        !state.hasOffer &&
        !state.hasActiveAssignment) {
      return DeliveryOfferErrorState(
        message: state.failure == null
            ? l10n.deliveryErrorGenericMessage
            : deliveryFailureMessage(state.failure!, l10n),
        onRetry: () => controller.initialize(),
      );
    }

    if (state.hasActiveAssignment && !state.hasOffer) {
      return SingleChildScrollView(
        child: DeliveryAssignmentSummary(
          assignment: state.activeAssignment!,
          onContinue: () => _continueDelivery(context),
        ),
      );
    }

    final showBatchEntry = ref.watch(batchFixtureEntryEnabledProvider);

    if (state.hasOffer) {
      return RefreshIndicator(
        onRefresh: () => controller.refreshOffers(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (state.failure != null) ...[
                _InlineFailureBanner(
                  message: deliveryFailureMessage(state.failure!, l10n),
                  onDismiss: () => controller.clearFailure(),
                  dismissLabel: l10n.deliveryDismissFailure,
                ),
                const SizedBox(height: AppTheme.spacingMD),
              ],
              DeliveryOfferCard(
                offer: state.activeOffer!,
                state: state,
                controller: controller,
                now: now,
              ),
              if (showBatchEntry) ...[
                const SizedBox(height: AppTheme.spacingMD),
                const BatchOfferEntryCard(),
              ],
            ],
          ),
        ),
      );
    }

    if (state.isEmpty || state.isInitialized) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (showBatchEntry) ...[
              const BatchOfferEntryCard(),
              const SizedBox(height: AppTheme.spacingMD),
            ],
            DeliveryOfferEmptyState(
              onRefresh: state.canRefresh
                  ? () => controller.refreshOffers()
                  : null,
            ),
          ],
        ),
      );
    }

    return const DeliveryOfferLoadingState();
  }

  void _continueDelivery(BuildContext context) {
    // Increment 1: route to active-delivery stub (summary only).
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(AppRoutes.deliveryActive);
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _InlineFailureBanner extends StatelessWidget {
  const _InlineFailureBanner({
    required this.message,
    required this.onDismiss,
    required this.dismissLabel,
  });

  final String message;
  final VoidCallback onDismiss;
  final String dismissLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: l10n.deliverySemanticsFailure,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingSM),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onDismiss,
                child: Text(dismissLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
