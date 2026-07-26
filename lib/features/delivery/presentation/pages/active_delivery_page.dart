import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/saeq_empty_state.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../providers/delivery_providers.dart';
import '../state/delivery_controller_state.dart';
import '../widgets/delivery_assignment_summary.dart';
import '../widgets/delivery_offer_loading_state.dart';

/// Active-delivery stub (Increment 1) — assignment summary only.
///
/// Stage machine lands in Increment 2. Continue returns to Home.
class ActiveDeliveryPage extends ConsumerWidget {
  const ActiveDeliveryPage({super.key});

  static const pageKey = Key('activeDeliveryPage');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(deliveryControllerProvider);

    return Scaffold(
      key: pageKey,
      appBar: AppBar(title: Text(l10n.activeDeliveryScreenTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: _buildBody(context, l10n, state),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    DeliveryControllerState state,
  ) {
    if (state.status == DeliveryViewStatus.initial ||
        state.status == DeliveryViewStatus.loading) {
      return const DeliveryOfferLoadingState();
    }

    if (!state.hasActiveAssignment) {
      return Column(
        children: [
          Expanded(
            child: SaeqEmptyState(
              title: l10n.activeDeliveryScreenTitle,
              message: l10n.shellPlaceholderMessage,
              icon: Icons.local_shipping_outlined,
            ),
          ),
          SaeqPrimaryButton(
            label: l10n.navHome,
            icon: Icons.home_outlined,
            onPressed: () => context.go(AppRoutes.home),
          ),
          const SizedBox(height: AppTheme.spacingSM),
        ],
      );
    }

    return SingleChildScrollView(
      child: DeliveryAssignmentSummary(
        assignment: state.activeAssignment!,
        onContinue: () => context.go(AppRoutes.home),
      ),
    );
  }
}
