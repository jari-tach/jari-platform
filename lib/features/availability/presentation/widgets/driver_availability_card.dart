import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../domain/entities/availability_status.dart';
import '../../domain/entities/driver_availability.dart';
import '../controllers/availability_controller.dart';
import '../controllers/availability_controller_state.dart';
import '../mappers/availability_failure_messages.dart';
import '../providers/availability_providers.dart';

/// High-visibility availability status card (PHASE 2.4 Increment 5).
///
/// Passive view over [availabilityControllerProvider]. Does not construct
/// eligibility input, call repositories, or invent confirmation.
class DriverAvailabilityCard extends ConsumerWidget {
  const DriverAvailabilityCard({super.key});

  static const statusLabelKey = Key('availabilityStatusLabel');
  static const statusDetailKey = Key('availabilityStatusDetail');
  static const statusChipKey = Key('availabilityStatusChip');
  static const primaryActionKey = Key('availabilityPrimaryAction');
  static const failureBannerKey = Key('availabilityFailureBanner');
  static const dismissFailureKey = Key('availabilityDismissFailure');
  static const retryKey = Key('availabilityRetry');
  static const progressKey = Key('availabilityProgress');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(availabilityControllerProvider);
    final controller = ref.read(availabilityControllerProvider.notifier);
    final presentation = _AvailabilityPresentation.from(state, l10n);

