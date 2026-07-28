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
import '../../../../shared/widgets/saeq_loading_skeleton.dart';
import '../../../../shared/widgets/saeq_notification_row.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../../../shared/widgets/saeq_status_chip.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsScreenTitle)),
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
    NotificationsControllerState state,
    NotificationsController controller,
  ) {
    if (state.loading) return SaeqLoadingSkeleton(title: l10n.loading);
    if (state.failureMessage != null) {
      return SaeqErrorState(
        title: l10n.notificationsErrorTitle,
        message: l10n.notificationsErrorMessage,
        retryLabel: l10n.profileRetry,
        onRetry: controller.load,
      );
    }
    if (state.items.isEmpty) {
      return SaeqEmptyState(
        title: l10n.notificationsEmptyTitle,
        message: l10n.notificationsEmptyMessage,
        icon: Icons.notifications_none,
      );
    }
    return ListView.separated(
      itemCount: state.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingSM),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return SaeqNotificationRow(
          title: _title(l10n, item.titleKey),
          body: _bodyText(l10n, item.bodyKey),
          isRead: item.isRead,
          readLabel: l10n.notificationRead,
          unreadLabel: l10n.notificationUnread,
          onTap: () => context.push(AppRoutes.notificationDetail(item.id)),
        );
      },
    );
  }

  String _title(AppLocalizations l10n, String key) {
    return switch (key) {
      'offer' => l10n.notificationTitleOffer,
      'payout' => l10n.notificationTitlePayout,
      'system' => l10n.notificationTitleSystem,
      _ => key,
    };
  }

  String _bodyText(AppLocalizations l10n, String key) {
    return switch (key) {
      'offer_body' => l10n.notificationBodyOffer,
      'payout_body' => l10n.notificationBodyPayout,
      'system_body' => l10n.notificationBodySystem,
      _ => key,
    };
  }
}

class NotificationDetailScreen extends ConsumerWidget {
  const NotificationDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final async = ref.watch(notificationDetailProvider(id));
    final controller = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationDetailTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: async.when(
            loading: () => SaeqLoadingSkeleton(title: l10n.loading),
            error: (_, _) => SaeqErrorState(
              title: l10n.notificationsErrorTitle,
              message: l10n.notificationsErrorMessage,
              retryLabel: l10n.profileRetry,
              onRetry: () => ref.invalidate(notificationDetailProvider(id)),
            ),
            data: (item) {
              if (item == null) {
                return SaeqEmptyState(
                  title: l10n.notificationDetailTitle,
                  message: l10n.notificationsEmptyMessage,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _title(l10n, item.titleKey),
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      SaeqStatusChip(
                        label: item.isRead
                            ? l10n.notificationRead
                            : l10n.notificationUnread,
                        tone: item.isRead
                            ? SaeqStatusTone.neutral
                            : SaeqStatusTone.warning,
                        icon: item.isRead
                            ? Icons.mark_email_read_outlined
                            : Icons.mark_email_unread_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  Text(
                    _bodyText(l10n, item.bodyKey),
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (!item.isRead)
                    SaeqPrimaryButton(
                      label: l10n.notificationMarkRead,
                      onPressed: () async {
                        await controller.markRead(id);
                        if (context.mounted) {
                          context.go(AppRoutes.notifications);
                        }
                      },
                    ),
                  if (item.isRead)
                    SaeqPrimaryButton(
                      label: l10n.navNotifications,
                      onPressed: () => context.go(AppRoutes.notifications),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n, String key) {
    return switch (key) {
      'offer' => l10n.notificationTitleOffer,
      'payout' => l10n.notificationTitlePayout,
      'system' => l10n.notificationTitleSystem,
      _ => key,
    };
  }

  String _bodyText(AppLocalizations l10n, String key) {
    return switch (key) {
      'offer_body' => l10n.notificationBodyOffer,
      'payout_body' => l10n.notificationBodyPayout,
      'system_body' => l10n.notificationBodySystem,
      _ => key,
    };
  }
}
