import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

/// A button shown under the empty-state guidance text.
class EmptyStateAction {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// Shows a small spinner instead of [icon] and disables the button.
  final bool busy;

  const EmptyStateAction({
    required this.label,
    this.icon,
    this.onPressed,
    this.busy = false,
  });
}

/// Shared empty-state panel: icon badge + title + guidance text.
///
/// Keeps the look of the project-list empty state so every list screen
/// communicates "what to do next" the same way.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color accent;

  /// Optional soft background for the icon badge. When omitted, a 10% alpha
  /// tint of [accent] is used.
  final Color? accentSoft;

  /// Optional filled (primary) and outlined (secondary) buttons.
  final EmptyStateAction? primaryAction;
  final EmptyStateAction? secondaryAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.accent = AppTheme.fieldGreen,
    this.accentSoft,
    this.primaryAction,
    this.secondaryAction,
  });

  bool get _hasActions => primaryAction != null || secondaryAction != null;

  Widget _buttonChild(EmptyStateAction action) {
    final Widget? leading = action.busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (action.icon == null ? null : Icon(action.icon, size: 18));
    if (leading == null) return Text(action.label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [leading, const SizedBox(width: 8), Text(action.label)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = primaryAction;
    final secondary = secondaryAction;
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: _hasActions
              ? const BoxConstraints(maxWidth: 420)
              : const BoxConstraints(),
          // Extra bottom margin keeps the card clear of the app-wide
          // quick-memo FAB (bottom-left overlay).
          margin: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            AppConstants.quickMemoFabClearance,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accentSoft ?? accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 34, color: accent),
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.subtext),
              ),
              if (primary != null) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: primary.busy ? null : primary.onPressed,
                    child: _buttonChild(primary),
                  ),
                ),
              ],
              if (secondary != null) ...[
                SizedBox(height: primary != null ? 8 : 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: secondary.busy ? null : secondary.onPressed,
                    child: _buttonChild(secondary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