    return Semantics(
      container: true,
      label: l10n.availabilitySemanticsStatus,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.availabilitySectionTitle,
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSM),
            if (presentation.showProgress) ...[
              Semantics(
                label: l10n.availabilitySemanticsProgress,
                child: const LinearProgressIndicator(
                  key: progressKey,
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSM),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  presentation.icon,
                  color: presentation.accent,
                  semanticLabel: presentation.title,
                ),
                const SizedBox(width: AppTheme.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        presentation.title,
                        key: statusLabelKey,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: presentation.accent,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        presentation.detail,
                        key: statusDetailKey,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (presentation.chipLabel != null) ...[
              const SizedBox(height: AppTheme.spacingSM),
              _StatusChip(
                key: statusChipKey,
                label: presentation.chipLabel!,
                tone: presentation.chipTone,
              ),
            ],
            if (state.failure != null) ...[
              const SizedBox(height: AppTheme.spacingMD),
              _FailureBanner(
                key: failureBannerKey,
                message: availabilityFailureMessage(state.failure!, l10n),
                semanticsLabel: l10n.availabilitySemanticsFailure,
                onDismiss: () => controller.clearFailure(),
                dismissLabel: l10n.availabilityActionDismissFailure,
                dismissKey: dismissFailureKey,
              ),
            ],
            const SizedBox(height: AppTheme.spacingMD),
            if (presentation.showRetry)
              SaeqPrimaryButton(
                key: retryKey,
                label: l10n.availabilityActionRetry,
                icon: Icons.refresh,
                onPressed: presentation.actionsEnabled
                    ? () => controller.initialize()
                    : null,
              )
            else
              Semantics(
                button: true,
                enabled: presentation.primaryEnabled,
                label: l10n.availabilitySemanticsAction,
                child: SaeqPrimaryButton(
                  key: primaryActionKey,
                  label: presentation.primaryLabel,
                  icon: presentation.primaryIcon,
                  onPressed: presentation.primaryEnabled
                      ? () => _onPrimaryPressed(controller, presentation)
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _onPrimaryPressed(
    AvailabilityController controller,
    _AvailabilityPresentation presentation,
  ) {
    switch (presentation.primaryAction) {
      case _PrimaryAction.goAvailable:
        // Never pass fabricated eligibility from UI.
        controller.requestAvailable();
      case _PrimaryAction.goUnavailable:
        controller.requestUnavailable();
      case _PrimaryAction.none:
        break;
    }
  }
}

enum _PrimaryAction { none, goAvailable, goUnavailable }

enum _ChipTone { confirmed, pending, restored, busy, offline, neutral }

class _AvailabilityPresentation {
  const _AvailabilityPresentation({
    required this.title,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.primaryAction,
    required this.primaryEnabled,
    required this.actionsEnabled,
    required this.showProgress,
    required this.showRetry,
    this.chipLabel,
    this.chipTone = _ChipTone.neutral,
  });

  final String title;
  final String detail;
  final IconData icon;
  final Color accent;
  final String primaryLabel;
  final IconData primaryIcon;
  final _PrimaryAction primaryAction;
  final bool primaryEnabled;
  final bool actionsEnabled;
  final bool showProgress;
  final bool showRetry;
  final String? chipLabel;
  final _ChipTone chipTone;

  factory _AvailabilityPresentation.from(
    AvailabilityControllerState state,
    AppLocalizations l10n,
  ) {
    final showProgress =
        state.status == AvailabilityViewStatus.loading || state.isProcessing;
    final actionsEnabled = !showProgress;

    if (state.status == AvailabilityViewStatus.loading &&
        state.current == null) {
      return _AvailabilityPresentation(
        title: l10n.availabilityStatusLoading,
        detail: l10n.availabilityStatusLoadingDetail,
        icon: Icons.hourglass_top,
        accent: AppColors.secondary,
        primaryLabel: l10n.availabilityActionGoAvailable,
        primaryIcon: Icons.play_arrow,
        primaryAction: _PrimaryAction.none,
        primaryEnabled: false,
        actionsEnabled: false,
        showProgress: true,
        showRetry: false,
      );
    }

    if (!state.isInitialized || state.current == null) {
      final canRetry =
          state.status == AvailabilityViewStatus.failure && !showProgress;
      return _AvailabilityPresentation(
        title: l10n.availabilityStatusInitial,
        detail: l10n.availabilityStatusInitialDetail,
        icon: Icons.lock_outline,
        accent: AppColors.secondary,
        primaryLabel: l10n.availabilityActionGoAvailable,
        primaryIcon: Icons.play_arrow,
        primaryAction: _PrimaryAction.none,
        primaryEnabled: false,
        actionsEnabled: actionsEnabled,
        showProgress: showProgress,
        showRetry: canRetry,
      );
    }

    final current = state.current!;
    final restoredBusy = _isRestoredBusy(state, current);

    if (state.isBusy || restoredBusy) {
      return _AvailabilityPresentation(
        title: restoredBusy
            ? l10n.availabilityStatusRestoredBusy
            : l10n.availabilityStatusBusy,
        detail: restoredBusy
            ? l10n.availabilityStatusRestoredBusyDetail
            : l10n.availabilityStatusBusyDetail,
        icon: Icons.local_shipping_outlined,
        accent: const Color(0xFFE65100),
        primaryLabel: l10n.availabilityActionGoUnavailable,
        primaryIcon: Icons.stop,
        primaryAction: _PrimaryAction.none,
        primaryEnabled: false,
        actionsEnabled: false,
        showProgress: showProgress,
        showRetry: false,
        chipLabel: restoredBusy
            ? l10n.availabilityChipRestored
            : l10n.availabilityChipBusy,
        chipTone: restoredBusy ? _ChipTone.restored : _ChipTone.busy,
      );
    }

    if (state.isOffline) {
      return _AvailabilityPresentation(
        title: l10n.availabilityStatusOffline,
        detail: l10n.availabilityStatusOfflineDetail,
        icon: Icons.wifi_off,
        accent: AppColors.error,
        primaryLabel: l10n.availabilityActionGoAvailable,
        primaryIcon: Icons.play_arrow,
        primaryAction: _PrimaryAction.none,
        primaryEnabled: false,
        actionsEnabled: false,
        showProgress: showProgress,
        showRetry: false,
        chipLabel: l10n.availabilityChipOffline,
        chipTone: _ChipTone.offline,
      );
    }

    if (state.isRestoredUnconfirmedAvailable) {
      return _AvailabilityPresentation(
        title: l10n.availabilityStatusRestoredAvailable,
        detail: l10n.availabilityStatusRestoredAvailableDetail,
        icon: Icons.restore,
        accent: const Color(0xFFF9A825),
        primaryLabel: l10n.availabilityActionGoUnavailable,
        primaryIcon: Icons.stop,
        primaryAction: _PrimaryAction.goUnavailable,
        primaryEnabled: state.canRequestUnavailable && actionsEnabled,
        actionsEnabled: actionsEnabled,
        showProgress: showProgress,
        showRetry: false,
        chipLabel: l10n.availabilityChipRestored,
        chipTone: _ChipTone.restored,
      );
    }

    if (state.isConfirmedAvailable) {
      return _AvailabilityPresentation(
        title: l10n.availabilityStatusConfirmedAvailable,
        detail: l10n.availabilityStatusConfirmedAvailableDetail,
        icon: Icons.check_circle_outline,
        accent: AppColors.primary,
        primaryLabel: l10n.availabilityActionGoUnavailable,
        primaryIcon: Icons.stop,
        primaryAction: _PrimaryAction.goUnavailable,
        primaryEnabled: state.canRequestUnavailable && actionsEnabled,
        actionsEnabled: actionsEnabled,
        showProgress: showProgress,
        showRetry: false,
        chipLabel: l10n.availabilityChipConfirmed,
        chipTone: _ChipTone.confirmed,
      );
    }

    if (current.status == AvailabilityStatus.available ||
        state.isPendingConfirmation) {
      return _AvailabilityPresentation(
        title: l10n.availabilityStatusPendingAvailable,
        detail: l10n.availabilityStatusPendingAvailableDetail,
        icon: Icons.pending_outlined,
        accent: const Color(0xFFF9A825),
        primaryLabel: l10n.availabilityActionGoUnavailable,
        primaryIcon: Icons.stop,
        primaryAction: _PrimaryAction.goUnavailable,
        primaryEnabled: state.canRequestUnavailable && actionsEnabled,
        actionsEnabled: actionsEnabled,
        showProgress: showProgress,
        showRetry: false,
        chipLabel: l10n.availabilityChipPending,
        chipTone: _ChipTone.pending,
      );
    }

    // Unavailable (and processing overlay keeps this stable view).
    final processingTitle = state.isProcessing
        ? l10n.availabilityStatusProcessing
        : l10n.availabilityStatusUnavailable;
    return _AvailabilityPresentation(
      title: processingTitle,
      detail: l10n.availabilityStatusUnavailableDetail,
      icon: Icons.pause_circle_outline,
      accent: AppColors.secondary,
      primaryLabel: l10n.availabilityActionGoAvailable,
      primaryIcon: Icons.play_arrow,
      primaryAction: _PrimaryAction.goAvailable,
      primaryEnabled: state.canRequestAvailable && actionsEnabled,
      actionsEnabled: actionsEnabled,
      showProgress: showProgress,
      showRetry: false,
    );
  }

  static bool _isRestoredBusy(
    AvailabilityControllerState state,
    DriverAvailability current,
  ) {
    // Local restore marks busy with pendingSync; authoritative busy clears it.
    // Do not use state.isRestored alone — it remains true after initialization.
    return current.status == AvailabilityStatus.busy && current.pendingSync;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({super.key, required this.label, required this.tone});

  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      _ChipTone.confirmed => (const Color(0xFFE8F5E9), AppColors.primary),
      _ChipTone.pending => (const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
      _ChipTone.restored => (const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      _ChipTone.busy => (const Color(0xFFFFF3E0), const Color(0xFFE65100)),
      _ChipTone.offline => (const Color(0xFFFFEBEE), AppColors.error),
      _ChipTone.neutral => (AppColors.surfaceVariant, AppColors.secondary),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSM,
          vertical: AppTheme.spacingXS,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({
    super.key,
    required this.message,
    required this.semanticsLabel,
    required this.onDismiss,
    required this.dismissLabel,
    required this.dismissKey,
  });

  final String message;
  final String semanticsLabel;
  final VoidCallback onDismiss;
  final String dismissLabel;
  final Key dismissKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticsLabel,
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
                key: dismissKey,
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
