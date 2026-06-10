import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';

class AdSettingsRepository {
  static const _adsRemovedKey = 'ads_removed';
  static const _lastInterstitialAtKey = 'last_interstitial_at';
  static const _interstitialDateKey = 'interstitial_date';
  static const _interstitialCountKey = 'interstitial_count';

  static const maxInterstitialsPerDay = 3;
  static const interstitialCooldown = Duration(minutes: 10);

  Future<bool> areAdsRemoved() async {
    return _getValue(_adsRemovedKey).then((value) => value == 'true');
  }

  Future<void> setAdsRemoved(bool removed) async {
    await _setValue(_adsRemovedKey, removed.toString());
  }

  Future<bool> canShowInterstitial({DateTime? now}) async {
    if (await areAdsRemoved()) return false;

    final currentTime = now ?? DateTime.now();
    final currentDate = _dateKey(currentTime);
    final storedDate = await _getValue(_interstitialDateKey);
    final shownToday = storedDate == currentDate
        ? int.tryParse(await _getValue(_interstitialCountKey) ?? '0') ?? 0
        : 0;

    if (shownToday >= maxInterstitialsPerDay) return false;

    final lastShownAt = DateTime.tryParse(
      await _getValue(_lastInterstitialAtKey) ?? '',
    );
    if (lastShownAt == null) return true;

    return currentTime.difference(lastShownAt) >= interstitialCooldown;
  }

  Future<void> recordInterstitialShown({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final currentDate = _dateKey(currentTime);
    final storedDate = await _getValue(_interstitialDateKey);
    final currentCount = storedDate == currentDate
        ? int.tryParse(await _getValue(_interstitialCountKey) ?? '0') ?? 0
        : 0;

    await _setValue(_interstitialDateKey, currentDate);
    await _setValue(_interstitialCountKey, (currentCount + 1).toString());
    await _setValue(_lastInterstitialAtKey, currentTime.toIso8601String());
  }

  Future<String?> _getValue(String key) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> _setValue(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  String _dateKey(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
