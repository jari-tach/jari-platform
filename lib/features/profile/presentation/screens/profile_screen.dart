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

import '../../../../shared/widgets/saeq_info_card.dart';

import '../../../../shared/widgets/saeq_loading_skeleton.dart';

import '../../../../shared/widgets/saeq_profile_header.dart';

import '../../../../shared/widgets/saeq_secondary_button.dart';

import '../../../../shared/widgets/saeq_status_chip.dart';

import '../../../auth/domain/entities/driver_session.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

import '../../domain/entities/driver_status.dart';

import '../../domain/entities/profile_error.dart';

import '../controllers/profile_controller_state.dart';

import '../providers/profile_providers.dart';

/// Driver profile screen (PHASE 2.3) — replaces the Profile placeholder.

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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

        final colors = SaeqSemanticColors.of(context);

        return ListView(
          children: [
            SaeqProfileHeader(
              fullName: profile.fullName,

              maskedPhone: _maskedPhone(profile.phoneNumber),

              email: profile.email,
            ),

            const SizedBox(height: AppTheme.spacingLG),

            SaeqInfoCard(
              title: l10n.profileAccountStatus,

              child: Wrap(
                spacing: AppTheme.spacingSM,

                runSpacing: AppTheme.spacingSM,

                children: [
                  SaeqStatusChip(
                    label: _accountStatusLabel(l10n, profile.accountStatus),

                    tone: _accountStatusTone(profile.accountStatus),
                  ),

                  SaeqStatusChip(
                    label: _employmentStatusLabel(
                      l10n,

                      profile.employmentStatus,
                    ),

                    tone: _employmentStatusTone(profile.employmentStatus),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingMD),

            SaeqInfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  _DetailRow(
                    label: l10n.profileBusinessId,

                    value: profile.businessId ?? l10n.profileScopeUnassigned,

                    colors: colors,
                  ),

                  const SizedBox(height: AppTheme.spacingSM),

                  _DetailRow(
                    label: l10n.profileBranchId,

                    value: profile.branchId ?? l10n.profileScopeUnassigned,

                    colors: colors,
                  ),

                  if (profile.vehicleType != null &&
                      profile.vehicleType!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingSM),

                    _DetailRow(
                      label: l10n.profileVehicleType,

                      value: profile.vehicleType!,

                      colors: colors,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingLG),

            SaeqSecondaryButton(
              label: l10n.profileEditAction,

              icon: Icons.edit_outlined,

              onPressed: () => context.push(AppRoutes.profileEdit),
            ),

            const SizedBox(height: AppTheme.spacingSM),

            SaeqSecondaryButton(
              label: l10n.profileOpenSettings,

              icon: Icons.settings_outlined,

              onPressed: () => context.push(AppRoutes.settings),
            ),

            const SizedBox(height: AppTheme.spacingSM),

            SaeqSecondaryButton(
              label: l10n.profileOpenSupport,

              icon: Icons.support_agent_outlined,

              onPressed: () => context.push(AppRoutes.support),
            ),
          ],
        );
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

  String _accountStatusLabel(AppLocalizations l10n, AccountStatus status) {
    return switch (status) {
      AccountStatus.pending => l10n.profileStatusPending,

      AccountStatus.verified => l10n.profileStatusVerified,

      AccountStatus.rejected => l10n.profileStatusRejected,

      AccountStatus.suspended => l10n.profileStatusSuspended,
    };
  }

  String _employmentStatusLabel(
    AppLocalizations l10n,

    EmploymentStatus status,
  ) {
    return switch (status) {
      EmploymentStatus.active => l10n.profileEmploymentActive,

      EmploymentStatus.inactive => l10n.profileEmploymentInactive,

      EmploymentStatus.onLeave => l10n.profileEmploymentOnLeave,

      EmploymentStatus.terminated => l10n.profileEmploymentTerminated,
    };
  }

  SaeqStatusTone _accountStatusTone(AccountStatus status) {
    return switch (status) {
      AccountStatus.verified => SaeqStatusTone.success,

      AccountStatus.pending => SaeqStatusTone.warning,

      AccountStatus.rejected => SaeqStatusTone.danger,

      AccountStatus.suspended => SaeqStatusTone.danger,
    };
  }

  SaeqStatusTone _employmentStatusTone(EmploymentStatus status) {
    return switch (status) {
      EmploymentStatus.active => SaeqStatusTone.success,

      EmploymentStatus.inactive => SaeqStatusTone.neutral,

      EmploymentStatus.onLeave => SaeqStatusTone.warning,

      EmploymentStatus.terminated => SaeqStatusTone.danger,
    };
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,

    required this.value,

    required this.colors,
  });

  final String label;

  final String value;

  final SaeqSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Expanded(
          flex: 2,

          child: Text(
            label,

            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),

        Expanded(
          flex: 3,

          child: Text(
            value,

            style: AppTextStyles.bodyLarge.copyWith(color: colors.textPrimary),
          ),
        ),
      ],
    );
  }
}
