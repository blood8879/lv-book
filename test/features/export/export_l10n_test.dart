import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/export/export_labels.dart';
import 'package:lv_book/features/export/pdf_template.dart';
import 'package:lv_book/features/export/project_submission_package.dart';
import 'package:lv_book/features/export/submission_summary_report.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/import/csv_importer.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';
import 'package:lv_book/l10n/l10n.dart';
import 'package:pdf/pdf.dart' show TtfParser;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = l10nFor(const Locale('en'));

  final fieldBook = FieldBook(
    id: 1,
    projectId: 1,
    title: 'Loop A',
    date: DateTime(2026, 6, 3),
    surveyor: 'Kim',
    checker: 'Park',
    instrument: 'DL-500',
    weather: 'Sunny',
    workSection: 'STA.0+000~0+200',
    jobNumber: 'J-2026-01',
    reviewStatus: FieldBookReviewStatus.reviewed,
    reviewMemo: 'OK by supervisor',
    reviewedAt: DateTime(2026, 6, 8),
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

  String exportEnglishCsv() => CsvExporter.withBom(
    CsvExporter.generateFieldBookCsv(
      fieldBook: fieldBook,
      measurements: measurements,
      bmName: 'BM.1',
      startElevation: 100,
      proSettings: const ProPdfSettings(includeCheckJudgement: true),
      l10n: en,
    ),
  );

  group('English CSV', () {
    test('uses English labels and headers', () {
      final csv = exportEnglishCsv();
      expect(csv, contains('Differential leveling level book'));
      expect(csv, contains('Level book,Loop A'));
      expect(csv, contains('Date,2026-06-03'));
      expect(csv, contains('Surveyor,Kim'));
      expect(csv, contains('Job no.,J-2026-01'));
      expect(csv, contains('Review status,Reviewed'));
      expect(csv, contains('BM elevation,100.000'));
      expect(csv, contains('No.,Station,BS,FS,HI,RL,Remarks'));
      expect(csv, contains('Difference,'));
      expect(csv, contains('Misclosure,'));
      expect(csv, contains('Result,'));
      expect(csv, isNot(contains(RegExp('[가-힣]'))));
      expect(csv, isNot(contains('Fail')));
    });

    test('round trips through the importer (English and Korean UI)', () {
      for (final l10n in [en, l10nKo]) {
        final result = CsvImporter.parse(
          exportEnglishCsv(),
          projectId: 7,
          fallbackDate: DateTime(2000),
          l10n: l10n,
        );
        expect(result.errors, isEmpty);
        expect(result.warnings, isEmpty);
        final imported = result.fieldBook!;
        expect(imported.title, 'Loop A');
        expect(imported.date, DateTime(2026, 6, 3));
        expect(imported.startElevation, 100);
        expect(imported.surveyor, 'Kim');
        expect(imported.checker, 'Park');
        expect(imported.instrument, 'DL-500');
        expect(imported.weather, 'Sunny');
        expect(imported.workSection, 'STA.0+000~0+200');
        expect(imported.jobNumber, 'J-2026-01');

        final rows = result.measurements;
        expect(rows, hasLength(4));
        expect(rows.map((m) => m.stationName), ['BM.1', 'TP1', 'TP2', 'END']);
        expect(rows[1].type, MeasurementType.tp);
        expect(rows[1].manualTp, isFalse);
        expect(rows[2].type, MeasurementType.tp);
        expect(rows[2].manualTp, isTrue);
        expect(rows[3].type, MeasurementType.normal);
        expect(rows[3].fs, 1.1);
        expect(rows[3].gh, 100.6);
      }
    });

    test('hand-edited English headers and lowercase TP are accepted', () {
      const csv =
          'title,Field test\n'
          'date,2026-06-03\n'
          'bm elevation,50.000\n'
          'work section,A\n'
          '\n'
          'No,Station,BS,FS,HI,RL,Remarks\n'
          '1,BM.1,1.000,,51.000,50.000,\n'
          '2,P1,,0.500,,50.500,tp\n';
      final result = CsvImporter.parse(
        csv,
        projectId: 1,
        fallbackDate: DateTime(2000),
        l10n: en,
      );
      expect(result.errors, isEmpty);
      expect(result.fieldBook?.title, 'Field test');
      expect(result.fieldBook?.startElevation, 50);
      expect(result.fieldBook?.workSection, 'A');
      expect(result.measurements[1].type, MeasurementType.tp);
      expect(result.measurements[1].manualTp, isTrue);
    });
  });

  group('Korean legacy CSV', () {
    // Exactly what app versions up to 1.3.0 exported (Pro settings on).
    const legacyCsv =
        '﻿직접수준측량 야장\r\n'
        '회사명,한국측량\r\n'
        '야장명,왕복 야장\r\n'
        '날짜,2026-06-03\r\n'
        '측량자,홍길동\r\n'
        '검측자,김검측\r\n'
        '장비,DL-500\r\n'
        '날씨,맑음\r\n'
        '작업구간,STA.0+000~0+200\r\n'
        '공사번호,J-2026-01\r\n'
        '검토 상태,검토완료\r\n'
        '시작 BM,BM.1\r\n'
        'BM 표고,100.000\r\n'
        '\r\n'
        'No.,측점명,후시(BS),전시(FS),기계고(IH),지반고(GH),비고\r\n'
        '1,BM.1,1.500,,101.500,100.000,\r\n'
        '2,TP1,1.200,1.000,101.700,100.500,TP\r\n'
        '3,TP2,,0.900,,100.800,TP\r\n'
        '4,END,,1.100,,100.600,\r\n'
        '\r\n'
        'ΣBS,2.700,ΣFS,2.100\r\n'
        'ΣBS - ΣFS,0.600\r\n'
        '오차,0.0000\r\n'
        '검산 판정,적합\r\n';

    test('still imports on an English app', () {
      final result = CsvImporter.parse(
        legacyCsv,
        projectId: 3,
        fallbackDate: DateTime(2000),
        l10n: en,
      );
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      final imported = result.fieldBook!;
      expect(imported.title, '왕복 야장');
      expect(imported.date, DateTime(2026, 6, 3));
      expect(imported.startElevation, 100);
      expect(imported.surveyor, '홍길동');
      expect(imported.checker, '김검측');
      expect(imported.instrument, 'DL-500');
      expect(imported.weather, '맑음');
      expect(imported.workSection, 'STA.0+000~0+200');
      expect(imported.jobNumber, 'J-2026-01');
      expect(result.measurements, hasLength(4));
      expect(result.measurements[2].type, MeasurementType.tp);
      expect(result.measurements[2].manualTp, isTrue);
    });

    test('Korean export equals the legacy layout', () {
      final csv = CsvExporter.generateFieldBookCsv(
        fieldBook: fieldBook,
        measurements: measurements,
        bmName: 'BM.1',
        startElevation: 100,
        l10n: l10nKo,
      );
      expect(csv, startsWith('직접수준측량 야장\r\n야장명,Loop A\r\n날짜,2026-06-03'));
      expect(csv, contains('No.,측점명,후시(BS),전시(FS),기계고(IH),지반고(GH),비고'));
      expect(csv, contains('ΣBS - ΣFS,'));
    });
  });

  group('import messages are localized', () {
    test('English errors and warnings', () {
      const badNumber =
          'Level book,X\nBM elevation,100\n\n'
          'No.,Station,BS,FS,HI,RL,Remarks\n1,BM.1,abc,,,\n';
      final error = CsvImporter.parse(
        badNumber,
        projectId: 1,
        fallbackDate: DateTime(2026),
        l10n: en,
      );
      expect(error.errors.single, 'Row 5: BS is not a valid number.');

      final noHeader = CsvImporter.parse(
        'Level book,X\n',
        projectId: 1,
        fallbackDate: DateTime(2026),
        l10n: en,
      );
      expect(
        noHeader.errors.single,
        "Couldn't find the measurement table header.",
      );

      final badDate = CsvImporter.parse(
        'Date,yesterday\n\nNo.,Station,BS,FS,HI,RL,Remarks\n1,BM.1,1,,,\n',
        projectId: 1,
        fallbackDate: DateTime(2026, 1, 2),
        l10n: en,
      );
      expect(
        badDate.warnings.single,
        'Couldn\'t read the date "yesterday", so it was set to 2026-01-02.',
      );

      final garbled = CsvImporter.parse(
        'Level book,�\n',
        projectId: 1,
        fallbackDate: DateTime(2026),
        l10n: en,
      );
      expect(garbled.errors.single, startsWith('Only UTF-8 CSV'));
    });
  });

  group('English PDF', () {
    test('table headers, metadata and signature labels', () {
      expect(exportTableHeaders(en), [
        'No.',
        'Station',
        'BS',
        'FS',
        'HI',
        'RL',
        'Remarks',
      ]);
      final labels = PdfExporter.metadataLabelsForTest(fieldBook, l10n: en);
      expect(labels, contains('Surveyor: Kim'));
      expect(labels, contains('Review status: Reviewed'));
      expect(labels, contains('Review date: 2026-06-08'));
      expect(
        en.exportCheckValue(en.exportCheckMisclosure, '0.0000'),
        'Misclosure = 0.0000',
      );
      expect(
        [
          en.exportSignaturePrepared,
          en.exportSignatureChecked,
          en.exportSignatureApproved,
        ],
        ['Prepared', 'Checked', 'Approved'],
      );
    });

    test('builds with every Pro option in English', () async {
      final bytes = await PdfExporter.generateFieldBookPdf(
        fieldBook: fieldBook.copyWith(memo: 'Memo text'),
        measurements: measurements,
        bmName: 'BM.1',
        startElevation: 100,
        proSettings: const ProPdfSettings(
          companyName: 'Acme Survey',
          authorName: 'Kim',
          includeCheckJudgement: true,
          includeSignatureLines: true,
          documentTemplate: ProDocumentTemplate.submission,
          watermarkText: 'DRAFT',
          footerNote: 'Footer',
        ),
        l10n: en,
      );
      expect(bytes.length, greaterThan(1000));
      expect(latin1.decode(bytes, allowInvalid: true), contains('NotoSansKR'));
    });

    test('NotoSansKR has glyphs for every English export string', () {
      final font = TtfParser(
        ByteData.sublistView(
          File('assets/fonts/NotoSansKR-Regular.ttf').readAsBytesSync(),
        ),
      );
      final arb =
          jsonDecode(File('lib/l10n/src/export_en.arb').readAsStringSync())
              as Map<String, dynamic>;
      final text = StringBuffer('ΣBS ΣFS 0123456789.-=+± m');
      arb.forEach((key, value) {
        if (!key.startsWith('@') && value is String) text.write(value);
      });
      final missing = text
          .toString()
          .runes
          .where((rune) => rune > 0x20)
          .where((rune) => !font.charToGlyphIndexMap.containsKey(rune))
          .map(String.fromCharCode)
          .toSet();
      expect(missing, isEmpty);
    });
  });

  test('English summary CSV and manifest', () {
    final summary = SubmissionSummaryReport.generateCsv([
      FieldBookSummaryInput(
        fieldBook: fieldBook,
        bmName: 'BM.1',
        startElevation: 100,
        measurements: measurements,
      ),
    ], l10n: en);
    expect(
      summary,
      startsWith(
        'Level book,Date,Start BM,Section,Surveyor,Review status,'
        'Review memo,Review date,Misclosure,Result\n',
      ),
    );
    expect(summary, contains('Reviewed'));
    expect(
      summary,
      anyOf(contains('Within tolerance'), contains('Check required')),
    );

    final manifest = ProjectSubmissionPackage.buildManifest(
      projectName: '',
      fieldBooks: [fieldBook],
      measurementsByFieldBookId: {1: measurements},
      fileNames: const ['Loop A.pdf'],
      l10n: en,
    );
    expect(manifest, contains('Lv Book submission package'));
    expect(manifest, contains('Site: Site name not set'));
    expect(manifest, contains('- Loop A: 4 stations, review status Reviewed'));
    expect(manifest, contains('  Review memo: OK by supervisor'));
    expect(manifest, contains('Included files'));

    expect(
      const ProjectSubmissionPackageException(
        ProjectSubmissionPackageError.noFiles,
      ).localizedMessage(en),
      'There are no files to package.',
    );
    expect(
      const SubmissionSummaryException(
        SubmissionSummaryError.noSelection,
      ).message,
      '요약할 야장을 선택하세요.',
    );
  });
}
