import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/utils/calculation.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_validation.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';

/// Builds a reduced run from (station, bs, fs) with the app's [LevelRun].
List<Measurement> run(double start, List<(String, double?, double?)> readings) {
  final results = LevelRun.compute(start, [
    for (final r in readings) LevelRunInput(bs: r.$2, fs: r.$3),
  ]);
  return [
    for (var i = 0; i < readings.length; i++)
      Measurement(
        fieldBookId: 1,
        orderIndex: i,
        stationName: readings[i].$1,
        type: results[i].isTP ? MeasurementType.tp : MeasurementType.normal,
        bs: readings[i].$2,
        fs: readings[i].$3,
        ih: results[i].ih,
        gh: results[i].gh,
      ),
  ];
}

void main() {
  // BM-1 100.000 → TP-1 → BM-2: final RL 100.300 (ΣBS 2.500, ΣFS 2.200).
  final rows = run(100, [
    ('BM-1', 1.500, null),
    ('TP-1', 1.000, 1.200),
    ('BM-2', null, 1.000),
  ]);

  FieldBook book({
    ClosingReferenceMode mode = ClosingReferenceMode.none,
    int? bmId,
    double? elevation,
  }) => FieldBook(
    projectId: 1,
    title: 'Run',
    date: DateTime(2026, 10, 4),
    startElevation: 100,
    closingMode: mode,
    closingBmId: bmId,
    closingElevation: elevation,
  );

  group('closing RL per mode', () {
    test('none has no closing RL: arithmetic check only', () {
      final fb = book();
      expect(fb.closingElevationFor(100), isNull);
      final check = LevelClosureCheck.compute(
        rows,
        startElevation: 100,
        closingElevation: fb.closingElevationFor(100),
      );
      expect(check.hasClosing, isFalse);
      expect(check.misclosure, isNull);
      expect(check.withinTolerance, isNull);
      expect(check.arithmeticError, closeTo(0, 1e-12));
      expect(check.isSuitable, isTrue);
    });

    test('loop closes on the (current) start RL', () {
      final fb = book(mode: ClosingReferenceMode.loop);
      expect(fb.closingElevationFor(100), 100);
      expect(fb.closingElevationFor(101.5), 101.5);
      final check = LevelClosureCheck.compute(
        rows,
        startElevation: 100,
        closingElevation: fb.closingElevationFor(100),
      );
      expect(check.misclosure, closeTo(0.300, 1e-9));
      expect(formatMisclosure(check.misclosure!), '+0.3000');
      expect(check.withinTolerance, isFalse);
      expect(check.isSuitable, isFalse);
    });

    test('closing BM uses the snapshotted elevation', () {
      final fb = book(
        mode: ClosingReferenceMode.benchmark,
        bmId: 7,
        elevation: 100.302,
      );
      expect(fb.closingElevationFor(100), 100.302);
      final check = LevelClosureCheck.compute(
        rows,
        startElevation: 100,
        closingElevation: fb.closingElevationFor(100),
      );
      expect(check.misclosure, closeTo(-0.002, 1e-9));
      expect(formatMisclosure(check.misclosure!), '-0.0020');
      expect(check.withinTolerance, isFalse);
    });

    test('manual closing RL', () {
      final fb = book(mode: ClosingReferenceMode.manual, elevation: 100.2995);
      final check = LevelClosureCheck.compute(
        rows,
        startElevation: 100,
        closingElevation: fb.closingElevationFor(100),
      );
      expect(check.misclosure, closeTo(0.0005, 1e-9));
      expect(check.withinTolerance, isTrue);
      expect(check.isSuitable, isTrue);
    });

    test('a closing mode without its RL behaves as none', () {
      expect(
        book(mode: ClosingReferenceMode.manual).closingElevationFor(100),
        isNull,
      );
    });
  });

  group('tolerance', () {
    test('fixed default is 1 mm and the boundary is inclusive', () {
      const tolerance = MisclosureTolerance.defaults;
      expect(tolerance.mode, MisclosureToleranceMode.fixed);
      expect(tolerance.allowed(1), 0.001);
      expect(tolerance.allowed(99), 0.001);
      // 100.301 − 100.300 is 0.00099999… or 0.0010000…1 in binary.
      expect(tolerance.isWithin(100.301 - 100.300, setups: 2), isTrue);
      expect(tolerance.isWithin(-(100.301 - 100.300), setups: 2), isTrue);
      expect(tolerance.isWithin(0.001 + 2e-9, setups: 2), isFalse);
      expect(tolerance.isWithin(0.0011, setups: 2), isFalse);
    });

    test('c·√n uses the number of instrument setups', () {
      const tolerance = MisclosureTolerance.sqrtSetups(5);
      expect(tolerance.allowed(4), closeTo(0.010, 1e-12));
      expect(tolerance.allowed(0), closeTo(0.005, 1e-12));
      expect(tolerance.isWithin(0.010, setups: 4), isTrue);
      expect(tolerance.isWithin(-0.010, setups: 4), isTrue);
      expect(tolerance.isWithin(0.0101, setups: 4), isFalse);

      // Two rows establish an HI here (BM-1 and TP-1).
      expect(LevelClosureCheck.countSetups(rows), 2);
      final check = LevelClosureCheck.compute(
        rows,
        startElevation: 100,
        closingElevation: 100.293,
        tolerance: tolerance,
      );
      expect(check.allowed, closeTo(0.005 * 1.4142135623730951, 1e-12));
      expect(formatAllowedMisclosure(check.allowed), '±0.0071');
      expect(check.misclosure, closeTo(0.007, 1e-9));
      expect(check.withinTolerance, isTrue);
    });

    test('mm input is validated', () {
      expect(MisclosureTolerance.parseMm('5'), 5);
      expect(MisclosureTolerance.parseMm(' 2.5 '), 2.5);
      expect(MisclosureTolerance.parseMm('2,5'), 2.5);
      expect(MisclosureTolerance.parseMm('0.1'), 0.1);
      expect(MisclosureTolerance.parseMm('100'), 100);
      for (final bad in ['', 'abc', '0', '-1', '0.05', '100.1', 'NaN', 'inf']) {
        expect(MisclosureTolerance.parseMm(bad), isNull, reason: bad);
      }
    });

    test('mode names parse with a safe fallback', () {
      expect(
        MisclosureToleranceMode.parse('sqrtSetups'),
        MisclosureToleranceMode.sqrtSetups,
      );
      expect(MisclosureToleranceMode.parse('x'), MisclosureToleranceMode.fixed);
      expect(ClosingReferenceMode.parse(null), ClosingReferenceMode.none);
      expect(ClosingReferenceMode.parse('loop'), ClosingReferenceMode.loop);
    });
  });

  test('misclosure formatting', () {
    expect(formatMisclosure(0.001), '+0.0010');
    expect(formatMisclosure(-0.00149), '-0.0015');
    expect(formatMisclosure(-0.00001), '0.0000');
    expect(formatMisclosure(0), '0.0000');
    expect(formatAllowedMisclosure(0.005), '±0.0050');
  });

  group('validation', () {
    test('no closing RL: arithmetic check item, no tolerance item', () {
      final result = MeasurementValidation.validate(
        measurements: rows,
        startElevation: 100,
      );
      expect(result.canExport, isTrue);
      expect(result.misclosure, isNull);
      final checks = result.checklist.map((item) => item.check);
      expect(checks, contains(MeasurementCheck.arithmetic));
      expect(checks, isNot(contains(MeasurementCheck.tolerance)));
    });

    test('misclosure within tolerance is suitable', () {
      final result = MeasurementValidation.validate(
        measurements: rows,
        startElevation: 100,
        closingElevation: 100.301,
      );
      expect(result.misclosure, closeTo(-0.001, 1e-9));
      expect(result.canExport, isTrue);
      expect(
        result.checklist
            .singleWhere((item) => item.check == MeasurementCheck.tolerance)
            .passed,
        isTrue,
      );
    });

    test('exceeding tolerance is a warning, not a blocking failure', () {
      final result = MeasurementValidation.validate(
        measurements: rows,
        startElevation: 100,
        closingElevation: 100.250,
      );
      expect(result.canExport, isFalse);
      expect(result.hasBlockingFailures, isFalse);
      expect(result.issues, [MeasurementIssue.exceedsTolerance]);
      expect(result.judgementLabel, '확인 필요');

      final relaxed = MeasurementValidation.validate(
        measurements: rows,
        startElevation: 100,
        closingElevation: 100.250,
        tolerance: const MisclosureTolerance.fixed(50),
      );
      expect(relaxed.canExport, isTrue);
    });

    test('an RL that does not match its readings fails the arithmetic '
        'check even when the misclosure is fine', () {
      final edited = [...rows];
      edited[2] = edited[2].copyWith(gh: 100.305);
      final result = MeasurementValidation.validate(
        measurements: edited,
        startElevation: 100,
        closingElevation: 100.305,
      );
      expect(result.misclosure, closeTo(0, 1e-9));
      expect(result.arithmeticError, closeTo(-0.005, 1e-9));
      expect(result.canExport, isFalse);
      expect(result.hasBlockingFailures, isFalse);
      expect(result.issues, [MeasurementIssue.arithmeticMismatch]);
    });

    test('structural problems still block regardless of misclosure', () {
      final result = MeasurementValidation.validate(
        measurements: [rows.last],
        startElevation: 100,
        closingElevation: 100,
      );
      expect(result.hasBlockingFailures, isTrue);
      expect(result.issues, contains(MeasurementIssue.firstBsMissing));
      expect(result.issues, isNot(contains(MeasurementIssue.exceedsTolerance)));
    });
  });
}
