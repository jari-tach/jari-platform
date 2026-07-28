import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/saeq_empty_state.dart';
import '../../../../shared/widgets/saeq_secondary_button.dart';

/// Shell placeholder until Increment 3/4 fills real content.
class ShellPlaceholderScreen extends StatelessWidget {
  const ShellPlaceholderScreen({
    super.key,
    required this.title,
    this.message,
    this.homeRoute = '/home',
  });

  final String title;
  final String? message;
  final String homeRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.contentPadding),
          child: Column(
            children: [
              Expanded(
                child: SaeqEmptyState(
                  title: title,
                  message: message ?? l10n.shellPlaceholderMessage,
                  icon: Icons.construction_outlined,
                ),
              ),
              SaeqSecondaryButton(
                label: l10n.navHome,
                icon: Icons.home_outlined,
                onPressed: () => context.go(homeRoute),
              ),
              const SizedBox(height: AppTheme.spacingSM),
            ],
          ),
        ),
      ),
    );
  }
}
