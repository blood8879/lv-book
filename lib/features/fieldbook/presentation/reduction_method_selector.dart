import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../domain/reduction.dart';
import 'fieldbook_l10n.dart';

/// "Reduction method" over a full-width [ HI | Rise & Fall ] — used by the new level book
/// sheet and the editor's details panel. Segments are at least 44 px tall.
class ReductionMethodSelector extends StatelessWidget {
  final ReductionMethod value;
  final ValueChanged<ReductionMethod> onChanged;

  /// Adds the one-line explanation below (editor panel).
  final bool showHelp;

  const ReductionMethodSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.showHelp = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.fieldbookReductionMethodLabel,
          style: TextStyle(fontSize: 13, color: colors.subtext),
        ),
        const SizedBox(height: 4),
        // Full width, equal segments; labels scale down rather than
        // overflow with large text.
        SegmentedButton<ReductionMethod>(
          key: const ValueKey('reduction-method-selector'),
          expandedInsets: EdgeInsets.zero,
          segments: [
            for (final method in ReductionMethod.values)
              ButtonSegment(
                value: method,
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(method.localizedLabel(l10n), maxLines: 1),
                ),
              ),
          ],
          selected: {value},
          showSelectedIcon: false,
          style: const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(44, 44)),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          onSelectionChanged: (selection) => onChanged(selection.first),
        ),
        if (showHelp) ...[
          const SizedBox(height: 4),
          Text(
            l10n.fieldbookReductionHelp,
            style: TextStyle(fontSize: 12, color: colors.subtext),
          ),
        ],
      ],
    );
  }
}
