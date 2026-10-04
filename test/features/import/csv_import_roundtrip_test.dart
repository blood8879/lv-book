import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/utils/text_file_picker.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/import/csv_importer.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  final fieldBook = FieldBook(
    projectId: 1,
    title: '왕복 야장',
    date: DateTime(2026, 6, 3),
    surveyor: '홍길동',
    checker: '김검측',
    instrument: 'DL-500',
    weather: '맑음',
    workSection: 'STA.0+000~0+200',
    jobNumber: 'J-2026-01',
  );
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
      stationName: 'TP1',
      type: MeasurementType.tp,
      bs: 1.2,
      fs: 1.0,
      ih: 101.7,
      gh: 100.5,
    ),
    // Manually marked TP (FS only) — auto-detection would not flag it.
    Measurement(
      fieldBookId: 1,
      orderIndex: 2,
      stationName: 'TP2',
      type: MeasurementType.tp,
      fs: 0.9,
      gh: 100.8,
      manualTp: true,
    ),
    Measurement(
      fieldBookId: 1,
      orderIndex: 3,
      stationName: 'END',
      fs: 1.1,
      gh: 100.6,
    ),
  ];

  String exportCsv() => CsvExporter.withBom(
    CsvExporter.generateFieldBookCsv(
      fieldBook: fieldBook,
      measurements: measurements,
      bmName: 'BM.1',
      startElevation: 100,
      l10n: l10nKo,
    ),
  );

  test('exported CSV starts with a UTF-8 BOM and imports cleanly', () {
    final csv = exportCsv();
    expect(csv.startsWith('﻿'), isTrue);
    expect(CsvExporter.withBom(csv), csv);

    final decoded = TextFilePicker.decodeUtf8(utf8.encode(csv));
    expect(decoded.startsWith('﻿'), isFalse);

    final result = CsvImporter.parse(
      csv,
      projectId: 1,
      fallbackDate: DateTime(2000),
      l10n: l10nKo,
    );
    expect(result.errors, isEmpty);
    expect(result.fieldBook?.title, '왕복 야장');
    expect(result.measurements, hasLength(4));
  });

  test('metadata round trips through CSV', () {
    final result = CsvImporter.parse(
      exportCsv(),
      projectId: 7,
      fallbackDate: DateTime(2000),
      l10n: l10nKo,
    );
    final imported = result.fieldBook!;
    expect(imported.projectId, 7);
    expect(imported.date, DateTime(2026, 6, 3));
    expect(imported.startElevation, 100);
    expect(imported.surveyor, '홍길동');
    expect(imported.checker, '김검측');
    expect(imported.instrument, 'DL-500');
    expect(imported.weather, '맑음');
    expect(imported.workSection, 'STA.0+000~0+200');
    expect(imported.jobNumber, 'J-2026-01');
    expect(result.warnings, isEmpty);
  });

  test('manualTp is set only for TP rows auto-detection would miss', () {
    final rows = CsvImporter.parse(
      exportCsv(),
      projectId: 1,
      fallbackDate: DateTime(2000),
      l10n: l10nKo,
    ).measurements;

    expect(rows[1].type, MeasurementType.tp);
    expect(rows[1].manualTp, isFalse);
    expect(rows[2].type, MeasurementType.tp);
    expect(rows[2].manualTp, isTrue);
    expect(rows[0].manualTp, isFalse);
    expect(rows[3].type, MeasurementType.normal);
    expect(rows[3].manualTp, isFalse);
  });

  test('date variants are accepted; unparseable date warns', () {
    expect(CsvImporter.parseDate('2026/6/3'), DateTime(2026, 6, 3));
    expect(CsvImporter.parseDate('2026.6.3'), DateTime(2026, 6, 3));
    expect(CsvImporter.parseDate('2026. 6. 3.'), DateTime(2026, 6, 3));
    expect(CsvImporter.parseDate('2026-06-03'), DateTime(2026, 6, 3));
    expect(CsvImporter.parseDate('2026-02-31'), isNull);

    const csv =
        '야장명,날짜오류\n날짜,어제\nBM 표고,100.000\n\nNo.,측점명,후시(BS),전시(FS),기계고(IH),지반고(GH),비고\n1,BM.1,1.000,,101.000,100.000,\n';
    final result = CsvImporter.parse(
      csv,
      projectId: 1,
      fallbackDate: DateTime(2026, 1, 2),
      l10n: l10nKo,
    );
    expect(result.fieldBook?.date, DateTime(2026, 1, 2));
    expect(result.warnings.single, contains('어제'));
  });

  test('malformed UTF-8 (CP949) is rejected with a clear message', () {
    // "측량" encoded in CP949.
    const cp949 = [0xC3, 0xF8, 0xB7, 0xAE];
    expect(
      () => TextFilePicker.decodeUtf8(cp949),
      throwsA(isA<TextFileEncodingException>()),
    );

    final result = CsvImporter.parse(
      '야장명,��\n',
      projectId: 1,
      fallbackDate: DateTime(2026),
      l10n: l10nKo,
    );
    expect(result.fieldBook, isNull);
    expect(result.errors.single, contains('UTF-8'));
  });
}
