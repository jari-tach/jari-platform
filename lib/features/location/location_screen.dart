import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routes/app_router.dart';
import '../../shared/widgets/saeq_primary_button.dart';
import '../../shared/widgets/saeq_secondary_button.dart';
import 'location_feature.dart';
import 'location_ui_helpers.dart';

/// P27 Driver Completion location states (STEP 2B fake UI only).
class LocationScreen extends ConsumerWidget {
  const LocationScreen({super.key});

  static const allowKey = Key('locationAllowAction');
  static const notNowKey = Key('locationNotNowAction');
  static const refreshKey = Key('locationRefreshAction');
  static const mapPreviewKey = Key('locationMapPreviewAction');
  static const openSettingsKey = Key('locationOpenSettingsAction');
  static const blockedRetryKey = Key('locationBlockedRetryAction');
  static const accuracyChipKey = Key('locationAccuracyChip');
  static const permissionMapKey = Key('locationPermissionMap');
  static const usageFieldKey = Key('locationUsageField');
  static const accuracyFieldKey = Key('locationAccuracyField');
  static const locatingMapSkeletonKey = Key('locationMapSkeleton');
  static const locatingDetailSkeletonKey = Key('locationDetailSkeleton');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(locationControllerProvider);
    final controller = ref.read(locationControllerProvider.notifier);

