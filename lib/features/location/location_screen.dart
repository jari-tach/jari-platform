import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';
import '../../shared/widgets/saeq_error_state.dart';
import '../../shared/widgets/saeq_info_card.dart';
import '../../shared/widgets/saeq_loading_skeleton.dart';
import '../../shared/widgets/saeq_primary_button.dart';
import '../../shared/widgets/saeq_secondary_button.dart';
import '../../shared/widgets/saeq_status_chip.dart';
import 'location_feature.dart';
import 'location_ui_helpers.dart';
import 'trial_state_selector.dart';

/// Driver location and GPS states (STEP 2B Fake UI).
class LocationScreen extends ConsumerWidget {
  const LocationScreen({super.key});

  static const allowKey = Key('locationAllowAction');
  static const refreshKey = Key('locationRefreshAction');
  static const mapPreviewKey = Key('locationMapPreviewAction');
  static const openSettingsKey = Key('locationOpenSettingsAction');
  static const settingsGuidanceKey = Key('locationSettingsGuidance');
  static const blockedRetryKey = Key('locationBlockedRetryAction');
  static const accuracyChipKey = Key('locationAccuracyChip');
  static const trialSelectorKey = Key('locationTrialSelector');

  static Key trialOptionKey(FakeLocationScenario scenario) =>
      Key('locationTrialOption-${scenario.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(locationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.locationTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _body(context, ref, l10n, state),
              const SizedBox(height: AppTheme.spacingLG),
              _trialSelector(ref, l10n, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    LocationState state,
  ) {
    final controller = ref.read(locationControllerProvider.notifier);

    if (state.serviceUnavailable) {
      return SaeqErrorState(
        title: l10n.locationUnavailableTitle,
        message: l10n.locationUnavailableMessage,
        retryLabel: l10n.profileRetry,
        onRetry: controller.retry,
      );
    }

    switch (state.status) {
      case LocationViewStatus.permissionIntro:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SaeqInfoCard(
              title: l10n.locationPermissionIntroTitle,
              subtitle: l10n.locationPermissionIntroMessage,
              leading: const Icon(Icons.my_location),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            _TrialNote(message: l10n.locationTrialNote),
            const SizedBox(height: AppTheme.spacingLG),
            SaeqPrimaryButton(
              key: allowKey,
              label: l10n.locationAllowAction,
              icon: Icons.location_on_outlined,
              onPressed: state.isProcessing
                  ? null
                  : controller.requestPermission,
              isLoading: state.isProcessing,
            ),
          ],
        );

      case LocationViewStatus.locating:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SaeqLoadingSkeleton(
              title: l10n.locationLocatingTitle,
              message: l10n.locationLocatingMessage,
            ),
            const SizedBox(height: AppTheme.spacingLG),
            // Same key as the entry action: the in-flight guard stays visible
            // so repeated taps cannot re-trigger the transition.
            SaeqPrimaryButton(
              key: allowKey,
              label: l10n.locationAllowAction,
              icon: Icons.location_on_outlined,
              onPressed: null,
              isLoading: true,
            ),
          ],
        );

      case LocationViewStatus.available:
      case LocationViewStatus.weakAccuracy:
        final isWeak = state.status == LocationViewStatus.weakAccuracy;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SaeqInfoCard(
              title: isWeak
                  ? l10n.locationWeakAccuracyTitle
                  : l10n.locationAvailableTitle,
              subtitle: isWeak
                  ? l10n.locationWeakAccuracyMessage
                  : l10n.locationAvailableMessage,
              leading: Icon(isWeak ? Icons.gps_not_fixed : Icons.gps_fixed),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SaeqStatusChip(
                  key: accuracyChipKey,
                  label: locationAccuracyChipLabel(
                    l10n,
                    state.accuracy,
                    state.accuracyMeters,
                  ),
                  tone: locationAccuracyTone(state.accuracy),
                  icon: locationAccuracyIcon(state.accuracy),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            SaeqPrimaryButton(
              key: mapPreviewKey,
              label: l10n.locationOpenMapPreviewAction,
              icon: Icons.map_outlined,
              onPressed: () => context.push(AppRoutes.mapPreview),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            SaeqSecondaryButton(
              key: refreshKey,
              label: l10n.locationRefreshAction,
              icon: Icons.refresh,
              onPressed: state.isProcessing ? null : controller.retry,
              isLoading: state.isProcessing,
            ),
          ],
        );

      case LocationViewStatus.permissionDenied:
        return SaeqErrorState(
          title: l10n.locationDeniedTitle,
          message: l10n.locationDeniedMessage,
          retryLabel: l10n.profileRetry,
          onRetry: controller.retry,
        );

      case LocationViewStatus.permissionPermanentlyDenied:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SaeqInfoCard(
              title: l10n.locationPermanentlyDeniedTitle,
              subtitle: l10n.locationPermanentlyDeniedMessage,
              leading: const Icon(Icons.location_disabled),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SaeqStatusChip(
                  label: l10n.locationPermanentlyDeniedTitle,
                  tone: SaeqStatusTone.danger,
                  icon: Icons.block,
                ),
              ),
            ),
            if (state.settingsGuidanceVisible) ...[
              const SizedBox(height: AppTheme.spacingSM),
              _TrialNote(
                key: settingsGuidanceKey,
                message: l10n.locationOpenSettingsGuidance,
                liveRegion: true,
              ),
            ],
            const SizedBox(height: AppTheme.spacingLG),
            SaeqPrimaryButton(
              key: openSettingsKey,
              label: l10n.locationOpenSettingsAction,
              icon: Icons.settings_outlined,
              onPressed: controller.showSettingsGuidance,
            ),
            const SizedBox(height: AppTheme.spacingSM),
            SaeqSecondaryButton(
              key: blockedRetryKey,
              label: l10n.profileRetry,
              icon: Icons.refresh,
              onPressed: state.isProcessing ? null : controller.retry,
            ),
          ],
        );

      case LocationViewStatus.gpsDisabled:
        return SaeqErrorState(
          title: l10n.locationGpsDisabledTitle,
          message: l10n.locationGpsDisabledMessage,
          retryLabel: l10n.profileRetry,
          onRetry: controller.retry,
        );

      case LocationViewStatus.offline:
        return SaeqErrorState(
          title: l10n.locationOfflineTitle,
          message: l10n.locationOfflineMessage,
          retryLabel: l10n.profileRetry,
          onRetry: controller.retry,
        );
    }
  }

  Widget _trialSelector(
    WidgetRef ref,
    AppLocalizations l10n,
    LocationState state,
  ) {
    final controller = ref.read(locationControllerProvider.notifier);
    return TrialStateSelector(
      key: trialSelectorKey,
      title: l10n.locationTrialStatesTitle,
      hint: l10n.locationTrialStatesHint,
      options: [
        for (final scenario in FakeLocationScenario.values)
          TrialStateOption(
            optionKey: trialOptionKey(scenario),
            label: locationScenarioLabel(l10n, scenario),
            selected: state.scenario == scenario,
            onSelected: state.isProcessing
                ? null
                : () => controller.selectScenario(scenario),
          ),
      ],
    );
  }
}

class _TrialNote extends StatelessWidget {
  const _TrialNote({super.key, required this.message, this.liveRegion = false});

  final String message;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return Semantics(
      liveRegion: liveRegion,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing12),
        decoration: BoxDecoration(
          color: colors.informationContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: colors.information.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: colors.information, size: 20),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
