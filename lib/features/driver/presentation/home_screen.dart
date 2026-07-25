import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/saeq_primary_button.dart';
import '../../auth/presentation/providers/auth_providers.dart';

/// Minimal authenticated landing screen (PHASE 2.2).
///
/// Only enough to prove the protected route + sign-out flow work end to
/// end: a greeting derived from the current session and a Sign Out
/// button. No dashboard, no Driver Profile, no availability toggle — all
/// explicitly out of scope for this phase.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    final session = state.session;
    final isBusy = state.isBusy;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeWelcomeTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.homeWelcomeTitle, style: AppTextStyles.headlineLarge),
              const SizedBox(height: 10),
              if (session != null)
                Text(session.maskedPhoneNumber, style: AppTextStyles.bodyLarge),
              const Spacer(),
              SaeqPrimaryButton(
                label: l10n.signOut,
                icon: Icons.logout,
                onPressed: isBusy
                    ? null
                    : () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
