class AppConstants {
  // App name is localized: use context.l10n.coreAppName.
  static const String dbName = 'lv_book.db';
  static const int dbVersion = 10;

  /// Bottom space (from the bottom safe-area edge) a scrollable list should
  /// reserve so its last item can scroll clear of the app-wide quick-memo FAB
  /// (52pt button + 80pt bottom offset + 16pt gap).
  static const double quickMemoFabClearance = 148;
}
