import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../fieldbook/domain/misclosure.dart';
import '../domain/two_peg_test.dart';

/// Two-peg test settings kept in `app_settings`: the allowance (mm for
/// metres, ft for feet; both kept so switching the unit loses nothing) and
/// the last typed field texts, so reopening the screen in the field keeps
/// them.
class PegTestSettings {
  final double toleranceMm;
  final double toleranceFt;

  /// Raw field texts by [PegTestField.name].
  final Map<String, String> inputs;

  const PegTestSettings({
    this.toleranceMm = TwoPegTest.defaultToleranceMm,
    this.toleranceFt = TwoPegTest.defaultToleranceFt,
    this.inputs = const {},
  });

  double toleranceFor(LengthUnit unit) =>
      unit == LengthUnit.metres ? toleranceMm : toleranceFt;
}

/// Input fields of the two-peg test; [name] is the persisted key.
enum PegTestField { a1, b1, a2, b2, distance }

/// Optional record fields (saved with a record), kept with the inputs like
/// [PegTestField]; [name] is the persisted key.
enum PegTestRecordField { instrument, observer, note }

class PegTestSettingsRepository {
  static const toleranceMmKey = 'peg_test_tolerance_mm';
  static const toleranceFtKey = 'peg_test_tolerance_ft';
  static const inputsKey = 'peg_test_inputs';

  static const _keys = [toleranceMmKey, toleranceFtKey, inputsKey];

  final DatabaseHelper _dbHelper;

  PegTestSettingsRepository({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Missing or invalid stored values fall back to the defaults.
  Future<PegTestSettings> load() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'app_settings',
      where: 'key IN (${List.filled(_keys.length, '?').join(', ')})',
      whereArgs: _keys,
    );
    final values = {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
    double tolerance(String key, LengthUnit unit) {
      final value = double.tryParse(values[key] ?? '');
      return MisclosureTolerance.isValidEntry(value, unit)
          ? value!
          : TwoPegTest.defaultTolerance(unit);
    }

    return PegTestSettings(
      toleranceMm: tolerance(toleranceMmKey, LengthUnit.metres),
      toleranceFt: tolerance(toleranceFtKey, LengthUnit.feet),
      inputs: _decodeInputs(values[inputsKey]),
    );
  }

  /// Saves the allowance for [unit]; throws [ArgumentError] when out of
  /// range (same range as the misclosure allowance).
  Future<void> saveTolerance(LengthUnit unit, double value) async {
    if (!MisclosureTolerance.isValidEntry(value, unit)) {
      throw ArgumentError.value(value, 'value', 'out of range');
    }
    await _put(
      unit == LengthUnit.metres ? toleranceMmKey : toleranceFtKey,
      value.toString(),
    );
  }

  Future<void> saveInputs(Map<String, String> inputs) =>
      _put(inputsKey, jsonEncode(inputs));

  Future<void> _put(String key, String value) async {
    final db = await _dbHelper.database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Map<String, String> _decodeInputs(String? raw) {
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };
    } on FormatException {
      return const {};
    }
  }
}

final pegTestSettingsRepositoryProvider = Provider<PegTestSettingsRepository>(
  (ref) => PegTestSettingsRepository(),
);
