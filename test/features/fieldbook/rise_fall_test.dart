import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/export/export_labels.dart';
import 'package:lv_book/features/export/pdf_template.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_validation.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/fieldbook/domain/reduction.dart';
import 'package:lv_book/features/import/csv_importer.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';
import 'package:lv_book/features/project/data/sample_project_service.dart';
import 'package:lv_book/features/settings/misclosure_tolerance_repository.dart';
import 'package:lv_book/features/settings/settings_screen.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  final en = l10nFor(const Locale('en'));
  // BM-1 → TP-1 → No.1 (IS) → TP-2 → No.2 (IS) → BM-1 (closing).
  final sample = SampleProjectService.buildMeasurements(fieldBookId: 1);

  FieldBook book({
    ReductionMethod method = ReductionMethod.riseAndFall,
    ClosingReferenceMode closingMode = ClosingReferenceMode.loop,
  }) => FieldBook(
    id: 1,
    projectId: 1,
    title: 'Sample',
    date: DateTime(2026, 10, 5),
    startElevation: 100,
    closingMode: closingMode,
    reductionMethod: method,
  );

  group('rise and fall', () {
    test('rise/fall per reading on the sample run', () {
      final values = riseFallOf(sample);
      expect(values[0], isNull); // first BS: no previous reading
      expect(values[1], closeTo(0.552, 1e-9)); // 1.425 − 0.873 (TP-1 FS)
      expect(values[2], closeTo(-0.328, 1e-9)); // 1.612 (TP-1 BS) − 1.940
      expect(values[3], closeTo(-0.165, 1e-9)); // 1.940 (IS) − 2.105
      expect(values[4], closeTo(0.088, 1e-9)); // 1.338 (TP-2 BS) − 1.250
      expect(values[5], closeTo(-0.146, 1e-9)); // 1.250 (IS) − 1.396

      // Each value is the change in RL from the previous reduced row.
      for (var i = 1; i < sample.length; i++) {
        expect(values[i], closeTo(sample[i].gh! - sample[i - 1].gh!, 1e-9));
      }
      expect(values.map((v) => v == null ? null : formatRiseFall(v)).toList(), [
        null,
        '+0.552',
        '−0.328',
        '−0.165',
        '+0.088',
        '−0.146',
      ]);
      expect(formatRiseFall(-0.0000001), '0.000');
    });

    test('ΣBS − ΣFS = ΣRise − ΣFall = Final RL − Start RL', () {
      final closure = LevelClosureCheck.compute(
        sample,
        startElevation: 100,
        closingElevation: 100,
        method: ReductionMethod.riseAndFall,
      );
      expect(closure.riseFall.sumRise, closeTo(0.640, 1e-9));
      expect(closure.riseFall.sumFall, closeTo(0.639, 1e-9));
      expect(closure.sums.sumBs, closeTo(4.375, 1e-9));
      expect(closure.sums.sumFs, closeTo(4.374, 1e-9));
      final finalMinusStart = closure.sums.lastGh - closure.sums.firstGh;
      expect(closure.riseFall.difference, closeTo(0.001, 1e-9));
      expect(
        closure.sums.difference,
        closeTo(closure.riseFall.difference, 1e-9),
      );
      expect(finalMinusStart, closeTo(closure.riseFall.difference, 1e-9));
      expect(closure.riseFallOk, isTrue);
      expect(closure.isSuitable, isTrue);
    });

    test('rows before the first BS, empty and BS-only rows have no value', () {
      final values = riseFallOf([
        Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'A', fs: 1),
        Measurement(fieldBookId: 1, orderIndex: 1, stationName: 'B', bs: 1.5),
        Measurement(fieldBookId: 1, orderIndex: 2, stationName: 'C'),
        Measurement(fieldBookId: 1, orderIndex: 3, stationName: 'D', bs: 2),
        Measurement(fieldBookId: 1, orderIndex: 4, stationName: 'E', fs: 1),
      ]);
      expect(values, [null, null, null, null, 0.5]);
    });

    test('validation adds the rise/fall check only for rise and fall', () {
      MeasurementValidationResult validate(
        List<Measurement> rows,
        ReductionMethod method,
      ) => MeasurementValidation.validate(
        measurements: rows,
        startElevation: 100,
        method: method,
      );

      final hi = validate(sample, ReductionMethod.heightOfInstrument);
      expect(
        hi.checklist.map((item) => item.check),
        isNot(contains(MeasurementCheck.riseFall)),
      );
      final rf = validate(sample, ReductionMethod.riseAndFall);
      final item = rf.checklist.singleWhere(
        (item) => item.check == MeasurementCheck.riseFall,
      );
      expect(item.passed, isTrue);
      expect(item.blocksExport, isFalse);
      expect(rf.canExport, isTrue);

      // A hand-edited final RL breaks both checks (warning, not blocking).
      final edited = [
        ...sample.take(sample.length - 1),
        sample.last.copyWith(gh: sample.last.gh! + 0.05),
      ];
      final broken = validate(edited, ReductionMethod.riseAndFall);
      expect(broken.issues, contains(MeasurementIssue.riseFallMismatch));
      expect(broken.canExport, isFalse);
      expect(broken.hasBlockingFailures, isFalse);
      expect(
        validate(edited, ReductionMethod.heightOfInstrument).issues,
        isNot(contains(MeasurementIssue.riseFallMismatch)),
      );
    });

    test('ReductionMethod parses unknown/missing values as HI', () {
      expect(ReductionMethod.parse(null), ReductionMethod.heightOfInstrument);
      expect(ReductionMethod.parse('x'), ReductionMethod.heightOfInstrument);
      expect(ReductionMethod.parse('riseAndFall'), ReductionMethod.riseAndFall);
      expect(
        FieldBook.fromMap(book().toMap()).reductionMethod,
        ReductionMethod.riseAndFall,
      );
      final legacy = book().toMap()..remove('reduction_method');
      expect(
        FieldBook.fromMap(legacy).reductionMethod,
        ReductionMethod.heightOfInstrument,
      );
    });
  });

  group('intermediate sights', () {
    test('FS-only rows that are not TP and not last are IS', () {
      expect(intermediateSightFlags(sample), [
        false, // BM-1 (BS)
        false, // TP-1
        true, // No.1
        false, // TP-2
        true, // No.2
        false, // closing BM: last observed row
      ]);
      // Trailing unmeasured rows do not make the final FS an IS; a manual
      // TP is never an IS.
      final rows = [
        ...sample.take(4),
        sample[4].copyWith(manualTp: true),
        sample[5],
        Measurement(fieldBookId: 1, orderIndex: 6, stationName: 'empty'),
      ];
      expect(intermediateSightFlags(rows), [
        false,
        false,
        true,
        false,
        false,
        false,
        false,
      ]);
    });

    test('IS column moves IS readings out of FS so FS sums to ΣFS', () {
      final columns = exportTableColumns(intermediateSights: true);
      final table = exportTableRows(sample, columns: columns, empty: '-');
      final isIndex = columns.indexOf(ExportColumn.intermediate);
      final fsIndex = columns.indexOf(ExportColumn.fs);
      expect(table.map((row) => row[isIndex]).toList(), [
        '-',
        '-',
        '1.940',
        '-',
        '1.250',
        '-',
      ]);
      expect(table.map((row) => row[fsIndex]).toList(), [
        '-',
        '0.873',
        '-',
        '2.105',
        '-',
        '1.396',
      ]);
      final fsSum = table
          .map((row) => double.tryParse(row[fsIndex]) ?? 0)
          .fold<double>(0, (a, b) => a + b);
      expect(
        fsSum,
        closeTo(LevelCheckSums.from(sample, startElevation: 100).sumFs, 1e-9),
      );
    });
  });

  group('exports', () {
    String csv(AppLocalizations l10n, {MisclosureTolerance? tolerance}) =>
        CsvExporter.generateFieldBookCsv(
          fieldBook: book(),
          measurements: sample,
          bmName: 'BM-1',
          startElevation: 100,
          tolerance: tolerance ?? MisclosureTolerance.defaults,
          proSettings: const ProPdfSettings(includeCheckJudgement: true),
          l10n: l10n,
        );

    test('English rise-and-fall CSV: BS | IS | FS | Rise | Fall', () {
      final text = csv(en);
      expect(text, contains('Reduction method,Rise and fall'));
      expect(text, contains('Unit,m'));
      expect(text, contains('No.,Station,BS,IS,FS,Rise,Fall,RL,Remarks'));
      expect(text, contains('1,BM-1,1.425,,,,,100.000,'));
      expect(text, contains('2,TP-1,1.612,,0.873,0.552,,100.552,TP'));
      expect(text, contains('3,No.1,,1.940,,,0.328,100.224,'));
      expect(text, contains('ΣRise,0.640,ΣFall,0.639'));
      expect(text, contains('ΣRise − ΣFall,0.001'));
      expect(text, isNot(contains('HI')));
      expect(text, isNot(contains('Fail')));
    });

    test('Korean CSV keeps no IS column; rise and fall replaces HI', () {
      final text = csv(l10nKo);
      expect(text, contains('기입 방식,승강식'));
      expect(text, contains('No.,측점명,후시(BS),전시(FS),승(+),강(−),지반고(GH),비고'));
      expect(text, contains('3,No.1,,1.940,,0.328,100.224,'));

      final hi = CsvExporter.generateFieldBookCsv(
        fieldBook: book(method: ReductionMethod.heightOfInstrument),
        measurements: sample,
        bmName: 'BM-1',
        startElevation: 100,
        l10n: l10nKo,
      );
      expect(hi, contains('No.,측점명,후시(BS),전시(FS),기계고(IH),지반고(GH),비고'));
      expect(hi, contains('기입 방식,기고식'));
      expect(hi, isNot(contains('Σ승')));
    });

    test('CSV round trips the method and IS readings (both UIs)', () {
      for (final source in [en, l10nKo]) {
        for (final ui in [en, l10nKo]) {
          final result = CsvImporter.parse(
            csv(source),
            projectId: 1,
            fallbackDate: DateTime(2000),
            l10n: ui,
            appUnit: LengthUnit.metres,
          );
          expect(result.errors, isEmpty);
          expect(result.warnings, isEmpty);
          expect(
            result.fieldBook!.reductionMethod,
            ReductionMethod.riseAndFall,
          );
          expect(result.measurements.map((m) => m.fs).toList(), [
            null,
            0.873,
            1.940,
            2.105,
            1.250,
            1.396,
          ]);
          expect(result.measurements.map((m) => m.bs).toList(), [
            1.425,
            1.612,
            null,
            1.338,
            null,
            null,
          ]);
          expect(result.measurements.last.gh, closeTo(100.001, 1e-9));
          expect(result.measurements[1].type, MeasurementType.tp);
        }
      }
    });

    test('old CSV without method/unit rows imports as HI', () {
      const old =
          '직접수준측량 야장\n야장명,Old\n날짜,2026-01-01\nBM 표고,100.000\n\n'
          'No.,측점명,후시(BS),전시(FS),기계고(IH),지반고(GH),비고\n'
          '1,BM,1.500,,101.500,100.000,\n'
          '2,A,,1.000,,100.500,\n';
      final result = CsvImporter.parse(
        old,
        projectId: 1,
        fallbackDate: DateTime(2000),
        l10n: en,
        appUnit: LengthUnit.feet,
      );
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      expect(
        result.fieldBook!.reductionMethod,
        ReductionMethod.heightOfInstrument,
      );
      expect(result.measurements[1].fs, 1.0);
      expect(result.measurements[0].ih, 101.5);
    });

    test('importer warns when the file unit differs from the app', () {
      final result = CsvImporter.parse(
        csv(en, tolerance: const MisclosureTolerance(unit: LengthUnit.feet)),
        projectId: 1,
        fallbackDate: DateTime(2000),
        l10n: en,
        appUnit: LengthUnit.metres,
      );
      expect(result.errors, isEmpty);
      expect(result.warnings.single, contains('ft'));
      expect(result.measurements[2].fs, 1.940); // not converted
    });

    test('PDF check box and header for rise and fall / feet', () {
      final closure = LevelClosureCheck.compute(
        sample,
        startElevation: 100,
        closingElevation: 100,
        method: ReductionMethod.riseAndFall,
      );
      final rows = PdfExporter.checkRowsForTest(closure, l10n: en);
      expect(rows, hasLength(4));
      expect(rows[2], [
        ('ΣRise', '0.640'),
        ('ΣFall', '0.639'),
        ('ΣRise − ΣFall', '0.001'),
      ]);
      expect(rows[3][1], ('Misclosure', '+0.0010'));

      final hiRows = PdfExporter.checkRowsForTest(
        LevelClosureCheck.compute(sample, startElevation: 100),
        l10n: en,
      );
      expect(hiRows, hasLength(3));

      expect(
        exportTableHeaders(
          en,
          method: ReductionMethod.riseAndFall,
          intermediateSights: exportUsesIntermediateColumn(en),
        ),
        ['No.', 'Station', 'BS', 'IS', 'FS', 'Rise', 'Fall', 'RL', 'Remarks'],
      );
      expect(exportUsesIntermediateColumn(l10nKo), isFalse);

      final labels = PdfExporter.metadataLabelsForTest(
        book(),
        l10n: en,
        unit: LengthUnit.feet,
      );
      expect(labels, contains('Reduction method: Rise and fall'));
      expect(labels, contains('Unit: ft'));
      final defaults = PdfExporter.metadataLabelsForTest(
        book(method: ReductionMethod.heightOfInstrument),
        l10n: l10nKo,
      );
      expect(defaults.where((l) => l.startsWith('기입 방식')), isEmpty);
      expect(defaults.where((l) => l.startsWith('단위')), isEmpty);
      expect(
        PdfExporter.closingLabelsForTest(
          book(),
          startElevation: 100,
          bmName: 'BM-1',
          l10n: en,
          unit: LengthUnit.feet,
        ),
        contains('Closing RL: 100.000 ft'),
      );
    });
  });

  group('units', () {
    test('metres keep the mm tolerance; feet use ft', () {
      expect(MisclosureTolerance.defaults.unit, LengthUnit.metres);
      expect(MisclosureTolerance.defaults.allowed(5), 0.001);

      const feet = MisclosureTolerance(unit: LengthUnit.feet);
      expect(feet.allowed(1), 0.01);
      expect(feet.isWithin(0.01, setups: 3), isTrue);
      expect(feet.isWithin(0.011, setups: 3), isFalse);
      final sqrt = feet.copyWith(mode: MisclosureToleranceMode.sqrtSetups);
      expect(sqrt.allowed(4), closeTo(0.04, 1e-12));

      // Editing in feet never touches the mm values (and vice versa).
      final edited = feet.withEntry(MisclosureToleranceMode.fixed, 0.02);
      expect(edited.fixedFt, 0.02);
      expect(edited.fixedMm, MisclosureTolerance.defaultFixedMm);
      expect(edited.copyWith(unit: LengthUnit.metres).allowed(1), 0.001);

      expect(MisclosureTolerance.parseEntry('0.01', LengthUnit.feet), 0.01);
      expect(MisclosureTolerance.parseEntry('5', LengthUnit.feet), isNull);
      expect(MisclosureTolerance.parseEntry('5', LengthUnit.metres), 5);
      expect(LengthUnit.parse(null), LengthUnit.metres);
      expect(LengthUnit.feet.symbol, 'ft');
      expect(LengthUnit.metres.toleranceSymbol, 'mm');
    });

    test('summary and labels per unit', () {
      const feet = MisclosureTolerance(unit: LengthUnit.feet);
      expect(misclosureToleranceSummary(en, feet), 'Fixed ±0.01 ft');
      expect(
        misclosureToleranceSummary(
          en,
          feet.copyWith(mode: MisclosureToleranceMode.sqrtSetups),
        ),
        '0.02 ft × √n (n = setups)',
      );
      expect(
        misclosureToleranceSummary(en, MisclosureTolerance.defaults),
        'Fixed ±1 mm',
      );
      expect(formatToleranceValue(0.0005), '0.0005');
      expect(formatToleranceValue(100), '100');
      expect(en.fieldbookStartElevationLabel('ft'), 'Start RL (ft) *');
      expect(l10nKo.benchmarkElevationLine('100.000', 'm'), '표고 100.000 m');
      expect(exportLength(12.5, LengthUnit.feet), '12.500 ft');
    });
  });
}
