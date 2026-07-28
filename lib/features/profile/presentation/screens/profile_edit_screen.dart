import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_info_card.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../domain/email_validator.dart';
import '../../domain/entities/driver_profile.dart';
import '../../domain/entities/driver_profile_update.dart';
import '../providers/profile_providers.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  static const saveKey = Key('profileEditSave');

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
  }

  void _seedFieldsOnce(DriverProfile profile) {
    if (_initialized) return;
    _fullNameController.text = profile.fullName;
    _emailController.text = profile.email ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    final profile = ref.read(profileControllerProvider).profile;
    if (profile == null) return;

    final fullName = _fullNameController.text.trim();
    final email = normalizeOptionalEmail(_emailController.text);

    final update = DriverProfileUpdate(
      fullName: fullName != profile.fullName ? fullName : null,
      email: email != profile.email ? email : null,
    );

    if (!update.hasChanges) {
      if (mounted) context.pop();
      return;
    }

    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(update);

    if (!mounted) return;

    final colors = SaeqSemanticColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? colors.success : colors.error,
        content: Text(
          success
              ? l10n.profileEditSuccessMessage
              : l10n.profileEditFailureMessage,
        ),
      ),
    );

    if (success && context.mounted && context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;
    if (profile != null) {
      _seedFieldsOnce(profile);
    }

    final isUpdating = state.isUpdating;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileEditTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SaeqInfoCard(
                  subtitle: l10n.profileEditHint,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        enabled: !isUpdating,
                        decoration: InputDecoration(
                          labelText: l10n.profileEditFullNameLabel,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.profileEditFullNameRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppTheme.spacingMD),
                      TextFormField(
                        controller: _emailController,
                        enabled: !isUpdating,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.profileEditEmailLabel,
                          hintText: l10n.profileEditEmailHint,
                        ),
                        validator: (value) => validateOptionalEmail(
                          value,
                          invalidMessage: l10n.profileEditEmailInvalid,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL),
                SaeqPrimaryButton(
                  key: ProfileEditScreen.saveKey,
                  label: l10n.profileEditSaveAction,
                  icon: Icons.save_outlined,
                  isLoading: isUpdating,
                  onPressed: isUpdating ? null : () => _save(l10n),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  l10n.profileEditHint,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
