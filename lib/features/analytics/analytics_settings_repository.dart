import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';

/// The "Share usage statistics" switch, stored in `app_settings`.
/// Missing value = on (the default).
class AnalyticsSettingsRepository {
  static const usageStatsKey = 'usage_stats_enabled';

  final DatabaseHelper _dbHelper;

  AnalyticsSettingsRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<bool> isUsageStatsEnabled() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [usageStatsKey],
      limit: 1,
    );
    if (rows.isEmpty) return true;
    return rows.first['value'] != 'false';
  }

  /// [isUsageStatsEnabled], or null when the setting cannot be read.
  Future<bool?> readUsageStatsEnabled() async {
    try {
      return await isUsageStatsEnabled();
    } catch (_) {
      return null;
    }
  }

  Future<void> setUsageStatsEnabled(bool enabled) async {
    final db = await _dbHelper.database;
    await db.insert('app_settings', {
      'key': usageStatsKey,
      'value': enabled.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
