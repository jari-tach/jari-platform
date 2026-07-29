import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/saeq_info_card.dart';

/// One selectable fake state inside [TrialStateSelector].
class TrialStateOption {
  const TrialStateOption({
    required this.optionKey,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final Key optionKey;
  final String label;
  final bool selected;
  final VoidCallback? onSelected;
}

/// Trial-only state switcher for the STEP 2B fake location and map screens.
///
/// The whole increment is a fake UI pass; this switcher is how each state is
/// reviewed on a real device without any platform location API.
class TrialStateSelector extends StatelessWidget {
  const TrialStateSelector({
    super.key,
    required this.title,
    required this.hint,
    required this.options,
  });

  final String title;
  final String hint;
  final List<TrialStateOption> options;

  @override
  Widget build(BuildContext context) {
    return SaeqInfoCard(
      title: title,
      subtitle: hint,
      leading: const Icon(Icons.science_outlined),
      child: Wrap(
        spacing: AppTheme.spacingSM,
        runSpacing: AppTheme.spacingSM,
        children: [
          for (final option in options)
            ChoiceChip(
              key: option.optionKey,
              label: Text(option.label),
              selected: option.selected,
              onSelected: option.onSelected == null
                  ? null
                  : (_) => option.onSelected!(),
            ),
        ],
      ),
    );
  }
}
