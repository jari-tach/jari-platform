import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';

/// Countdown label for OTP resend with live second-by-second updates.
class SaeqResendTimer extends StatefulWidget {
  const SaeqResendTimer({
    super.key,
    required this.resendAvailableAt,
    required this.cooldownLabelBuilder,
    required this.resendLabel,
    this.onResend,
    this.isBusy = false,
  });

  final DateTime? resendAvailableAt;
  final String Function(int seconds) cooldownLabelBuilder;
  final String resendLabel;
  final VoidCallback? onResend;
  final bool isBusy;

  static const timerKey = Key('saeqResendTimer');
  static const actionKey = Key('saeqResendTimerAction');

  @override
  State<SaeqResendTimer> createState() => _SaeqResendTimerState();
}

class _SaeqResendTimerState extends State<SaeqResendTimer> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _syncRemainingFromDeadline();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant SaeqResendTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resendAvailableAt != widget.resendAvailableAt) {
      _syncRemainingFromDeadline();
      _startTimerIfNeeded();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncRemainingFromDeadline() {
    final availableAt = widget.resendAvailableAt;
    if (availableAt == null) {
      _secondsRemaining = 0;
      return;
    }
    final diff = availableAt.difference(DateTime.now());
    if (diff.isNegative) {
      _secondsRemaining = 0;
      return;
    }
    _secondsRemaining =
        diff.inSeconds + (diff.inMilliseconds.remainder(1000) > 0 ? 1 : 0);
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (_secondsRemaining <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        }
        if (_secondsRemaining <= 0) {
          _timer?.cancel();
          _timer = null;
        }
      });
    });
  }

  bool get _canResend =>
      !widget.isBusy && _secondsRemaining <= 0 && widget.onResend != null;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    final inCooldown = _secondsRemaining > 0;
    final label = inCooldown
        ? widget.cooldownLabelBuilder(_secondsRemaining)
        : widget.resendLabel;

    return Semantics(
      key: SaeqResendTimer.timerKey,
      liveRegion: inCooldown,
      label: label,
      button: !inCooldown,
      enabled: _canResend,
      child: SizedBox(
        width: double.infinity,
        height: AppTheme.minTouchTarget,
        child: inCooldown
            ? Center(
                child: Text(
                  label,
                  key: const Key('saeqResendCooldownText'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : TextButton(
                key: SaeqResendTimer.actionKey,
                onPressed: _canResend ? widget.onResend : null,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, AppTheme.minTouchTarget),
                  foregroundColor: colors.primary,
                  disabledForegroundColor: colors.disabled,
                ),
                child: Text(label),
              ),
      ),
    );
  }
}
