import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/saeq_destructive_dialog.dart';
import '../../../../shared/widgets/saeq_empty_state.dart';
import '../../../../shared/widgets/saeq_error_state.dart';
import '../../../../shared/widgets/saeq_info_card.dart';
import '../../../../shared/widgets/saeq_loading_skeleton.dart';
import '../../../../shared/widgets/saeq_profile_header.dart';
import '../../../../shared/widgets/saeq_profile_navigation_row.dart';
import '../../../auth/domain/entities/auth_error.dart';
import '../../../auth/domain/entities/driver_session.dart';
import '../../../auth/presentation/controllers/auth_controller_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../availability/presentation/providers/availability_providers.dart';
import '../../domain/entities/profile_error.dart';
import '../controllers/profile_controller_state.dart';
import '../providers/profile_providers.dart';

/// Driver profile screen with vehicle/documents navigation (STEP 2A).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const editRowKey = Key('profileEditRow');
  static const vehicleRowKey = Key('profileVehicleRow');
  static const documentsRowKey = Key('profileDocumentsRow');
  static const locationRowKey = Key('profileLocationRow');
  static const settingsRowKey = Key('profileSettingsRow');
  static const supportRowKey = Key('profileSupportRow');
  static const safetyRowKey = Key('profileSafetyRow');
  static const signOutRowKey = Key('profileSignOutRow');

  static String _maskedPhone(String phoneNumber) {
    return DriverSession(
      driverId: 'mask',
      phoneNumber: phoneNumber,
      sessionToken: 'mask',
    ).maskedPhoneNumber;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: _buildBody(context, ref, l10n, state),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ProfileControllerState state,
  ) {
    switch (state.status) {
      case ProfileViewStatus.initial:
      case ProfileViewStatus.loading:
        return SaeqLoadingSkeleton(title: l10n.loading);

      case ProfileViewStatus.empty:
        return SaeqEmptyState(
          title: l10n.profileEmptyTitle,
          message: l10n.profileEmptyMessage,
          icon: Icons.person_outline,
          actionLabel: l10n.profileRetry,
          onAction: () => ref.read(profileControllerProvider.notifier).retry(),
        );

      case ProfileViewStatus.sessionExpired:
        return SaeqErrorState(
          title: l10n.profileSessionExpiredTitle,
          message: l10n.sessionExpiredMessage,
          retryLabel: l10n.signOut,
          onRetry: () => ref.read(authControllerProvider.notifier).signOut(),
        );

      case ProfileViewStatus.error:
        return SaeqErrorState(
          title: l10n.profileErrorTitle,
          message: _mapError(l10n, state.error),
          retryLabel: l10n.profileRetry,
          onRetry: () => ref.read(profileControllerProvider.notifier).retry(),
        );

      case ProfileViewStatus.success:
        final profile = state.profile!;

        return ListView(
          children: [
            SaeqInfoCard(
              child: SaeqProfileHeader(
                fullName: profile.fullName,
                maskedPhone: _maskedPhone(profile.phoneNumber),
                email: profile.email,
              ),
            ),
            if (state.compliance != null) ...[
              const SizedBox(height: AppTheme.spacingSM),
              SaeqInfoCard(
                child: Text(
                  key: const Key('profileComplianceStatus'),
                  state.compliance!.overallStatus,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingSM),
            SaeqProfileNavigationRow(
              key: editRowKey,
              label: l10n.profileEditAction,
              onTap: () => context.push(AppRoutes.profileEdit),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            SaeqProfileNavigationRow(
              key: vehicleRowKey,
              label: l10n.profileMenuVehicle,
              onTap: () => context.push(AppRoutes.profileVehicle),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            SaeqProfileNavigationRow(
              key: documentsRowKey,
              label: l10n.profileMenuDocuments,
              onTap: () => context.push(AppRoutes.profileDocuments),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            SaeqProfileNavigationRow(
              key: locationRowKey,
              label: l10n.locationTitle,
              onTap: () => context.push(AppRoutes.location),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            SaeqProfileNavigationRow(
              key: settingsRowKey,
              label: l10n.profileOpenSettings,
              onTap: () => context.push(AppRoutes.settings),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            SaeqProfileNavigationRow(
              key: supportRowKey,
              label: l10n.profileOpenSupport,
              onTap: () => context.push(AppRoutes.support),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            SaeqProfileNavigationRow(
              key: safetyRowKey,
              label: l10n.profileMenuSafety,
              onTap: () => context.push(AppRoutes.supportSafety),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            SaeqProfileNavigationRow(
              key: signOutRowKey,
              label: l10n.signOut,
              destructive: true,
              onTap: () => _confirmSignOut(context, ref, l10n),
            ),
          ],
        );
    }
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await SaeqDestructiveDialog.show(
      context,
      title: l10n.signOutConfirmTitle,
      message: l10n.signOutConfirmMessage,
      confirmLabel: l10n.signOut,
      cancelLabel: l10n.cancelAction,
    );
    if (confirmed == true) {
      await ref
          .read(availabilityControllerProvider.notifier)
          .prepareForLogout();
      await ref.read(authControllerProvider.notifier).signOut();
      if (!context.mounted) return;
      final authState = ref.read(authControllerProvider);
      if (authState.status == AuthControllerStatus.failure &&
          authState.error is SecureStorageFailureError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.secureStorageFailureMessage)),
        );
      }
    }
  }

  String _mapError(AppLocalizations l10n, ProfileError? error) {
    return switch (error) {
      ProfileUnauthenticatedError() => l10n.profileUnauthenticatedMessage,
      ProfileForbiddenError() => l10n.profileForbiddenMessage,
      ProfileInvalidDataError() => l10n.profileInvalidDataMessage,
      ProfileSovereignFieldMutationError() =>
        l10n.profileSovereignMutationMessage,
      _ => l10n.profileUnexpectedMessage,
    };
  }
}
