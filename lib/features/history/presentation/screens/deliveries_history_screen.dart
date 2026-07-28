import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_empty_state.dart';
import '../../../../shared/widgets/saeq_error_state.dart';
import '../../../../shared/widgets/saeq_filter_chip_bar.dart';
import '../../../../shared/widgets/saeq_info_card.dart';
import '../../../../shared/widgets/saeq_loading_skeleton.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../../../shared/widgets/saeq_status_chip.dart';
import '../../domain/entities/delivery_history_item.dart';
import '../providers/history_providers.dart';

class DeliveriesHistoryScreen extends ConsumerWidget {
  const DeliveriesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final state = ref.watch(historyControllerProvider);
    final controller = ref.read(historyControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.deliveriesScreenTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.fakeAlphaDataHint,
                style: AppTextStyles.supporting.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
              SaeqFilterChipBar(
                chips: [
                  SaeqFilterChip(
                    label: l10n.historyFilterAll,
                    selected: state.filter == DeliveryHistoryFilter.all,
                    onTap: () =>
                        controller.setFilter(DeliveryHistoryFilter.all),
                  ),
                  SaeqFilterChip(
                    label: l10n.historyFilterDelivered,
                    selected: state.filter == DeliveryHistoryFilter.delivered,
                    onTap: () =>
                        controller.setFilter(DeliveryHistoryFilter.delivered),
                  ),
                  SaeqFilterChip(
                    label: l10n.historyFilterCancelled,
                    selected: state.filter == DeliveryHistoryFilter.cancelled,
                    onTap: () =>
                        controller.setFilter(DeliveryHistoryFilter.cancelled),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Expanded(child: _body(context, l10n, state, controller)),
              SaeqPrimaryButton(
                label: l10n.activeDeliveryScreenTitle,
                icon: Icons.local_shipping_outlined,
                onPressed: () => context.push(AppRoutes.deliveryActive),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    HistoryControllerState state,
    HistoryController controller,
  ) {
    if (state.loading) {
      return SaeqLoadingSkeleton(title: l10n.loading);
    }
    if (state.failureMessage != null) {
      return SaeqErrorState(
        title: l10n.historyErrorTitle,
        message: l10n.historyErrorMessage,
        retryLabel: l10n.profileRetry,
        onRetry: controller.load,
      );
    }
    if (state.items.isEmpty) {
      return SaeqEmptyState(
        title: l10n.historyEmptyTitle,
        message: l10n.historyEmptyMessage,
        icon: Icons.history,
      );
    }
    final colors = SaeqSemanticColors.of(context);
    return ListView.separated(
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingSM),
      itemBuilder: (context, index) {
        final item = state.items[index];
        final isCancelled = item.statusLabelKey == 'cancelled';
        return SaeqInfoCard(
          title: item.storeName,
          subtitle: '${item.pickupLabel} → ${item.dropoffLabel}',
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              SaeqStatusChip(
                label: isCancelled
                    ? l10n.historyStatusCancelled
                    : l10n.historyStatusDelivered,
                tone: isCancelled
                    ? SaeqStatusTone.danger
                    : SaeqStatusTone.success,
              ),
              const SizedBox(height: AppTheme.spacingXS),
              Text(
                l10n.homeEarningsValue(item.earningsSar.toStringAsFixed(1)),
                style: AppTextStyles.monetary.copyWith(color: colors.primary),
              ),
            ],
          ),
          onTap: () => context.push(AppRoutes.deliveryHistoryDetail(item.id)),
        );
      },
    );
  }
}

class DeliveryHistoryDetailScreen extends ConsumerWidget {
  const DeliveryHistoryDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final async = ref.watch(historyDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyDetailTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: async.when(
            loading: () => SaeqLoadingSkeleton(title: l10n.loading),
            error: (_, _) => SaeqErrorState(
              title: l10n.historyErrorTitle,
              message: l10n.historyErrorMessage,
              retryLabel: l10n.profileRetry,
              onRetry: () => ref.invalidate(historyDetailProvider(id)),
            ),
            data: (item) {
              if (item == null) {
                return SaeqEmptyState(
                  title: l10n.historyDetailTitle,
                  message: l10n.historyEmptyMessage,
                );
              }
              final isCancelled = item.statusLabelKey == 'cancelled';
              return ListView(
                children: [
                  Text(
                    item.storeName,
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  Text(
                    '${l10n.deliveryOfferPickupLabel}: ${item.pickupLabel}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  Text(
                    '${l10n.deliveryOfferDropoffLabel}: ${item.dropoffLabel}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSM),
                  SaeqStatusChip(
                    label: isCancelled
                        ? l10n.historyStatusCancelled
                        : l10n.historyStatusDelivered,
                    tone: isCancelled
                        ? SaeqStatusTone.danger
                        : SaeqStatusTone.success,
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  Text(
                    l10n.homeEarningsValue(item.earningsSar.toStringAsFixed(1)),
                    style: AppTextStyles.monetary.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                  SaeqPrimaryButton(
                    label: l10n.navDeliveries,
                    onPressed: () => context.go(AppRoutes.deliveries),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