    return Scaffold(
      body: P27Page(
        title: _title(l10n, state.status),
        children: _content(context, l10n, state, controller),
      ),
    );
  }

  String _title(AppLocalizations l10n, LocationViewStatus status) {
    return switch (status) {
      LocationViewStatus.permissionIntro => l10n.locationPermissionPageTitle,
      LocationViewStatus.permissionDenied => l10n.locationDeniedTitle,
      LocationViewStatus.permissionPermanentlyDenied =>
        l10n.locationPermanentlyDeniedTitle,
      LocationViewStatus.gpsDisabled => l10n.locationGpsDisabledTitle,
      LocationViewStatus.locating => l10n.locationLocatingTitle,
      LocationViewStatus.available => l10n.locationAvailableTitle,
      LocationViewStatus.weakAccuracy => l10n.locationWeakAccuracyTitle,
      LocationViewStatus.stale => l10n.locationStaleTitle,
      LocationViewStatus.unavailable => l10n.locationGnssUnavailableTitle,
      LocationViewStatus.offline => l10n.locationOfflineTitle,
    };
  }

  List<Widget> _content(
    BuildContext context,
    AppLocalizations l10n,
    LocationState state,
    LocationController controller,
  ) {
    if (state.serviceUnavailable) {
      return [
        P27Banner(
          title: l10n.locationUnavailableTitle,
          message: l10n.locationUnavailableMessage,
          tone: P27BannerTone.error,
        ),
        const P27Skeleton(height: 430),
        _primary(
          key: blockedRetryKey,
          label: l10n.profileRetry,
          icon: Icons.refresh,
          onPressed: controller.retry,
        ),
      ];
    }

    return switch (state.status) {
      LocationViewStatus.permissionIntro => [
        P27Banner(
          title: l10n.locationPermissionReasonTitle,
          message: l10n.locationPermissionIntroMessage,
          tone: P27BannerTone.information,
        ),
        const KeyedSubtree(
          key: permissionMapKey,
          child: P27FakeMap(height: 300),
        ),
        P27Field(
          key: usageFieldKey,
          label: l10n.locationPermissionUsageLabel,
          value: l10n.locationPermissionUsageValue,
        ),
        P27Field(
          key: accuracyFieldKey,
          label: l10n.locationPermissionAccuracyLabel,
          value: l10n.locationPermissionAccuracyValue,
        ),
        _primary(
          key: allowKey,
          label: l10n.locationAllowAction,
          icon: Icons.location_on_outlined,
          onPressed: state.isProcessing ? null : controller.requestPermission,
        ),
        _secondary(
          key: notNowKey,
          label: l10n.locationNotNowAction,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ],
      LocationViewStatus.permissionDenied => [
        P27Banner(
          title: l10n.locationDeniedTitle,
          message: l10n.locationDeniedMessage,
          tone: P27BannerTone.warning,
        ),
        const P27Skeleton(height: 430),
        _primary(
          key: blockedRetryKey,
          label: l10n.profileRetry,
          icon: Icons.refresh,
          onPressed: state.isProcessing ? null : controller.retry,
        ),
        _secondary(
          label: l10n.locationReturnHomeAction,
          onPressed: () => context.go(AppRoutes.home),
        ),
      ],
      LocationViewStatus.permissionPermanentlyDenied => [
        P27Banner(
          title: l10n.locationPermanentlyDeniedTitle,
          message: l10n.locationPermanentlyDeniedMessage,
          tone: P27BannerTone.error,
        ),
        P27Field(
          label: l10n.locationPermissionPathLabel,
          value: l10n.locationPermissionPathValue,
        ),
        const P27Skeleton(height: 390),
        _primary(
          key: openSettingsKey,
          label: l10n.locationOpenAppSettingsAction,
          icon: Icons.settings_outlined,
          onPressed: controller.showSettingsGuidance,
        ),
        _secondary(
          key: blockedRetryKey,
          label: l10n.mapPreviewBackAction,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ],
      LocationViewStatus.gpsDisabled => [
        P27Banner(
          title: l10n.locationGpsDisabledTitle,
          message: l10n.locationGpsDisabledMessage,
          tone: P27BannerTone.warning,
        ),
        const P27FakeMap(height: 300),
        _primary(
          key: openSettingsKey,
          label: l10n.locationOpenLocationSettingsAction,
          icon: Icons.settings_outlined,
          onPressed: controller.showSettingsGuidance,
        ),
        _secondary(
          key: blockedRetryKey,
          label: l10n.profileRetry,
          icon: Icons.refresh,
          onPressed: state.isProcessing ? null : controller.retry,
        ),
      ],
      LocationViewStatus.locating => [
        P27Banner(
          title: l10n.locationLocatingTitle,
          message: l10n.locationLocatingMessage,
          tone: P27BannerTone.information,
        ),
        const KeyedSubtree(
          key: locatingMapSkeletonKey,
          child: P27Skeleton(height: 300),
        ),
        const KeyedSubtree(
          key: locatingDetailSkeletonKey,
          child: P27Skeleton(height: 220),
        ),
        _primary(
          key: allowKey,
          label: l10n.locationLocatingTitle,
          onPressed: null,
          loading: true,
        ),
      ],
      LocationViewStatus.available => [
        P27Banner(
          title: l10n.locationAvailableTitle,
          message: l10n.locationAvailableMessage,
          tone: P27BannerTone.success,
        ),
        const P27FakeMap(height: 300),
        P27Field(
          key: accuracyChipKey,
          label: l10n.locationApproximateLabel,
          value: l10n.locationApproximateValue,
        ),
        _primary(
          key: mapPreviewKey,
          label: l10n.locationOpenGoogleMapsAction,
          icon: Icons.map_outlined,
          onPressed: () => context.push(AppRoutes.mapPreview),
        ),
        _secondary(
          key: refreshKey,
          label: l10n.locationRefreshAction,
          icon: Icons.refresh,
          onPressed: state.isProcessing ? null : controller.retry,
        ),
      ],
      LocationViewStatus.weakAccuracy => [
        P27Banner(
          title: l10n.locationWeakAccuracyTitle,
          message: locationAccuracyChipLabel(
            l10n,
            state.accuracy,
            state.accuracyMeters,
          ),
          tone: P27BannerTone.warning,
        ),
        const P27FakeMap(height: 300),
        P27Banner(
          title: l10n.locationWeakAccuracyTitle,
          message: l10n.locationWeakAccuracyMessage,
          tone: P27BannerTone.warning,
        ),
        _primary(
          key: refreshKey,
          label: l10n.locationRelocateAction,
          icon: Icons.my_location,
          onPressed: state.isProcessing ? null : controller.retry,
        ),
        _secondary(
          key: mapPreviewKey,
          label: l10n.locationContinueWithoutNavigationAction,
          onPressed: () => context.push(AppRoutes.mapPreview),
        ),
      ],
      LocationViewStatus.stale => [
        P27Banner(
          title: l10n.locationStaleTitle,
          message: l10n.locationStaleMessage,
          tone: P27BannerTone.warning,
        ),
        const P27FakeMap(height: 300),
        _primary(
          key: refreshKey,
          label: l10n.locationRelocateAction,
          icon: Icons.my_location,
          onPressed: state.isProcessing ? null : controller.retry,
        ),
      ],
      LocationViewStatus.unavailable => [
        P27Banner(
          title: l10n.locationGnssUnavailableTitle,
          message: l10n.locationGnssUnavailableMessage,
          tone: P27BannerTone.warning,
        ),
        const P27Skeleton(height: 430),
        _primary(
          key: blockedRetryKey,
          label: l10n.profileRetry,
          icon: Icons.refresh,
          onPressed: state.isProcessing ? null : controller.retry,
        ),
      ],
      LocationViewStatus.offline => [
        P27Banner(
          title: l10n.locationOfflineTitle,
          message: l10n.locationOfflineMessage,
          tone: P27BannerTone.warning,
        ),
        const P27Skeleton(height: 430),
        _primary(
          key: blockedRetryKey,
          label: l10n.profileRetry,
          icon: Icons.refresh,
          onPressed: state.isProcessing ? null : controller.retry,
        ),
      ],
    };
  }

  Widget _primary({
    Key? key,
    required String label,
    IconData? icon,
    VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      height: 56,
      child: SaeqPrimaryButton(
        key: key,
        label: label,
        icon: icon,
        onPressed: onPressed,
        isLoading: loading,
      ),
    );
  }

  Widget _secondary({
    Key? key,
    required String label,
    IconData? icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: SaeqSecondaryButton(
        key: key,
        label: label,
        icon: icon,
        onPressed: onPressed,
      ),
    );
  }
}
