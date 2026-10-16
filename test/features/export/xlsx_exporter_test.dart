import 'package:excel_community/excel_community.dart' as xl;
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/export_file_namer.dart';
import 'package:lv_book/features/export/xlsx_exporter.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/fieldbook/domain/reduction.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  final en = l10nFor(const Locale('en'));
  final ko = l10nKo;
  final es = l10nFor(const Locale('es'));

  FieldBook book({
    bool showDesign = false,
    ReductionMethod method = ReductionMethod.heightOfInstrument,
  }) => FieldBook(
    id: 1,
    projectId: 1,
    title: 'Loop A',
    date: DateTime(2026, 10, 16),
    surveyor: 'Kim',
    instrument: 'DL-500',
    closingMode: ClosingReferenceMode.manual,
    closingElevation: 100.6,
    reductionMethod: method,
    showDesignLevel: showDesign,
  );

  // BM.1 → No.1 (IS) → TP1 → END; closes on 100.600 exactly.
  final measurements = [
    Measurement(
      fieldBookId: 1,
      orderIndex: 0,
      stationName: 'BM.1',
      bs: 1.5,
      ih: 101.5,
      gh: 100,
    ),
    Measurement(
      fieldBookId: 1,
      orderIndex: 1,
      stationName: 'No.1',
      fs: 1.276,
      gh: 100.224,
      designLevel: 100.099,
    ),
    Measurement(
      fieldBookId: 1,
      orderIndex: 2,
      stationName: 'TP1',
      type: MeasurementType.tp,
      bs: 1.2,
      fs: 1.0,
      ih: 101.7,
      gh: 100.5,
    ),
    Measurement(
      fieldBookId: 1,
      orderIndex: 3,
      stationName: 'END',
      fs: 1.1,
      gh: 100.6,
      designLevel: 100.64,
    ),
  ];

  xl.Sheet decode(
    AppLocalizations l10n, {
    FieldBook? fieldBook,
    ProPdfSettings? proSettings,
  }) {
    final bytes = XlsxExporter.generateFieldBookXlsx(
      fieldBook: fieldBook ?? book(),
      measurements: measurements,
      bmName: 'BM.1',
      startElevation: 100,
      projectName: 'Route 7',
      proSettings: proSettings,
      l10n: l10n,
    );
    final excel = xl.Excel.decodeBytes(bytes);
    expect(excel.tables.keys, [XlsxExporter.sheetNameFor(l10n)]);
    return excel.tables[XlsxExporter.sheetNameFor(l10n)]!;
  }

  List<Object?> valuesOf(List<xl.Data?> row) => [
    for (final cell in row)
      switch (cell?.value) {
        null => null,
        xl.TextCellValue(:final value) => value.toString(),
        xl.IntCellValue(:final value) => value,
        xl.DoubleCellValue(:final value) => value,
        final other => other,
      },
  ];

  /// Cells of the first row whose column A is [label] (trailing empties
  /// dropped).
  List<Object?> rowOf(xl.Sheet sheet, String label) {
    final row = sheet.rows.firstWhere(
      (row) => row.isNotEmpty && valuesOf(row).first == label,
      orElse: () => fail('no row "$label"'),
    );
    final values = valuesOf(row);
    while (values.isNotEmpty && values.last == null) {
      values.removeLast();
    }
    return values;
  }

  test('English: header block, numeric table and check footer', () {
    final sheet = decode(en);

    expect(rowOf(sheet, en.exportDocTitle), [en.exportDocTitle]);
    expect(rowOf(sheet, 'Project'), ['Project', 'Route 7']);
    expect(rowOf(sheet, 'Level book'), ['Level book', 'Loop A']);
    expect(rowOf(sheet, 'Date'), ['Date', '2026-10-16']);
    expect(rowOf(sheet, 'Surveyor'), ['Surveyor', 'Kim']);
    expect(rowOf(sheet, 'Instrument'), ['Instrument', 'DL-500']);
    expect(rowOf(sheet, 'Unit'), ['Unit', 'm']);
    expect(rowOf(sheet, 'BM elevation'), ['BM elevation', 100.0]);

    // Same columns as the PDF (BS | IS | FS for English), no design columns.
    final header = rowOf(sheet, 'No.');
    expect(header, ['No.', 'Station', 'BS', 'IS', 'FS', 'HI', 'RL', 'Remarks']);
    final headerIndex = sheet.rows.indexWhere(
      (row) => row.isNotEmpty && valuesOf(row).first == 'No.',
    );
    final table = [
      for (final row in sheet.rows.skip(headerIndex + 1).take(4))
        valuesOf(row).take(header.length).toList(),
    ];
    expect(table, [
      [1, 'BM.1', 1.5, null, null, 101.5, 100.0, null],
      [2, 'No.1', null, 1.276, null, null, 100.224, null],
      [3, 'TP1', 1.2, null, 1.0, 101.7, 100.5, 'TP'],
      [4, 'END', null, null, 1.1, null, 100.6, null],
    ]);

    // Numbers are numeric cells with a 3-decimal format.
    final rlCell = sheet.rows[headerIndex + 3][6]!;
    expect(rlCell.value, isA<xl.DoubleCellValue>());
    expect(rlCell.cellStyle?.numberFormat.formatCode, '0.000');

    // Check footer: same labels as the PDF check box.
    expect(rowOf(sheet, en.exportCheckTitleWithClosure).length, 1);
    expect(rowOf(sheet, 'ΣBS'), ['ΣBS', 2.7]);
    expect(rowOf(sheet, 'ΣFS'), ['ΣFS', 2.1]);
    final misclosure = rowOf(sheet, en.exportCheckMisclosure);
    expect(misclosure.first, en.exportCheckMisclosure);
    expect(misclosure[1], 0.0);
    expect(rowOf(sheet, en.exportCheckAllowed)[1], isA<double>());
    expect(rowOf(sheet, en.exportCheckResult), [
      en.exportCheckResult,
      en.coreJudgementWithinTolerance,
    ]);
  });

  test('Korean: original layout, Korean labels and verdict', () {
    final sheet = decode(ko, proSettings: const ProPdfSettings());

    expect(rowOf(sheet, '야장명'), ['야장명', 'Loop A']);
    expect(rowOf(sheet, '프로젝트'), ['프로젝트', 'Route 7']);
    expect(rowOf(sheet, '측량자'), ['측량자', 'Kim']);
    expect(rowOf(sheet, '장비'), ['장비', 'DL-500']);
    expect(rowOf(sheet, '단위'), ['단위', 'm']);
    final header = rowOf(sheet, ko.exportColumnNo);
    expect(header, contains(ko.exportColumnHi));
    expect(header, isNot(contains(ko.exportColumnIs)));
    expect(header, isNot(contains(ko.exportColumnDesign)));
    expect(rowOf(sheet, ko.exportCheckSumBs), [ko.exportCheckSumBs, 2.7]);
    expect(rowOf(sheet, ko.exportCheckResult), [
      ko.exportCheckResult,
      ko.coreJudgementWithinTolerance,
    ]);
  });

  test('judgement row follows the PDF setting', () {
    final sheet = decode(
      en,
      proSettings: const ProPdfSettings(includeCheckJudgement: false),
    );
    expect(
      sheet.rows.any(
        (row) => row.isNotEmpty && valuesOf(row).first == en.exportCheckResult,
      ),
      isFalse,
    );
  });

  test('design columns only when the book shows design levels', () {
    final hidden = rowOf(decode(en), 'No.');
    expect(hidden, isNot(contains('Design level')));
    expect(hidden, isNot(contains('Target reading')));

    for (final l10n in [en, ko, es]) {
      final sheet = decode(l10n, fieldBook: book(showDesign: true));
      final header = rowOf(sheet, l10n.exportColumnNo);
      final design = header.indexOf(l10n.exportColumnDesign);
      final cutFill = header.indexOf(l10n.exportColumnCutFill);
      // PDF order: right after RL.
      expect(design, header.indexOf(l10n.exportColumnRl) + 1);
      expect(cutFill, design + 1);
      final target = header.indexOf(l10n.exportColumnTarget);
      expect(target, cutFill + 1);

      // No.1: RL 100.224 − design 100.099 = cut 0.125, stored signed with
      // the localized letters in the number format.
      final headerIndex = sheet.rows.indexWhere(
        (row) => row.isNotEmpty && valuesOf(row).first == l10n.exportColumnNo,
      );
      final no1 = sheet.rows[headerIndex + 2];
      expect(no1[design]!.value, isA<xl.DoubleCellValue>());
      expect(valuesOf(no1)[design], 100.099);
      expect(valuesOf(no1)[cutFill] as double, closeTo(0.125, 1e-9));
      // Target reading: HI 101.500 − 100.099; END uses the TP1 HI 101.700.
      expect(no1[target]!.value, isA<xl.DoubleCellValue>());
      expect(valuesOf(no1)[target] as double, closeTo(1.401, 1e-9));
      final end = valuesOf(sheet.rows[headerIndex + 4]);
      expect(end[target] as double, closeTo(1.06, 1e-9));
      expect(valuesOf(sheet.rows[headerIndex + 1])[target], isNull);
      expect(
        no1[cutFill]!.cellStyle?.numberFormat.formatCode,
        '"${l10n.exportCutLetter} "0.000;"${l10n.exportFillLetter} "0.000;0.000',
      );
    }
  });

  test('rise and fall books export Rise / Fall instead of HI', () {
    final sheet = decode(
      en,
      fieldBook: book(method: ReductionMethod.riseAndFall),
    );
    final header = rowOf(sheet, 'No.');
    expect(header, containsAllInOrder(['FS', 'Rise', 'Fall', 'RL']));
    expect(header, isNot(contains('HI')));
    expect(rowOf(sheet, 'ΣRise')[1], isA<double>());
  });

  test('file name uses the export naming with .xlsx', () {
    expect(
      ExportFileNamer().next(
        fieldBook: book(),
        extension: 'xlsx',
        projectName: 'Route 7',
      ),
      'Loop A.xlsx',
    );
  });
}
