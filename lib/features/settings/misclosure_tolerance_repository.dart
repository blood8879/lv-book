import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../fieldbook/domain/misclosure.dart';

/// App-level misclosure tolerance and length unit, stored in `app_settings`
/// next to the ads / Pro settings. Missing or invalid stored values fall back
/// to the defaults (metres, fixed 1 mm, c = 5 mm), so older installs keep the
/// 0.001 m behaviour.
class MisclosureToleranceRepository {
  static const modeKey = 'misclosure_tolerance_mode';
  static const fixedMmKey = 'misclosure_tolerance_fixed_mm';
  static const coefficientMmKey = 'misclosure_tolerance_coefficient_mm';
  static const unitKey = 'length_unit';
  static const fixedFtKey = 'misclosure_tolerance_fixed_ft';
  static const coefficientFtKey = 'misclosure_tolerance_coefficient_ft';

  static const _keys = [
    modeKey,
    fixedMmKey,
    coefficientMmKey,
    unitKey,
    fixedFtKey,
    coefficientFtKey,
  ];

  final DatabaseHelper _dbHelper;

  MisclosureToleranceRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<MisclosureTolerance> load() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'app_settings',
      where: 'key IN (${List.filled(_keys.length, '?').join(', ')})',
      whereArgs: _keys,
    );
    final values = {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
    double entry(String key, LengthUnit unit, double fallback) {
      final value = double.tryParse(values[key] ?? '');
      return MisclosureTolerance.isValidEntry(value, unit) ? value! : fallback;
    }

    return MisclosureTolerance(
      mode: MisclosureToleranceMode.parse(values[modeKey]),
      fixedMm: entry(
        fixedMmKey,
        LengthUnit.metres,
        MisclosureTolerance.defaultFixedMm,
      ),
      coefficientMm: entry(
        coefficientMmKey,
        LengthUnit.metres,
        MisclosureTolerance.defaultCoefficientMm,
      ),
      unit: LengthUnit.parse(values[unitKey]),
      fixedFt: entry(
        fixedFtKey,
        LengthUnit.feet,
        MisclosureTolerance.defaultFixedFt,
      ),
      coefficientFt: entry(
        coefficientFtKey,
        LengthUnit.feet,
        MisclosureTolerance.defaultCoefficientFt,
      ),
    );
  }

  /// Saves [tolerance] (including its unit); throws [ArgumentError] for
  /// out-of-range values.
  Future<void> save(MisclosureTolerance tolerance) async {
    if (!MisclosureTolerance.isValidMm(tolerance.fixedMm) ||
        !MisclosureTolerance.isValidMm(tolerance.coefficientMm) ||
        !MisclosureTolerance.isValidEntry(tolerance.fixedFt, LengthUnit.feet) ||
        !MisclosureTolerance.isValidEntry(
          tolerance.coefficientFt,
          LengthUnit.feet,
        )) {
      throw ArgumentError.value(tolerance, 'tolerance', 'out of range');
    }
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final entry in {
      modeKey: tolerance.mode.name,
      fixedMmKey: tolerance.fixedMm.toString(),
      coefficientMmKey: tolerance.coefficientMm.toString(),
      unitKey: tolerance.unit.name,
      fixedFtKey: tolerance.fixedFt.toString(),
      coefficientFtKey: tolerance.coefficientFt.toString(),
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

/// App length unit (labels only; see [LengthUnit]). Metres while loading.
final lengthUnitProvider = Provider<LengthUnit>(
  (ref) =>
      ref.watch(misclosureToleranceProvider).valueOrNull?.unit ??
      LengthUnit.metres,
);

/// Allowance text (mm or ft) without trailing zeros: 1.0 → '1', 2.5 → '2.5',
/// 0.01 → '0.01'.
String formatToleranceValue(double value) {
  final text = value.toStringAsFixed(4);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}
