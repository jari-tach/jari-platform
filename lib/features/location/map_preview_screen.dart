import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/routes/app_router.dart';
import '../../shared/widgets/saeq_primary_button.dart';
import '../../shared/widgets/saeq_secondary_button.dart';
import 'location_ui_helpers.dart';
import 'map_preview_feature.dart';

/// P27 Driver Completion map states (STEP 2B fake UI only).
class MapPreviewScreen extends ConsumerWidget {
  const MapPreviewScreen({super.key});

  static const loadingStatusKey = Key('mapPreviewLoadingStatus');
  static const mapSkeletonKey = Key('mapPreviewMapSkeleton');
  static const detailSkeletonKey = Key('mapPreviewDetailSkeleton');
  static const loadingActionKey = Key('mapPreviewLoadingAction');
  static const retryKey = Key('mapPreviewRetryAction');
  static const primaryActionKey = Key('mapPreviewPrimaryAction');
  static const secondaryActionKey = Key('mapPreviewSecondaryAction');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(mapPreviewControllerProvider);
    final controller = ref.read(mapPreviewControllerProvider.notifier);
    return Scaffold(
      body: P27Page(
        title: state.status == MapPreviewStatus.externalNavigationUnavailable
            ? l10n.mapPreviewExternalNavigationUnavailableTitle
            : l10n.mapPreviewTitle,
        onBack: () => leavePreview(context, controller),
        children: _content(context, l10n, state, controller),
      ),
    );
  }

  List<Widget> _content(
    BuildContext context,
    AppLocalizations l10n,
    MapPreviewState state,
    MapPreviewController controller,
  ) {
    return switch (state.status) {
      MapPreviewStatus.loading => [
        P27Banner(
          key: loadingStatusKey,
          title: l10n.mapPreviewLoadingTitle,
          message: l10n.mapPreviewLoadingMessage,
          tone: P27BannerTone.information,
        ),
        const KeyedSubtree(
          key: mapSkeletonKey,
          child: P27Skeleton(height: 300),
        ),
        const KeyedSubtree(
          key: detailSkeletonKey,
          child: P27Skeleton(height: 220),
        ),
        _primary(
          key: loadingActionKey,
          label: l10n.mapPreviewLoadingTitle,
          onPressed: null,
          loading: true,
        ),
      ],
      MapPreviewStatus.error => [
        P27Banner(
          title: l10n.mapPreviewErrorTitle,
          message: l10n.mapPreviewErrorMessage,
          tone: P27BannerTone.error,
        ),
        const P27Skeleton(height: 300),
        P27Field(
          label: l10n.mapPreviewAddressLabel,
          value: l10n.mapPreviewAddressValue,
        ),
        _primary(
          key: retryKey,
          label: l10n.profileRetry,
          icon: Icons.refresh,
          onPressed: state.isProcessing ? null : controller.retry,
        ),
        _secondary(
          key: secondaryActionKey,
          label: l10n.mapPreviewOpenAddressBrowserAction,
          icon: Icons.open_in_browser,
          onPressed: controller.openExternalNavigation,
        ),
      ],
      MapPreviewStatus.offline => [
        P27Banner(
          title: l10n.mapPreviewOfflineTitle,
          message: l10n.mapPreviewOfflineMessage,
          tone: P27BannerTone.warning,
        ),
        const P27FakeMap(height: 300),
        P27Field(
          label: l10n.mapPreviewLastKnownLocationLabel,
          value: l10n.mapPreviewLastKnownLocationValue,
        ),
        _primary(
          key: primaryActionKey,
          label: l10n.locationOpenGoogleMapsAction,
          icon: Icons.map_outlined,
          onPressed: controller.openExternalNavigation,
        ),
        _secondary(
          key: retryKey,
          label: l10n.mapPreviewRetryConnectedAction,
          icon: Icons.refresh,
          onPressed: state.isProcessing ? null : controller.retry,
        ),
      ],
      MapPreviewStatus.loadedPlaceholder => [
        P27Banner(
          title: l10n.locationAvailableTitle,
          message: l10n.locationAvailableMessage,
          tone: P27BannerTone.success,
        ),
        P27FakeMap(
          height: 300,
          snapshot: state.snapshot ?? FakeMapPreviewService.defaultSnapshot,
        ),
        P27Field(
          label: l10n.mapPreviewAddressLabel,
          value: l10n.mapPreviewAddressValue,
        ),
        _primary(
          key: primaryActionKey,
          label: l10n.locationOpenGoogleMapsAction,
          icon: Icons.navigation_outlined,
          onPressed: state.isProcessing
              ? null
              : controller.openExternalNavigation,
        ),
        _secondary(
          key: retryKey,
          label: l10n.locationRefreshAction,
          icon: Icons.refresh,
          onPressed: state.isProcessing ? null : controller.retry,
        ),
      ],
      MapPreviewStatus.externalNavigationUnavailable => [
        P27Banner(
          title: l10n.mapPreviewExternalNavigationUnavailableTitle,
          message: l10n.mapPreviewExternalNavigationUnavailableMessage,
          tone: P27BannerTone.error,
        ),
        P27Field(
          label: l10n.mapPreviewAddressLabel,
          value: l10n.mapPreviewAddressValue,
        ),
        P27Field(
          label: l10n.mapPreviewCoordinatesLabel,
          value: l10n.mapPreviewCoordinatesValue,
        ),
        const P27Skeleton(height: 300),
        _primary(
          key: primaryActionKey,
          label: l10n.mapPreviewBrowserRouteAction,
          icon: Icons.open_in_browser,
          onPressed: controller.dismissExternalNavigationNotice,
        ),
        _secondary(
          key: secondaryActionKey,
          label: l10n.mapPreviewCopyAddressAction,
          icon: Icons.copy_outlined,
          onPressed: controller.dismissExternalNavigationNotice,
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

  static void leavePreview(
    BuildContext context,
    MapPreviewController controller,
  ) {
    controller.dismissExternalNavigationNotice();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.location);
    }
  }
}
