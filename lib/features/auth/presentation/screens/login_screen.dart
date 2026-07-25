import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../domain/entities/auth_error.dart';
import '../providers/auth_providers.dart';

/// Trial (PHASE 2.2) driver sign-in screen.
///
/// Minimal by design: phone number field, a Sign In button, a loading
/// state and an error message. No OTP screen, no registration, no
/// document upload — those are explicitly out of scope for this phase.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit(bool isBusy) {
    if (isBusy) return; // Belt-and-suspenders: controller also guards this.
    if (_formKey.currentState?.validate() != true) return;
    ref
        .read(authControllerProvider.notifier)
        .signIn(_phoneController.text.trim());
  }

  String? _validatePhoneNumber(String? value, AppLocalizations l10n) {
    final input = (value ?? '').trim();
    if (!RegExp(r'^05\d{8}$').hasMatch(input)) {
      return l10n.invalidPhoneNumberMessage;
    }
    return null;
  }

  String? _messageFor(AuthError? error, AppLocalizations l10n) {
    return switch (error) {
      null => null,
      InvalidPhoneNumberError() => l10n.invalidPhoneNumberMessage,
      AuthenticationRejectedError() => l10n.authenticationRejectedMessage,
      SessionExpiredError() => l10n.sessionExpiredMessage,
      CorruptedSessionError() => l10n.corruptedSessionMessage,
      SecureStorageFailureError() => l10n.secureStorageFailureMessage,
      UnexpectedAuthError() => l10n.unexpectedAuthErrorMessage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    final isBusy = state.isBusy;
    final errorMessage = _messageFor(state.error, l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.loginSubtitle, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneController,
                  enabled: !isBusy,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumberLabel,
                    hintText: l10n.phoneNumberHint,
                  ),
                  validator: (value) => _validatePhoneNumber(value, l10n),
                  onFieldSubmitted: (_) => _submit(isBusy),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage,
                    key: const Key('loginErrorMessage'),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 24),
                SaeqPrimaryButton(
                  label: isBusy ? '...' : l10n.signIn,
                  icon: Icons.login,
                  // `null` disables the button while a sign-in request is
                  // already in flight, preventing duplicate submissions.
                  onPressed: isBusy ? null : () => _submit(isBusy),
                ),
                if (isBusy) ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
