import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_earnings_row.dart';
import '../../../../shared/widgets/saeq_empty_state.dart';
import '../../../../shared/widgets/saeq_error_state.dart';
import '../../../../shared/widgets/saeq_filter_chip_bar.dart';
import '../../../../shared/widgets/saeq_loading_skeleton.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../domain/entities/earnings_period.dart';
import '../providers/earnings_providers.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(earningsControllerProvider);
    final controller = ref.read(earningsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.earningsScreenTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SaeqFilterChipBar(
                chips: [
                  SaeqFilterChip(
                    label: l10n.earningsFilterAll,
                    selected: state.filter == EarningsFilter.all,
                    onTap: () => controller.setFilter(EarningsFilter.all),
                  ),
                  SaeqFilterChip(
                    label: l10n.earningsFilterToday,
                    selected: state.filter == EarningsFilter.today,
                    onTap: () => controller.setFilter(EarningsFilter.today),
                  ),
                  SaeqFilterChip(
                    label: l10n.earningsFilterWeek,
                    selected: state.filter == EarningsFilter.week,
                    onTap: () => controller.setFilter(EarningsFilter.week),
                  ),
                  SaeqFilterChip(
                    label: l10n.earningsFilterMonth,
                    selected: state.filter == EarningsFilter.month,
                    onTap: () => controller.setFilter(EarningsFilter.month),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Expanded(child: _body(context, l10n, state, controller)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    EarningsControllerState state,
    EarningsController controller,
  ) {
    if (state.loading) return SaeqLoadingSkeleton(title: l10n.loading);
    if (state.failureMessage != null) {
      return SaeqErrorState(
        title: l10n.earningsErrorTitle,
        message: l10n.earningsErrorMessage,
        retryLabel: l10n.profileRetry,
        onRetry: controller.load,
      );
    }
    if (state.items.isEmpty) {
      return SaeqEmptyState(
        title: l10n.earningsEmptyTitle,
        message: l10n.earningsEmptyMessage,
        icon: Icons.payments_outlined,
      );
    }
    return ListView.separated(
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingSM),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return SaeqEarningsRow(
          title: _periodLabel(l10n, item.labelKey),
          subtitle: l10n.homeTripsValue(item.tripsCount),
          amountLabel: l10n.homeEarningsValue(
            item.amountSar.toStringAsFixed(1),
          ),
          onTap: () => context.push(AppRoutes.earningsDetail(item.id)),
        );
      },
    );
  }

  String _periodLabel(AppLocalizations l10n, String key) {
    return switch (key) {
      'today' => l10n.earningsFilterToday,
      'week' => l10n.earningsFilterWeek,
      'month' => l10n.earningsFilterMonth,
      _ => key,
    };
  }
}

class EarningsDetailScreen extends ConsumerWidget {
  const EarningsDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final async = ref.watch(earningsDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.earningsDetailTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: async.when(
            loading: () => SaeqLoadingSkeleton(title: l10n.loading),
            error: (_, _) => SaeqErrorState(
              title: l10n.earningsErrorTitle,
              message: l10n.earningsErrorMessage,
              retryLabel: l10n.profileRetry,
              onRetry: () => ref.invalidate(earningsDetailProvider(id)),
            ),
            data: (item) {
              if (item == null) {
                return SaeqEmptyState(
                  title: l10n.earningsDetailTitle,
                  message: l10n.earningsEmptyMessage,
                );
              }
              return ListView(
                children: [
                  Text(
                    l10n.homeEarningsValue(item.amountSar.toStringAsFixed(1)),
                    style: AppTextStyles.monetary.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  Text(
                    l10n.homeTripsValue(item.tripsCount),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLG),
                  SaeqPrimaryButton(
                    label: l10n.navEarnings,
                    onPressed: () => context.go(AppRoutes.earnings),
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
