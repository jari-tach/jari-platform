import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/saeq_empty_state.dart';
import '../../../shared/widgets/saeq_error_state.dart';
import '../../../shared/widgets/saeq_info_card.dart';
import '../../../shared/widgets/saeq_loading_skeleton.dart';
import '../../../shared/widgets/saeq_primary_button.dart';
import '../../../shared/widgets/saeq_status_chip.dart';
import 'vehicle_feature.dart';

class VehicleOverviewScreen extends ConsumerWidget {
  const VehicleOverviewScreen({super.key});

  static const editKey = Key('vehicleEditAction');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(vehicleControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: _body(context, ref, l10n, state),
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    VehicleState state,
  ) {
    switch (state.status) {
      case VehicleViewStatus.loading:
        return SaeqLoadingSkeleton(
          title: l10n.vehicleLoadingTitle,
          message: l10n.vehicleLoadingMessage,
        );
      case VehicleViewStatus.empty:
        return SaeqEmptyState(
          title: l10n.vehicleEmptyTitle,
          message: l10n.vehicleEmptyMessage,
          icon: Icons.directions_car_outlined,
          actionLabel: l10n.vehicleAddAction,
          actionIcon: Icons.add,
          onAction: () => context.push(AppRoutes.profileVehicleEdit),
        );
      case VehicleViewStatus.offline:
        return SaeqErrorState(
          title: l10n.vehicleOfflineTitle,
          message: l10n.vehicleOfflineMessage,
          retryLabel: l10n.profileRetry,
          onRetry: ref.read(vehicleControllerProvider.notifier).load,
        );
      case VehicleViewStatus.error:
        return SaeqErrorState(
          title: l10n.vehicleErrorTitle,
          message: l10n.vehicleErrorMessage,
          retryLabel: l10n.profileRetry,
          onRetry: ref.read(vehicleControllerProvider.notifier).load,
        );
      case VehicleViewStatus.loaded:
      case VehicleViewStatus.editing:
      case VehicleViewStatus.saving:
      case VehicleViewStatus.saveSuccess:
      case VehicleViewStatus.validationError:
        final vehicle = state.vehicle;
        if (vehicle == null) {
          return SaeqEmptyState(
            title: l10n.vehicleEmptyTitle,
            message: l10n.vehicleEmptyMessage,
            icon: Icons.directions_car_outlined,
          );
        }
        return ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            SaeqInfoCard(
              title: '${vehicle.make} ${vehicle.model}',
              subtitle: l10n.vehicleTypeValue(vehicle.vehicleType),
              leading: const Icon(Icons.directions_car_outlined),
              trailing: SaeqStatusChip(
                label: _statusLabel(l10n, vehicle.approvalStatus),
                tone: _statusTone(vehicle.approvalStatus),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            SaeqInfoCard(
              child: Column(
                children: [
                  _VehicleField(
                    label: l10n.vehicleMakeLabel,
                    value: vehicle.make,
                  ),
                  _VehicleField(
                    label: l10n.vehicleModelLabel,
                    value: vehicle.model,
                  ),
                  _VehicleField(
                    label: l10n.vehicleYearLabel,
                    value: vehicle.year.toString(),
                  ),
                  _VehicleField(
                    label: l10n.vehicleColorLabel,
                    value: vehicle.color,
                  ),
                  _VehicleField(
                    label: l10n.vehiclePlateLabel,
                    value: _maskedPlate(vehicle.plate),
                  ),
                  _VehicleField(
                    label: l10n.vehicleTypeLabel,
                    value: vehicle.vehicleType,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            SaeqPrimaryButton(
              key: editKey,
              label: l10n.vehicleEditAction,
              icon: Icons.edit_outlined,
              onPressed: () => context.push(AppRoutes.profileVehicleEdit),
            ),
          ],
        );
    }
  }

  static String _maskedPlate(String plate) {
    final compact = plate.replaceAll(' ', '');
    if (compact.length <= 2) return '••';
    return '${'•' * (compact.length - 2)}${compact.substring(compact.length - 2)}';
  }

  static String _statusLabel(
    AppLocalizations l10n,
    VehicleApprovalStatus status,
  ) {
    return switch (status) {
      VehicleApprovalStatus.approved => l10n.statusApproved,
      VehicleApprovalStatus.underReview => l10n.statusUnderReview,
      VehicleApprovalStatus.rejected => l10n.statusRejected,
    };
  }

  static SaeqStatusTone _statusTone(VehicleApprovalStatus status) {
    return switch (status) {
      VehicleApprovalStatus.approved => SaeqStatusTone.success,
      VehicleApprovalStatus.underReview => SaeqStatusTone.warning,
      VehicleApprovalStatus.rejected => SaeqStatusTone.danger,
    };
  }
}

class _VehicleField extends StatelessWidget {
  const _VehicleField({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppTheme.spacingMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: AppTheme.spacingMD),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
