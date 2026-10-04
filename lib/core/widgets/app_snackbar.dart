import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Dark-surface snackbars with a leading status icon.
///
/// success=초록 체크 / error=err ✕ / progress=16px 스피너.
/// Background/text come from the theme's [SnackBarThemeData] (dark surface).
class AppSnackbar {
  const AppSnackbar._();

  static void success(BuildContext context, String message) {
    final colors = AppColors.of(context);
    _show(context, message, Icon(Icons.check, size: 18, color: colors.green));
  }

  static void error(BuildContext context, String message) {
    final colors = AppColors.of(context);
    _show(context, message, Icon(Icons.close, size: 18, color: colors.err));
  }

  static void progress(BuildContext context, String message) {
    _show(
      context,
      message,
      const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  static void _show(BuildContext context, String message, Widget leading) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
