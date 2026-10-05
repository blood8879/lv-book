import 'package:flutter/widgets.dart';

class AppConstants {
  // App name is localized: use context.l10n.coreAppName.
  static const String dbName = 'lv_book.db';
  static const int dbVersion = 10;

  /// Bottom space (from the bottom safe-area edge) a scrollable list should
  /// reserve so its last item can scroll clear of the app-wide quick-memo FAB
  /// (52pt button + 80pt bottom offset + 16pt gap).
  static const double quickMemoFabClearance = 148;

  /// Bottom padding for a list that runs to the bottom of the screen:
  /// [quickMemoFabClearance] plus the system navigation bar / gesture bar
  /// inset, which edge-to-edge layouts draw content under. Uses
  /// [MediaQuery.paddingOf], so the inset drops out while the keyboard is up
  /// and inside a Scaffold body that already has a bottom bar.
  static double quickMemoFabListBottomPadding(BuildContext context) =>
      quickMemoFabClearance + MediaQuery.paddingOf(context).bottom;
}
