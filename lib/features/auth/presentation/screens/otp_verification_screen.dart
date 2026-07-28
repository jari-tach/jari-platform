import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';
import '../../../../shared/widgets/saeq_otp_input.dart';
import '../../../../shared/widgets/saeq_primary_button.dart';
import '../../domain/entities/auth_error.dart';
import '../controllers/auth_controller_state.dart';
import '../providers/auth_providers.dart';

/// Figma `Final/Auth/OTP *` + resend / failure states (nodes 40:72 … 48:2024).
class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _codeController
      ..removeListener(_onCodeChanged)
      ..dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    final authState = ref.read(authControllerProvider);
    if (authState.error != null) {
      ref.read(authControllerProvider.notifier).clearError();
    }
    setState(() {});
  }

  void _goBackToLogin() {
    ref.read(authControllerProvider.notifier).clearOtpFlow();
    GoRouter.maybeOf(context)?.go(AppRoutes.login);
  }

  /// Figma Auth mask: `05•••678` (first 2 + ••• + last 3). Presentation only.
  String _figmaMaskedPhone(String phone) {
    if (phone.length < 5) return phone;
    return '${phone.substring(0, 2)}•••${phone.substring(phone.length - 3)}';
  }

  String get _effectivePhone {
    final fromState = ref.read(authControllerProvider).pendingPhone;
    if (fromState != null && fromState.isNotEmpty) return fromState;
    return widget.phoneNumber;
  }

  String get _maskedPhone {
    final phone = _effectivePhone;
    if (phone.isEmpty) return phone;
    return _figmaMaskedPhone(phone);
  }

  bool get _isCodeComplete => _codeController.text.trim().length == 6;

  int _secondsRemaining(DateTime? availableAt) {
    if (availableAt == null) return 0;
    final diff = availableAt.difference(DateTime.now());
    if (diff.isNegative) return 0;
    return diff.inSeconds + (diff.inMilliseconds.remainder(1000) > 0 ? 1 : 0);
  }

  String _formatMmSs(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _verify(bool isBusy) async {
    if (isBusy || !_isCodeComplete) return;
    await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(_codeController.text.trim());
  }

  Future<void> _resend(bool isBusy) async {
    if (isBusy) return;
    await ref.read(authControllerProvider.notifier).resendOtp();
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
      UnexpectedAuthError() => (
        title: l10n.networkFailureTitle,
        message: l10n.networkFailureMessage,
      ),
      _ => null,
    };
  }

  String? _statusSubtitle(AuthError? error, AppLocalizations l10n) {
    return switch (error) {
      InvalidOtpError() => l10n.invalidOtpMessage,
      ExpiredOtpError() => l10n.expiredOtpMessage,
      IncompleteOtpError() => l10n.incompleteOtpMessage,
      InvalidPhoneNumberError() => l10n.invalidPhoneNumberMessage,
      AuthenticationRejectedError() => l10n.authenticationRejectedMessage,
      SessionExpiredError() => l10n.sessionExpiredMessage,
      CorruptedSessionError() => l10n.corruptedSessionMessage,
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
    final statusError = _statusSubtitle(state.error, l10n);
    final hasInputError =
        state.error is InvalidOtpError || state.error is IncompleteOtpError;
    final isExpired = state.error is ExpiredOtpError;
    final secondsLeft = _secondsRemaining(state.resendAvailableAt);
    final inCooldown = secondsLeft > 0;
    final isVerifying = state.status == AuthControllerStatus.verifyingOtp;
    final canResend = !inCooldown && state.resendAvailableAt != null;

    ref.listen<AuthControllerState>(authControllerProvider, (previous, next) {
      if (next.isAuthenticated) {
        final router = GoRouter.maybeOf(context);
        router?.go(AppRoutes.home);
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
                  key: const Key('otpRetryAction'),
                  label: l10n.authRetryAction,
                  onPressed: isBusy
                      ? null
                      : () {
                          ref
                              .read(authControllerProvider.notifier)
                              .clearError();
                        },
                ),
                const SizedBox(height: AppTheme.spacing12),
                TextButton(
                  key: const Key('otpBlockingBack'),
                  onPressed: isBusy ? null : _goBackToLogin,
                  child: Text(l10n.changePhoneAction),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final subtitle =
        statusError ??
        (inCooldown
            ? l10n.otpResendCountdown(_formatMmSs(secondsLeft))
            : canResend
            ? l10n.otpResendReadyMessage
            : l10n.otpSentToMasked(_maskedPhone));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBackToLogin();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    key: const Key('otpChangePhone'),
                    onPressed: isBusy ? null : _goBackToLogin,
                    child: Text(l10n.changePhoneAction),
                  ),
                ),
                Text(
                  l10n.otpTitle,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: colors.textPrimary,
                    fontSize: AppTheme.fontSizeXXL,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    subtitle,
                    key: statusError != null
                        ? const Key('otpErrorMessage')
                        : const Key('otpSubtitleMessage'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      // Figma OTP status/error subtitles use secondary gray.
                      color: colors.textSecondary,
                      fontSize: AppTheme.fontSizeSM,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing12),
                SaeqOtpInput(
                  key: const Key('otpCodeField'),
                  controller: _codeController,
                  enabled: !isBusy,
                  hasError: hasInputError,
                  semanticsLabel: l10n.otpCodeLabel,
                  onCompleted: (_) {
                    if (!isExpired) _verify(isBusy);
                  },
                ),
                const SizedBox(height: AppTheme.spacingLG),
                if (isExpired || canResend) ...[
                  SizedBox(
                    height: AppTheme.minTouchTarget,
                    width: double.infinity,
                    child: TextButton(
                      key: const Key('otpResend'),
                      onPressed: isBusy ? null : () => _resend(isBusy),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                        textStyle: AppTextStyles.button.copyWith(
                          fontWeight: AppTheme.fontWeightBold,
                          fontSize: AppTheme.fontSizeMD,
                        ),
                      ),
                      child: Text(l10n.otpResendAction),
                    ),
                  ),
                  if (!isExpired) const SizedBox(height: AppTheme.spacing12),
                ],
                if (!isExpired)
                  SaeqPrimaryButton(
                    key: const Key('otpVerifySubmit'),
                    label: isVerifying
                        ? l10n.loadingEllipsis
                        : l10n.otpVerifyAction,
                    isLoading: isVerifying,
                    onPressed: isBusy || !_isCodeComplete
                        ? null
                        : () => _verify(isBusy),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
