import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/saeq_semantic_colors.dart';
import '../../../shared/widgets/saeq_primary_button.dart';
import 'vehicle_feature.dart';

class VehicleEditScreen extends ConsumerStatefulWidget {
  const VehicleEditScreen({super.key});

  static const saveKey = Key('vehicleSaveAction');

  @override
  ConsumerState<VehicleEditScreen> createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends ConsumerState<VehicleEditScreen> {
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _color = TextEditingController();
  final _plate = TextEditingController();
  final _type = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _color.dispose();
    _plate.dispose();
    _type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final state = ref.watch(vehicleControllerProvider);
    final vehicle = state.vehicle;
    if (!_initialized && vehicle != null) {
      _initialized = true;
      _make.text = vehicle.make;
      _model.text = vehicle.model;
      _year.text = vehicle.year.toString();
      _color.text = vehicle.color;
      _plate.text = vehicle.plate;
      _type.text = vehicle.vehicleType;
    }

    ref.listen(vehicleControllerProvider, (previous, next) {
      if (next.status == VehicleViewStatus.saveSuccess &&
          previous?.status != VehicleViewStatus.saveSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vehicleSaveSuccess)));
        if (context.canPop()) context.pop();
      }
    });

    final isSaving = state.status == VehicleViewStatus.saving;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.vehicleEditTitle)),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            AppConstants.contentPadding,
            AppConstants.contentPadding,
            AppConstants.contentPadding,
            MediaQuery.viewInsetsOf(context).bottom +
                AppConstants.contentPadding,
          ),
          children: [
            _field(l10n.vehicleMakeLabel, _make),
            _field(l10n.vehicleModelLabel, _model),
            _field(
              l10n.vehicleYearLabel,
              _year,
              keyboardType: TextInputType.number,
            ),
            _field(l10n.vehicleColorLabel, _color),
            _field(l10n.vehiclePlateLabel, _plate),
            _field(l10n.vehicleTypeLabel, _type),
            if (state.status == VehicleViewStatus.validationError)
              _Message(
                key: const Key('vehicleValidationError'),
                text: l10n.vehicleValidationMessage,
                color: colors.error,
              ),
            if (state.status == VehicleViewStatus.offline)
              _Message(text: l10n.vehicleOfflineMessage, color: colors.warning),
            if (state.status == VehicleViewStatus.error)
              _Message(text: l10n.vehicleSaveFailure, color: colors.error),
            const SizedBox(height: AppTheme.spacingSM),
            SaeqPrimaryButton(
              key: VehicleEditScreen.saveKey,
              label: isSaving
                  ? l10n.vehicleSavingAction
                  : l10n.vehicleSaveAction,
              isLoading: isSaving,
              onPressed: isSaving
                  ? null
                  : () => ref
                        .read(vehicleControllerProvider.notifier)
                        .save(
                          make: _make.text,
                          model: _model.text,
                          year: _year.text,
                          color: _color.text,
                          plate: _plate.text,
                          vehicleType: _type.text,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled:
            ref.watch(vehicleControllerProvider).status !=
            VehicleViewStatus.saving,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: Semantics(
        liveRegion: true,
        child: Text(text, style: TextStyle(color: color)),
      ),
    );
  }
}
