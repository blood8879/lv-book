import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../fieldbook/domain/misclosure.dart';

/// App-level misclosure tolerance, stored in `app_settings` next to the ads /
/// Pro settings. Missing or invalid stored values fall back to the defaults
/// (fixed 1 mm, c = 5 mm), so older installs keep the 0.001 m behaviour.
class MisclosureToleranceRepository {
  static const modeKey = 'misclosure_tolerance_mode';
  static const fixedMmKey = 'misclosure_tolerance_fixed_mm';
  static const coefficientMmKey = 'misclosure_tolerance_coefficient_mm';

  final DatabaseHelper _dbHelper;

  MisclosureToleranceRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<MisclosureTolerance> load() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'app_settings',
      where: 'key IN (?, ?, ?)',
      whereArgs: [modeKey, fixedMmKey, coefficientMmKey],
    );
    final values = {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
    double mm(String key, double fallback) {
      final value = double.tryParse(values[key] ?? '');
      return MisclosureTolerance.isValidMm(value) ? value! : fallback;
    }

    return MisclosureTolerance(
      mode: MisclosureToleranceMode.parse(values[modeKey]),
      fixedMm: mm(fixedMmKey, MisclosureTolerance.defaultFixedMm),
      coefficientMm: mm(
        coefficientMmKey,
        MisclosureTolerance.defaultCoefficientMm,
      ),
    );
  }

  /// Saves [tolerance]; throws [ArgumentError] for out-of-range values.
  Future<void> save(MisclosureTolerance tolerance) async {
    if (!MisclosureTolerance.isValidMm(tolerance.fixedMm) ||
        !MisclosureTolerance.isValidMm(tolerance.coefficientMm)) {
      throw ArgumentError.value(tolerance, 'tolerance', 'out of range');
    }
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final entry in {
      modeKey: tolerance.mode.name,
      fixedMmKey: tolerance.fixedMm.toString(),
      coefficientMmKey: tolerance.coefficientMm.toString(),
    }.entries) {
      batch.insert('app_settings', {
        'key': entry.key,
        'value': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}

final misclosureToleranceRepositoryProvider =
    Provider<MisclosureToleranceRepository>(
      (ref) => MisclosureToleranceRepository(),
    );

/// Current tolerance rule. Widgets fall back to [MisclosureTolerance.defaults]
/// while loading (`valueOrNull ?? MisclosureTolerance.defaults`).
final misclosureToleranceProvider = FutureProvider<MisclosureTolerance>(
  (ref) => ref.watch(misclosureToleranceRepositoryProvider).load(),
);

/// mm text without trailing zeros: 1.0 → '1', 2.5 → '2.5'.
String formatToleranceMm(double mm) {
  final text = mm.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}
