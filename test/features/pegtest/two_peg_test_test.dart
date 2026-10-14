import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/database/database_helper.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/pegtest/data/peg_test_settings_repository.dart';
import 'package:lv_book/features/pegtest/domain/two_peg_test.dart';
import 'package:lv_book/features/pegtest/presentation/peg_test_screen.dart';
import 'package:lv_book/l10n/l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

TwoPegTest? _parse({
  String a1 = '1.525',
  String b1 = '1.230',
  String a2 = '1.410',
  String b2 = '1.120',
  String distance = '40',
  LengthUnit unit = LengthUnit.metres,
  double tolerance = 3,
}) => TwoPegTest.tryParse(
  a1: a1,
  b1: b1,
  a2: a2,
  b2: b2,
  pegDistance: distance,
  unit: unit,
  toleranceEntry: tolerance,
);

void main() {
  group('TwoPegTest (metres)', () {
    test('worked example: +5 mm over 40 m needs adjustment at 3 mm', () {
      final test = _parse()!;
      expect(test.trueDifference, closeTo(0.295, 1e-9));
      expect(test.expectedB2, closeTo(1.115, 1e-9));
      expect(test.error, closeTo(0.005, 1e-9));
      expect(test.errorPer100, closeTo(0.0125, 1e-9));
      // atan(0.005 / 40) ≈ 25.78″
      expect(test.arcSeconds, closeTo(25.78, 0.01));
      expect(test.allowed, closeTo(0.003, 1e-12));
      expect(test.withinTolerance, isFalse);

      expect(formatPegTestError(test.error, LengthUnit.metres), '+5.0 mm');
      expect(
        formatPegTestError(test.errorPer100, LengthUnit.metres),
        '+12.5 mm',
      );
      expect(formatArcSeconds(test.arcSeconds), '+25.8″');
      expect(
        formatPegTestReading(test.expectedB2, LengthUnit.metres),
        '1.115 m',
      );
    });

    test('same example is within a 5 mm tolerance (boundary inclusive)', () {
      expect(_parse(tolerance: 5)!.withinTolerance, isTrue);
      expect(_parse(tolerance: 4.9)!.withinTolerance, isFalse);
    });

    test('downward line of sight gives a negative error', () {
      final test = _parse(b2: '1.113')!;
      expect(test.error, closeTo(-0.002, 1e-9));
      expect(test.arcSeconds, lessThan(0));
      expect(test.withinTolerance, isTrue);
      expect(formatPegTestError(test.error, LengthUnit.metres), '-2.0 mm');
    });

    test('perfect instrument reads exactly the expected B', () {
      final test = _parse(b2: '1.115')!;
      expect(formatPegTestError(test.error, LengthUnit.metres), '0.0 mm');
      expect(formatArcSeconds(test.arcSeconds), '0.0″');
      expect(test.withinTolerance, isTrue);
    });

    test('accepts a decimal comma', () {
      expect(
        _parse(a1: '1,525', distance: '40,0')!.trueDifference,
        closeTo(0.295, 1e-9),
      );
    });
  });

  test('feet mode: tolerance and error stay in ft', () {
    final test = _parse(
      a1: '5.000',
      b1: '4.000',
      a2: '5.200',
      b2: '4.215',
      distance: '150',
      unit: LengthUnit.feet,
      tolerance: 0.01,
    )!;
    expect(test.trueDifference, closeTo(1.0, 1e-9));
    expect(test.expectedB2, closeTo(4.2, 1e-9));
    expect(test.error, closeTo(0.015, 1e-9));
    expect(test.errorPer100, closeTo(0.01, 1e-9));
    expect(test.allowed, 0.01); // ft, not divided by 1000
    expect(test.arcSeconds, closeTo(20.63, 0.01));
    expect(test.withinTolerance, isFalse);
    expect(formatPegTestError(test.error, LengthUnit.feet), '+0.0150 ft');
    expect(formatPegTestReading(test.expectedB2, LengthUnit.feet), '4.200 ft');
    expect(TwoPegTest.defaultTolerance(LengthUnit.feet), 0.01);
    expect(TwoPegTest.defaultTolerance(LengthUnit.metres), 3);
  });

  group('invalid input gives no result', () {
    test('empty fields', () {
      expect(_parse(a1: ''), isNull);
      expect(_parse(b2: '  '), isNull);
      expect(_parse(distance: ''), isNull);
    });

    test('zero or negative peg distance', () {
      expect(_parse(distance: '0'), isNull);
      expect(_parse(distance: '-40'), isNull);
    });

    test('non-numbers', () {
      expect(_parse(a2: 'abc'), isNull);
      expect(_parse(distance: 'NaN'), isNull);
      expect(_parse(distance: 'Infinity'), isNull);
    });
  });

  test('summary lists inputs, results and the verdict', () {
    final en = l10nFor(const Locale('en'));
    final summary = buildPegTestSummary(
      en,
      _parse()!,
      DateTime(2026, 10, 15, 9, 5),
    );
    expect(summary, startsWith('Two-peg test · 2026-10-15 09:05'));
    expect(summary, contains('Setup 1 (midway): A 1.525 m, B 1.230 m'));
    expect(summary, contains('Setup 2 (near A): A 1.410 m, B 1.120 m'));
    expect(summary, contains('Collimation error over A–B: +5.0 mm'));
    expect(summary, contains('Error per 100 m: +12.5 mm'));
    expect(summary, contains('Tolerance: ±3 mm'));
    expect(summary, contains('Result: Adjustment required'));
    expect(summary, contains('Correct B reading: 1.115 m'));

    final ko = buildPegTestSummary(l10nKo, _parse()!, DateTime(2026));
    expect(ko, contains('판정: 조정 필요'));
  });

  group('PegTestSettingsRepository', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    final helper = DatabaseHelper.instance;
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: helper.openDatabaseOptions(),
      );
      helper.setDatabaseForTesting(db);
    });

    tearDown(() async {
      helper.setDatabaseForTesting(null);
      await db.close();
    });

    test('defaults, then round-trips tolerance and inputs', () async {
      final repository = PegTestSettingsRepository();
      final initial = await repository.load();
      expect(initial.toleranceMm, 3);
      expect(initial.toleranceFt, 0.01);
      expect(initial.inputs, isEmpty);

      await repository.saveTolerance(LengthUnit.metres, 2.5);
      await repository.saveTolerance(LengthUnit.feet, 0.02);
      await repository.saveInputs({'a1': '1.525', 'distance': '40'});
      final loaded = await repository.load();
      expect(loaded.toleranceFor(LengthUnit.metres), 2.5);
      expect(loaded.toleranceFor(LengthUnit.feet), 0.02);
      expect(loaded.inputs, {'a1': '1.525', 'distance': '40'});
    });

    test('rejects out-of-range tolerance and ignores corrupt rows', () async {
      final repository = PegTestSettingsRepository();
      expect(
        () => repository.saveTolerance(LengthUnit.metres, 0),
        throwsArgumentError,
      );
      await db.insert('app_settings', {
        'key': PegTestSettingsRepository.toleranceMmKey,
        'value': 'abc',
      });
      await db.insert('app_settings', {
        'key': PegTestSettingsRepository.inputsKey,
        'value': '{not json',
      });
      final loaded = await repository.load();
      expect(loaded.toleranceMm, 3);
      expect(loaded.inputs, isEmpty);
    });
  });
}
