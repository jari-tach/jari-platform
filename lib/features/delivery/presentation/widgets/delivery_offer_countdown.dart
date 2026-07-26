import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';

/// Live countdown to [expiresAt]. Presentation-only; no domain policy.
class DeliveryOfferCountdown extends StatefulWidget {
  const DeliveryOfferCountdown({super.key, required this.expiresAt, this.now});

  final DateTime expiresAt;

  /// Injectable clock for tests; defaults to [DateTime.now].
  final DateTime Function()? now;

  static const countdownKey = Key('deliveryOfferCountdown');

  @override
  State<DeliveryOfferCountdown> createState() => _DeliveryOfferCountdownState();
}

class _DeliveryOfferCountdownState extends State<DeliveryOfferCountdown> {
  Timer? _timer;
  late Duration _remaining;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _remaining = _computeRemaining());
    });
  }

  @override
  void didUpdateWidget(covariant DeliveryOfferCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _remaining = _computeRemaining();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Duration _computeRemaining() {
    final delta = widget.expiresAt.difference(_now);
    return delta.isNegative ? Duration.zero : delta;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final expired = _remaining == Duration.zero;
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds.remainder(60);
    final value = expired
        ? l10n.deliveryOfferCountdownExpired
        : l10n.deliveryOfferCountdownValue(minutes, seconds);

    return Semantics(
      liveRegion: true,
      label: '${l10n.deliveryOfferCountdownLabel}: $value',
      child: Container(
        key: DeliveryOfferCountdown.countdownKey,
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacingSM),
        decoration: BoxDecoration(
          color: expired ? const Color(0xFFFFEBEE) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          border: Border.all(
            color: expired
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              expired ? Icons.timer_off_outlined : Icons.timer_outlined,
              color: expired ? AppColors.error : AppColors.secondary,
              semanticLabel: l10n.deliverySemanticsCountdown,
            ),
            const SizedBox(width: AppTheme.spacingSM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.deliveryOfferCountdownLabel,
                    style: AppTextStyles.bodyMedium,
                  ),
                  Text(
                    value,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: expired ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
