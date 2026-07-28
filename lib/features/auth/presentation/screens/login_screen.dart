import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../domain/entities/auth_error.dart';
import '../../domain/saudi_phone_normalizer.dart';
import '../controllers/auth_controller_state.dart';
import '../providers/auth_providers.dart';

/// Figma `Final/Auth/Phone *` states (nodes 40:15 … 40:55, 40:293, 48:1989).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocus = FocusNode();
  bool _showFieldError = false;

  @override
  void initState() {
    super.initState();
    _phoneFocus.addListener(() => setState(() {}));
    _phoneController.addListener(() {
      if (_showFieldError) setState(() => _showFieldError = false);
      final authState = ref.read(authControllerProvider);
      if (authState.error != null) {
        ref.read(authControllerProvider.notifier).clearError();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _submit(bool isBusy) async {
    if (isBusy) return;
    final valid = _formKey.currentState?.validate() == true;
    setState(() => _showFieldError = !valid);
    if (!valid) return;
    final phone = normalizeSaudiPhoneNumber(_phoneController.text);
    if (phone == null) {
      setState(() => _showFieldError = true);
      return;
    }
    await ref.read(authControllerProvider.notifier).requestOtp(phone);
  }

  String? _validatePhoneNumber(String? value, AppLocalizations l10n) {
    if (!isValidSaudiPhoneInput(value ?? '')) {
      return l10n.invalidPhoneNumberMessage;
    }
    return null;
  }

  String? _inlineMessageFor(AuthError? error, AppLocalizations l10n) {
    return switch (error) {
      null => null,
      InvalidPhoneNumberError() => l10n.invalidPhoneNumberMessage,
      AuthenticationRejectedError() => l10n.authenticationRejectedMessage,
      SessionExpiredError() => l10n.sessionExpiredMessage,
      CorruptedSessionError() => l10n.corruptedSessionMessage,
      InvalidOtpError() => l10n.invalidOtpMessage,
      ExpiredOtpError() => l10n.expiredOtpMessage,
      IncompleteOtpError() => l10n.incompleteOtpMessage,
      // Full-screen states handled separately.
      SecureStorageFailureError() ||
      OtpRateLimitedError() ||
      UnexpectedAuthError() => null,
    };
  }

  ({String title, String message})? _blockingFailure(
    AuthError? error,
    AppLocalizations l10n,
  ) {
    return switch (error) {
      SecureStorageFailureError() => (
        title: l10n.secureStorageFailureTitle,
        message: l10n.secureStorageFailureMessage,
      ),
      OtpRateLimitedError() => (
        title: l10n.rateLimitTitle,
        message: l10n.otpRateLimitedMessage,
      ),
      // Fake Alpha has no dedicated network error; Unexpected maps to
      // Final/Auth/Network Failure for presentation only.
      UnexpectedAuthError() => (
        title: l10n.networkFailureTitle,
        message: l10n.networkFailureMessage,
      ),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);
    final state = ref.watch(authControllerProvider);
    final isBusy = state.isBusy;
    final blocking = _blockingFailure(state.error, l10n);
    final errorMessage = _inlineMessageFor(state.error, l10n);
    final isRequestingOtp = state.status == AuthControllerStatus.requestingOtp;
    final fieldError =
        _showFieldError || errorMessage == l10n.invalidPhoneNumberMessage;
    final focused = _phoneFocus.hasFocus;

    ref.listen<AuthControllerState>(authControllerProvider, (previous, next) {
      if (next.status == AuthControllerStatus.otpRequested &&
          next.pendingPhone != null) {
        final router = GoRouter.maybeOf(context);
        if (router == null) return;
        final phone = Uri.encodeComponent(next.pendingPhone!);
        router.go('${AppRoutes.loginOtp}?phone=$phone');
      }
      if (next.error is SessionExpiredError) {
        final router = GoRouter.maybeOf(context);
        if (router == null) return;
        ref.read(authControllerProvider.notifier).clearError();
        router.go(AppRoutes.sessionExpired);
      }
    });

    if (blocking != null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  blocking.title,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: colors.textPrimary,
                    fontSize: AppTheme.fontSizeXXL,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  blocking.message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    fontSize: AppTheme.fontSizeSM,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                SaeqPrimaryButton(
                  key: const Key('loginRetryAction'),
                  label: l10n.authRetryAction,
                  onPressed: isBusy
                      ? null
                      : () {
                          ref
                              .read(authControllerProvider.notifier)
                              .clearError();
                        },
                ),
                if (state.error is UnexpectedAuthError) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  TextButton(
                    key: const Key('loginNetworkBack'),
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).clearError();
                      context.go(AppRoutes.login);
                    },
                    child: Text(l10n.backAction),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final borderColor = fieldError
        ? colors.error
        : focused
        ? colors.primary
        : colors.border;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    key: const Key('loginBack'),
                    onPressed: isBusy
                        ? null
                        : () => context.go(AppRoutes.onboarding),
                    child: Text(l10n.backAction),
                  ),
                ),
                Text(
                  l10n.loginTitle,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: colors.textPrimary,
                    fontSize: AppTheme.fontSizeXXL,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
                if (!fieldError) ...[
                  const SizedBox(height: AppTheme.spacing12),
                  Text(
                    l10n.loginSubtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textSecondary,
                      fontSize: AppTheme.fontSizeSM,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  l10n.phoneNumberLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: fieldError ? colors.error : colors.textPrimary,
                    fontSize: AppTheme.fontSizeSM,
                    fontWeight: AppTheme.fontWeightMedium,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  enabled: !isBusy,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: fieldError ? colors.error : colors.textPrimary,
                    fontWeight: fieldError
                        ? AppTheme.fontWeightMedium
                        : AppTheme.fontWeightRegular,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.phoneNumberHint,
                    hintStyle: AppTextStyles.bodyLarge.copyWith(
                      color: colors.textSecondary,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? colors.elevatedSurface
                        : colors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMD,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      borderSide: BorderSide(
                        color: borderColor,
                        width: fieldError || focused
                            ? AppTheme.borderWidthMedium
                            : AppTheme.borderWidthThin,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      borderSide: BorderSide(
                        color: borderColor,
                        width: AppTheme.borderWidthMedium,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      borderSide: BorderSide(
                        color: colors.error,
                        width: AppTheme.borderWidthMedium,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      borderSide: BorderSide(
                        color: colors.error,
                        width: AppTheme.borderWidthMedium,
                      ),
                    ),
                    errorStyle: AppTextStyles.label.copyWith(
                      color: colors.error,
                      fontSize: AppTheme.fontSizeXS,
                      fontWeight: AppTheme.fontWeightRegular,
                    ),
                  ),
                  validator: (value) => _validatePhoneNumber(value, l10n),
                  onFieldSubmitted: (_) => _submit(isBusy),
                ),
                if (errorMessage != null &&
                    errorMessage != l10n.invalidPhoneNumberMessage) ...[
                  const SizedBox(height: AppTheme.spacingSM),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      errorMessage,
                      key: const Key('loginErrorMessage'),
                      style: AppTextStyles.label.copyWith(
                        color: colors.error,
                        fontSize: AppTheme.fontSizeXS,
                        fontWeight: AppTheme.fontWeightRegular,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingLG),
                SaeqPrimaryButton(
                  key: const Key('loginSubmit'),
                  label: isBusy ? l10n.loadingEllipsis : l10n.otpRequestAction,
                  isLoading: isRequestingOtp,
                  onPressed: isBusy ? null : () => _submit(isBusy),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
