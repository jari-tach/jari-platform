import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/saeq_semantic_colors.dart';
import 'saeq_secondary_button.dart';

/// Address block for pickup / dropoff.
class SaeqAddressBlock extends StatelessWidget {
  const SaeqAddressBlock({
    super.key,
    required this.title,
    required this.address,
  });

  final String title;
  final String address;

  @override
  Widget build(BuildContext context) {
    final colors = SaeqSemanticColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          address,
          style: AppTextStyles.bodyLarge.copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }
}

/// Maps / help actions. Maps copies a search query (no new launcher dependency).
class SaeqContactActionsRow extends StatelessWidget {
  const SaeqContactActionsRow({
    super.key,
    required this.mapsLabel,
    required this.query,
    required this.mapsCopiedMessage,
    this.helpLabel,
    this.onHelp,
  });

  final String mapsLabel;
  final String query;
  final String mapsCopiedMessage;
  final String? helpLabel;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SaeqSecondaryButton(
          label: mapsLabel,
          icon: Icons.map_outlined,
          onPressed: () async {
            final uri =
                'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
            await Clipboard.setData(ClipboardData(text: uri));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(mapsCopiedMessage)));
            }
          },
        ),
        if (helpLabel != null && onHelp != null) ...[
          const SizedBox(height: AppTheme.spacingSM),
          SaeqSecondaryButton(
            label: helpLabel!,
            icon: Icons.report_problem_outlined,
            onPressed: onHelp,
          ),
        ],
      ],
    );
  }
}
