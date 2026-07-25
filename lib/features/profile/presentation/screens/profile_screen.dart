import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/driver_status.dart';
import '../../domain/entities/profile_error.dart';
import '../controllers/profile_controller_state.dart';
import '../providers/profile_providers.dart';

/// Driver profile screen (PHASE 2.3) — replaces the Profile placeholder.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

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
        return const Center(child: CircularProgressIndicator());
      case ProfileViewStatus.empty:
        return _MessageState(
          title: l10n.profileEmptyTitle,
          message: l10n.profileEmptyMessage,
          actionLabel: l10n.profileRetry,
          onAction: () => ref.read(profileControllerProvider.notifier).retry(),
        );
      case ProfileViewStatus.sessionExpired:
        return _MessageState(
          title: l10n.profileSessionExpiredTitle,
          message: l10n.sessionExpiredMessage,
          actionLabel: l10n.signOut,
          onAction: () => ref.read(authControllerProvider.notifier).signOut(),
        );
      case ProfileViewStatus.error:
        return _MessageState(
          title: l10n.profileErrorTitle,
          message: _mapError(l10n, state.error),
          actionLabel: l10n.profileRetry,
          onAction: () => ref.read(profileControllerProvider.notifier).retry(),
        );
      case ProfileViewStatus.success:
        final profile = state.profile!;
        return ListView(
          children: [
            Text(profile.fullName, style: AppTextStyles.headlineLarge),
            const SizedBox(height: 8),
            Text(profile.phoneNumber, style: AppTextStyles.bodyLarge),
            if (profile.email != null && profile.email!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(profile.email!, style: AppTextStyles.bodyMedium),
            ],
            const SizedBox(height: 20),
            _InfoRow(
              label: l10n.profileAccountStatus,
              value: _accountStatusLabel(l10n, profile.accountStatus),
            ),
            _InfoRow(
              label: l10n.profileEmploymentStatus,
              value: _employmentStatusLabel(l10n, profile.employmentStatus),
            ),
            _InfoRow(
              label: l10n.profileBusinessId,
              value: profile.businessId ?? l10n.profileScopeUnassigned,
            ),
            _InfoRow(
              label: l10n.profileBranchId,
              value: profile.branchId ?? l10n.profileScopeUnassigned,
            ),
            if (profile.vehicleType != null && profile.vehicleType!.isNotEmpty)
              _InfoRow(
                label: l10n.profileVehicleType,
                value: profile.vehicleType!,
              ),
            const SizedBox(height: 24),
            SaeqPrimaryButton(
              label: l10n.profileRetry,
              icon: Icons.refresh,
              onPressed: () =>
                  ref.read(profileControllerProvider.notifier).retry(),
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
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppTextStyles.bodyMedium),
          ),
          Expanded(flex: 3, child: Text(value, style: AppTextStyles.bodyLarge)),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: AppTextStyles.headlineLarge),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SaeqPrimaryButton(label: actionLabel, onPressed: onAction),
        ],
      ),
    );
  }
}
