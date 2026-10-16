import 'dart:typed_data';

import 'package:excel_community/excel_community.dart' as xl;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/utils/calculation.dart';
import 'package:lv_book/features/export/xlsx_exporter.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/fieldbook/domain/reduction.dart';
import 'package:lv_book/features/import/csv_importer.dart';
import 'package:lv_book/features/import/xlsx_importer.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  final en = l10nFor(const Locale('en'));
  final ko = l10nKo;
  final es = l10nFor(const Locale('es'));

  Measurement row(
    int index,
    String station, {
    double? bs,
    double? fs,
    bool tp = false,
    bool manualTp = false,
    double? design,
  }) => Measurement(
    fieldBookId: 1,
    orderIndex: index,
    stationName: station,
    type: tp ? MeasurementType.tp : MeasurementType.normal,
    bs: bs,
    fs: fs,
    manualTp: manualTp,
    designLevel: design,
  );

  // BS, an intermediate sight with a design level, an auto TP, a manual
  // (FS-only) TP and the closing foresight.
  final measurements = [
    row(0, 'BM.1', bs: 1.5),
    row(1, 'P1', fs: 1.234, design: 100.2),
    row(2, 'TP1', bs: 1.3, fs: 0.9, tp: true),
    row(3, 'P2', fs: 1.05, design: 100.75),
    row(4, 'TP2', fs: 1.1, tp: true, manualTp: true),
    row(5, 'END', fs: 0.8),
  ];

  FieldBook book({
    required ReductionMethod method,
    required bool showDesign,
    required ClosingReferenceMode closingMode,
  }) => FieldBook(
    id: 1,
    projectId: 1,
    title: 'Loop A',
    date: DateTime(2026, 10, 16),
    startElevation: 100,
    closingMode: closingMode,
    closingElevation: closingMode == ClosingReferenceMode.manual
        ? 100.95
        : null,
    reductionMethod: method,
    showDesignLevel: showDesign,
    routeLength: 1.25,
    surveyor: 'Kim',
    checker: 'Lee',
    instrument: 'DL-500',
    weather: 'Clear',
    workSection: 'STA.0+000~0+200',
    jobNumber: 'J-2026-01',
  );

  CsvImportResult importBytes(List<int> bytes, AppLocalizations l10n) =>
      XlsxImporter.parse(
        bytes,
        projectId: 7,
        fallbackDate: DateTime(2000),
        l10n: l10n,
        appUnit: LengthUnit.metres,
      );

  void expectSameBook(CsvImportResult result, FieldBook source) {
    expect(result.errors, isEmpty);
    expect(result.warnings, isEmpty);
    final imported = result.fieldBook!;
    expect(imported.projectId, 7);
    expect(imported.title, source.title);
    expect(imported.date, source.date);
    expect(imported.startElevation, source.startElevation);
    expect(imported.closingMode, source.closingMode);
    expect(imported.closingElevation, source.closingElevation);
    expect(imported.reductionMethod, source.reductionMethod);
    expect(imported.showDesignLevel, source.showDesignLevel);
    expect(imported.routeLength, source.routeLength);
    expect(imported.surveyor, source.surveyor);
    expect(imported.checker, source.checker);
    expect(imported.instrument, source.instrument);
    expect(imported.weather, source.weather);
    expect(imported.workSection, source.workSection);
    expect(imported.jobNumber, source.jobNumber);

    // HI/RL are recomputed from BS/FS like the editor does.
    final levels = LevelRun.compute(source.startElevation!, [
      for (final m in measurements)
        LevelRunInput(bs: m.bs, fs: m.fs, manualTp: m.manualTp),
    ]);
    final rows = result.measurements;
    expect(rows, hasLength(measurements.length));
    for (var i = 0; i < rows.length; i++) {
      final expected = measurements[i];
      expect(rows[i].orderIndex, i);
      expect(rows[i].stationName, expected.stationName);
      expect(rows[i].bs, expected.bs, reason: expected.stationName);
      expect(rows[i].fs, expected.fs, reason: expected.stationName);
      expect(rows[i].type, expected.type, reason: expected.stationName);
      expect(rows[i].manualTp, expected.manualTp, reason: expected.stationName);
      expect(
        rows[i].designLevel,
        source.showDesignLevel ? expected.designLevel : null,
        reason: expected.stationName,
      );
      expect(rows[i].ih, levels[i].ih);
      expect(rows[i].gh, levels[i].gh);
    }
  }

  group('round trip XlsxExporter → XlsxImporter', () {
    for (final (name, l10n) in [('en', en), ('ko', ko), ('es', es)]) {
      test('$name: HI book with design levels and a loop closing', () {
        final source = book(
          method: ReductionMethod.heightOfInstrument,
          showDesign: true,
          closingMode: ClosingReferenceMode.loop,
        );
        final bytes = XlsxExporter.generateFieldBookXlsx(
          fieldBook: source,
          measurements: measurements,
          bmName: 'BM.1',
          startElevation: 100,
          projectName: 'Route 7',
          l10n: l10n,
        );
        expect(XlsxImporter.isXlsx(bytes), isTrue);
        expectSameBook(importBytes(bytes, l10n), source);
      });

      test('$name: Rise & Fall book with a manual closing and branding', () {
        final source = book(
          method: ReductionMethod.riseAndFall,
          showDesign: false,
          closingMode: ClosingReferenceMode.manual,
        );
        // Branding and review rows push the table below row 20.
        final bytes = XlsxExporter.generateFieldBookXlsx(
          fieldBook: source,
          measurements: measurements,
          bmName: 'BM.1',
          startElevation: 100,
          projectName: 'Route 7',
          proSettings: const ProPdfSettings(
            companyName: 'Acme Survey',
            authorName: 'Kim',
          ),
          l10n: l10n,
        );
        // Imported in another app language: labels of every language match.
        expectSameBook(importBytes(bytes, l10n == en ? ko : en), source);
      });
    }

    test('a file unit other than the app unit warns', () {
      final bytes = XlsxExporter.generateFieldBookXlsx(
        fieldBook: book(
          method: ReductionMethod.heightOfInstrument,
          showDesign: false,
          closingMode: ClosingReferenceMode.none,
        ),
        measurements: measurements,
        bmName: 'BM.1',
        startElevation: 100,
        tolerance: const MisclosureTolerance(unit: LengthUnit.feet),
        l10n: en,
      );
      final result = importBytes(bytes, en);
      expect(result.errors, isEmpty);
      expect(result.warnings.single, en.exportImportUnitMismatch('ft', 'm'));
    });
  });

  group('generic workbooks', () {
    Uint8List workbook(Map<String, List<List<xl.CellValue?>>> sheets) {
      final excel = xl.Excel.createExcel();
      final defaultSheet = excel.getDefaultSheet()!;
      var first = true;
      for (final MapEntry(key: name, value: rows) in sheets.entries) {
        if (first) {
          excel.rename(defaultSheet, name);
          first = false;
        }
        final sheet = excel[name];
        for (var r = 0; r < rows.length; r++) {
          for (var c = 0; c < rows[r].length; c++) {
            final value = rows[r][c];
            if (value == null) continue;
            sheet
                    .cell(
                      xl.CellIndex.indexByColumnRow(
                        columnIndex: c,
                        rowIndex: r,
                      ),
                    )
                    .value =
                value;
          }
        }
      }
      return Uint8List.fromList(excel.encode()!);
    }

    xl.TextCellValue t(String text) => xl.TextCellValue(text);
    xl.DoubleCellValue d(double value) => xl.DoubleCellValue(value);

    test('Korean headers, text numbers with a decimal comma, blank rows', () {
      final bytes = workbook({
        // A notes sheet without a table comes first and is skipped.
        '메모': [
          [t('현장 메모')],
          [t('측점'), t('설명')],
        ],
        '야장': [
          [t('현장 야장')],
          [t('날짜'), t('2026.10.3')],
          [t('BM 표고'), t('25,500')],
          [],
          [t(' 측점 '), t('후시 (BS)'), t('중간시'), t('전시'), t('지반고(GH)'), t('비고')],
          [t('BM1'), t('1,234'), null, null, t('n/a'), null],
          [],
          [t('No.1'), null, t('1.500')],
          [t('TP1'), d(1.1), null, t('0,987'), null, t('TP')],
          [t('END'), null, null, xl.IntCellValue(1)],
          [t('합계'), d(2.334), null, d(1.987)],
        ],
      });

      final result = importBytes(bytes, ko);
      expect(result.errors, isEmpty);
      final imported = result.fieldBook!;
      expect(imported.date, DateTime(2026, 10, 3));
      expect(imported.startElevation, 25.5);
      expect(imported.reductionMethod, ReductionMethod.heightOfInstrument);

      final rows = result.measurements;
      expect(
        [for (final m in rows) m.stationName],
        ['BM1', 'No.1', 'TP1', 'END'],
      );
      expect([for (final m in rows) m.bs], [1.234, null, 1.1, null]);
      expect([for (final m in rows) m.fs], [null, 1.5, 0.987, 1.0]);
      expect(
        [for (final m in rows) m.type],
        [
          MeasurementType.normal,
          MeasurementType.normal,
          MeasurementType.tp,
          MeasurementType.normal,
        ],
      );
      // The RL column ('n/a') is ignored; levels are recomputed.
      expect(rows[0].gh, 25.5);
      expect(rows[1].gh, closeTo(25.234, 1e-9));
      expect(rows[2].gh, closeTo(25.747, 1e-9));
      expect(rows[3].gh, closeTo(25.847, 1e-9));
    });

    test('English No./BS/FS headers in any case; No. is the station', () {
      final bytes = workbook({
        'Sheet1': [
          [t('NO.'), t('bs'), t('Fs'), t('REMARKS')],
          [xl.IntCellValue(1), d(1.5)],
          [xl.IntCellValue(2), null, d(1.25), t('turning point')],
        ],
      });
      final result = importBytes(bytes, en);
      expect(result.errors, isEmpty);
      expect(result.warnings.single, en.exportImportDateMissing('2000-01-01'));
      expect([for (final m in result.measurements) m.stationName], ['1', '2']);
      expect(result.measurements[1].fs, 1.25);
      expect(result.measurements[1].manualTp, isTrue);
      expect(result.fieldBook!.startElevation, isNull);
    });

    test('an unreadable number reports the worksheet row', () {
      final bytes = workbook({
        'Sheet1': [
          [t('Station'), t('BS'), t('FS')],
          [t('BM'), d(1.5)],
          [t('P1'), null, t('abc')],
        ],
      });
      final result = importBytes(bytes, en);
      expect(result.fieldBook, isNull);
      expect(result.errors.single, en.exportImportInvalidNumber(3, 'FS'));
    });

    test('a workbook without a recognisable header is rejected', () {
      final bytes = workbook({
        'Sheet1': [
          [t('Name'), t('Value')],
          [t('A'), d(1)],
        ],
      });
      for (final l10n in [en, ko]) {
        final result = importBytes(bytes, l10n);
        expect(result.fieldBook, isNull);
        expect(result.errors, [l10n.exportImportHeaderNotFound]);
      }
    });

    test('formula cells read their cached value, else empty', () {
      expect(
        XlsxImporter.cellText(
          xl.FormulaCellValue('B2+1', cachedValue: xl.DoubleCellValue(1.25)),
        ),
        '1.25',
      );
      expect(XlsxImporter.cellText(xl.FormulaCellValue('B2+1')), '');
      expect(XlsxImporter.cellText(xl.DoubleCellValue(100)), '100');
      expect(
        XlsxImporter.cellText(xl.DateCellValue(year: 2026, month: 3, day: 9)),
        '2026-03-09',
      );
    });
  });

  group('unreadable files never throw', () {
    final valid = XlsxExporter.generateFieldBookXlsx(
      fieldBook: book(
        method: ReductionMethod.heightOfInstrument,
        showDesign: false,
        closingMode: ClosingReferenceMode.none,
      ),
      measurements: measurements,
      bmName: 'BM.1',
      startElevation: 100,
      l10n: en,
    );

    test('a corrupt or truncated .xlsx', () {
      final corrupt = [0x50, 0x4B, 0x03, 0x04, ...List.filled(200, 0x41)];
      final truncated = valid.sublist(0, valid.length ~/ 2);
      for (final bytes in [corrupt, truncated]) {
        final result = importBytes(bytes, en);
        expect(result.fieldBook, isNull);
        expect(result.errors, [en.exportImportXlsxUnreadable]);
      }
    });

    test('an old .xls or encrypted workbook asks for .xlsx', () {
      final ole = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1];
      final bytes = [...ole, ...List.filled(1024, 0)];
      expect(XlsxImporter.isXlsx(bytes), isFalse);
      final result = importBytes(bytes, ko);
      expect(result.fieldBook, isNull);
      expect(result.errors, [ko.exportImportXlsxLegacy]);
      expect(ko.exportImportXlsxLegacy, contains('.xlsx'));
    });

    test('text that is not a workbook', () {
      final result = importBytes('No.,Station\n'.codeUnits, en);
      expect(result.errors, [en.exportImportXlsxUnreadable]);
    });
  });
}
