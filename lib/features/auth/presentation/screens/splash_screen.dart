import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/saeq_semantic_colors.dart';

/// Cold-start splash — Figma `DRV-SYS-001-Splash`.
///
/// Auto-advances to Welcome after a short delay; tap also continues.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), _goWelcome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goWelcome() {
    if (_navigated || !mounted) return;
    _navigated = true;
    GoRouter.maybeOf(context)?.go(AppRoutes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = SaeqSemanticColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _goWelcome,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  key: const Key('splashBrandTitle'),
                  l10n.splashTitle,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: colors.primary,
                    fontSize: AppTheme.fontSizeXXL,
                    fontWeight: AppTheme.fontWeightBold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacing12),
                Text(
                  l10n.splashSubtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    fontSize: AppTheme.fontSizeSM,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLG),
                Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  key: const Key('splashContinueHint'),
                  l10n.splashTapToContinue,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textSecondary,
                    fontSize: AppTheme.fontSizeXS,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingMD),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
