import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/saeq_error_state.dart';
import '../../shared/widgets/saeq_loading_skeleton.dart';
import 'fake_map_placeholder.dart';
import 'location_ui_helpers.dart';
import 'map_preview_feature.dart';
import 'trial_state_selector.dart';

/// Fake map preview for the active-delivery route (STEP 2B Fake UI).
class MapPreviewScreen extends ConsumerWidget {
  const MapPreviewScreen({super.key});

  static const trialSelectorKey = Key('mapPreviewTrialSelector');

  static Key trialOptionKey(FakeMapScenario scenario) =>
      Key('mapPreviewTrialOption-${scenario.name}');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(mapPreviewControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapPreviewTitle)),
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
    MapPreviewState state,
  ) {
    final controller = ref.read(mapPreviewControllerProvider.notifier);

    switch (state.status) {
      case MapPreviewStatus.loading:
        return SaeqLoadingSkeleton(
          title: l10n.mapPreviewLoadingTitle,
          message: l10n.mapPreviewLoadingMessage,
        );

      case MapPreviewStatus.error:
        return SaeqErrorState(
          title: l10n.mapPreviewErrorTitle,
          message: l10n.mapPreviewErrorMessage,
          retryLabel: l10n.profileRetry,
          onRetry: controller.retry,
        );

      case MapPreviewStatus.offline:
        return SaeqErrorState(
          title: l10n.mapPreviewOfflineTitle,
          message: l10n.mapPreviewOfflineMessage,
          retryLabel: l10n.profileRetry,
          onRetry: controller.retry,
        );

      case MapPreviewStatus.loadedPlaceholder:
      case MapPreviewStatus.externalNavigationUnavailable:
        final snapshot = state.snapshot;
        if (snapshot == null) {
          return SaeqLoadingSkeleton(
            title: l10n.mapPreviewLoadingTitle,
            message: l10n.mapPreviewLoadingMessage,
          );
        }
        return FakeMapPlaceholder(
          snapshot: snapshot,
          isProcessing: state.isProcessing,
          externalNavigationUnavailable:
              state.status == MapPreviewStatus.externalNavigationUnavailable,
          onRetry: controller.retry,
          onOpenExternalNavigation: controller.openExternalNavigation,
          onBack: () => _leavePreview(context, controller),
        );
    }
  }

  Widget _trialSelector(
    WidgetRef ref,
    AppLocalizations l10n,
    MapPreviewState state,
  ) {
    final controller = ref.read(mapPreviewControllerProvider.notifier);
    return TrialStateSelector(
      key: trialSelectorKey,
      title: l10n.locationTrialStatesTitle,
      hint: l10n.mapPreviewTrialStatesHint,
      options: [
        for (final scenario in FakeMapScenario.values)
          TrialStateOption(
            optionKey: trialOptionKey(scenario),
            label: mapScenarioLabel(l10n, scenario),
            selected: state.scenario == scenario,
            onSelected: state.isProcessing
                ? null
                : () => controller.selectScenario(scenario),
          ),
      ],
    );
  }

  static void _leavePreview(
    BuildContext context,
    MapPreviewController controller,
  ) {
    controller.dismissExternalNavigationNotice();
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.location);
  }
}
