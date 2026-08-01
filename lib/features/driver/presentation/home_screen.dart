import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/providers/home_ui_providers.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/saeq_semantic_colors.dart';
import '../../../shared/widgets/saeq_brand_mark.dart';
import '../../../shared/widgets/saeq_icon_button.dart';
import '../../../shared/widgets/saeq_info_card.dart';
import '../../../shared/widgets/saeq_offline_banner.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../availability/presentation/widgets/availability_connectivity_bridge.dart';
import '../../availability/presentation/widgets/driver_availability_card.dart';
import '../../delivery/presentation/providers/delivery_providers.dart';
import '../../delivery/presentation/widgets/delivery_offer_home_banner.dart';
import '../../realtime/domain/entities/realtime_connection_status.dart';
import '../../realtime/presentation/providers/realtime_providers.dart';
import '../../realtime/presentation/widgets/realtime_connection_banner.dart';

/// Authenticated Home dashboard (PHASE 2.6 Batch 3 — Figma Home/Availability).
///
/// Sign-out lives in Settings (with confirmation + [prepareForLogout]), not here.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const notificationsActionKey = Key('homeNotificationsAction');
  static const greetingKey = Key('homeGreeting');
  static const summaryStripKey = Key('homeSummaryStrip');
  static const quickActionDeliveriesKey = Key('homeQuickActionDeliveries');
  static const quickActionEarningsKey = Key('homeQuickActionEarnings');
  static const quickActionNotificationsKey = Key(
    'homeQuickActionNotifications',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final state = ref.watch(authControllerProvider);
    final session = state.session;
    final offline = ref.watch(isOfflineProvider);
    final realtime = ref.watch(realtimeControllerProvider);
    final summary = ref.watch(fakeHomeSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const SaeqBrandAppBarTitle(),
        actions: [
          SaeqIconButton(
            key: notificationsActionKey,
            icon: Icons.notifications_outlined,
            tooltip: l10n.homeOpenNotificationsTooltip,
            onPressed: () => context.go(AppRoutes.notifications),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AvailabilityConnectivityBridge(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SaeqOfflineBanner(
                        message: l10n.offlineBannerMessage,
                        visible: offline,
                      ),
                      RealtimeConnectionBanner(
                        status: realtime.status,
                        message: _realtimeMessage(l10n, realtime.status),
                      ),
                      Text(
                        key: greetingKey,
                        l10n.homeWelcomeTitle,
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: AppTheme.fontWeightBold,
                        ),
                      ),
                      if (session != null) ...[
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          session.maskedPhoneNumber,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingMD),
                      const DriverAvailabilityCard(),
                      const SizedBox(height: AppTheme.spacingMD),
                      const DeliveryOfferHomeBanner(),
                      const _HomeNoOfferHint(),
                      // Metrics strip only when a summary source is wired
                      // (hidden in production via fakeHomeSummaryProvider).
                      if (summary != null) ...[
                        const SizedBox(height: AppTheme.spacingMD),
                        _HomeSummaryStrip(summary: summary),
                      ],
                      const SizedBox(height: AppTheme.spacingLG),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeNoOfferHint extends ConsumerWidget {
  const _HomeNoOfferHint();

  static const keyHint = Key('homeNoOfferHint');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delivery = ref.watch(deliveryControllerProvider);
    if (delivery.hasOffer || delivery.hasActiveAssignment) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    return Padding(
      key: keyHint,
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSM),
      child: Text(
        l10n.homeNoOfferMessage,
        style: AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

class _HomeSummaryStrip extends StatelessWidget {
  const _HomeSummaryStrip({required this.summary});

  final FakeHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final amount = summary.todayEarningsSar.toStringAsFixed(
      summary.todayEarningsSar == summary.todayEarningsSar.roundToDouble()
          ? 0
          : 1,
    );

    return SaeqInfoCard(
      key: HomeScreen.summaryStripKey,
      title: l10n.homeSummarySectionTitle,
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: l10n.homeTodayEarningsLabel,
              value: l10n.homeEarningsValue(amount),
            ),
          ),
          Expanded(
            child: _Metric(
              label: l10n.homeTripsTodayLabel,
              value: l10n.homeTripsValue(summary.completedTripsToday),
            ),
          ),
          Expanded(
            child: _Metric(
              label: l10n.homeAcceptanceRateLabel,
              value: l10n.homeAcceptanceValue(summary.acceptanceRatePercent),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

String _realtimeMessage(
  AppLocalizations l10n,
  RealtimeConnectionStatus status,
) {
  return switch (status) {
    RealtimeConnectionStatus.reconnecting => l10n.realtimeReconnecting,
    RealtimeConnectionStatus.degraded => l10n.realtimeDegraded,
    RealtimeConnectionStatus.catchingUp => l10n.realtimeCatchingUp,
    RealtimeConnectionStatus.connected => l10n.realtimeConnected,
    RealtimeConnectionStatus.idle ||
    RealtimeConnectionStatus.stopped => l10n.realtimeConnected,
  };
}
