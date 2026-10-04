import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/export/pdf_template.dart';
import 'package:lv_book/features/export/submission_summary_report.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/import/csv_importer.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';
import 'package:lv_book/features/project/data/sample_project_service.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  final en = l10nFor(const Locale('en'));
  final ko = l10nKo;
  // Sample loop: BM-1 100.000 → … → BM-1, final RL 100.001.
  final measurements = SampleProjectService.buildMeasurements(fieldBookId: 1);

  FieldBook book(ClosingReferenceMode mode, {int? bmId, double? elevation}) =>
      FieldBook(
        id: 1,
        projectId: 1,
        title: 'Loop',
        date: DateTime(2026, 10, 4),
        startElevation: 100,
        closingMode: mode,
        closingBmId: bmId,
        closingElevation: elevation,
      );

  String csv(
    FieldBook fieldBook,
    AppLocalizations l10n, {
    String? closingBmName,
    MisclosureTolerance tolerance = MisclosureTolerance.defaults,
  }) => CsvExporter.withBom(
    CsvExporter.generateFieldBookCsv(
      fieldBook: fieldBook,
      measurements: measurements,
      bmName: 'BM-1',
      startElevation: 100,
      closingBmName: closingBmName,
      tolerance: tolerance,
      proSettings: const ProPdfSettings(includeCheckJudgement: true),
      l10n: l10n,
    ),
  );

  FieldBook import(String text, AppLocalizations l10n) {
    final result = CsvImporter.parse(
      text,
      projectId: 2,
      fallbackDate: DateTime(2000),
      l10n: l10n,
    );
    expect(result.errors, isEmpty);
    expect(result.measurements, hasLength(6));
    return result.fieldBook!;
  }

  group('CSV', () {
    test('loop: metadata, misclosure +0.0010, allowed and result', () {
      final english = csv(book(ClosingReferenceMode.loop), en);
      expect(english, contains('Closing BM,BM-1\r\n'));
      expect(english, contains('Closing RL,100.000\r\n'));
      expect(english, contains('Final - Start,0.001\r\n'));
      expect(english, contains('Misclosure,+0.0010\r\n'));
      expect(english, contains('Allowed,±0.0010\r\n'));
      expect(english, contains('Result,Within tolerance'));

      final korean = csv(book(ClosingReferenceMode.loop), ko);
      expect(korean, contains('폐합 BM,BM-1\r\n'));
      expect(korean, contains('폐합 표고,100.000\r\n'));
      expect(korean, contains('폐합오차,+0.0010\r\n'));
      expect(korean, contains('검산 판정,적합'));
    });

    test('c·√n tolerance and an exceeded misclosure', () {
      final relaxed = csv(
        book(ClosingReferenceMode.manual, elevation: 99.995),
        en,
        tolerance: const MisclosureTolerance.sqrtSetups(5),
      );
      // 3 setups (BM-1, TP-1, TP-2): 5·√3 = 8.66 mm; misclosure +6 mm.
      expect(relaxed, contains('Misclosure,+0.0060\r\n'));
      expect(relaxed, contains('Allowed,±0.0087\r\n'));
      expect(relaxed, contains('Result,Within tolerance'));

      final strict = csv(
        book(ClosingReferenceMode.manual, elevation: 99.995),
        en,
      );
      expect(strict, contains('Result,Check required'));
      expect(strict, isNot(contains('Fail')));
    });

    test('no closing reference: misclosure not available', () {
      final english = csv(book(ClosingReferenceMode.none), en);
      expect(english, isNot(contains('Closing')));
      expect(english, contains('Misclosure,n/a (no closing RL)'));
      expect(english, contains('Result,Within tolerance'));
    });

    test('round trips in both languages', () {
      for (final exportL10n in [en, ko]) {
        for (final importL10n in [en, ko]) {
          final loop = import(
            csv(book(ClosingReferenceMode.loop), exportL10n),
            importL10n,
          );
          expect(loop.closingMode, ClosingReferenceMode.loop);
          expect(loop.closingElevationFor(100), 100);

          final manual = import(
            csv(
              book(ClosingReferenceMode.manual, elevation: 99.9996),
              exportL10n,
            ),
            importL10n,
          );
          expect(manual.closingMode, ClosingReferenceMode.manual);
          // Exports keep 3 decimals.
          expect(manual.closingElevation, 100.000);

          // A BM id can't travel in a CSV: the closing RL is kept as manual.
          final bm = import(
            csv(
              book(ClosingReferenceMode.benchmark, bmId: 5, elevation: 101.25),
              exportL10n,
              closingBmName: 'BM-2',
            ),
            importL10n,
          );
          expect(bm.closingMode, ClosingReferenceMode.manual);
          expect(bm.closingBmId, isNull);
          expect(bm.closingElevation, 101.25);

          final none = import(
            csv(book(ClosingReferenceMode.none), exportL10n),
            importL10n,
          );
          expect(none.closingMode, ClosingReferenceMode.none);
          expect(none.closingElevation, isNull);
        }
      }
    });

    test('older CSVs without closing rows import as none', () {
      const legacy =
          '야장명,왕복 야장\r\n'
          '날짜,2026-06-03\r\n'
          '시작 BM,BM.1\r\n'
          'BM 표고,100.000\r\n'
          '\r\n'
          'No.,측점명,후시(BS),전시(FS),기계고(IH),지반고(GH),비고\r\n'
          '1,BM.1,1.500,,101.500,100.000,\r\n'
          '2,END,,1.500,,100.000,\r\n';
      final result = CsvImporter.parse(
        legacy,
        projectId: 1,
        fallbackDate: DateTime(2000),
        l10n: en,
      );
      expect(result.errors, isEmpty);
      expect(result.fieldBook!.closingMode, ClosingReferenceMode.none);
    });
  });

  group('PDF', () {
    test('header and check box show closing RL, misclosure and allowed', () {
      expect(
        PdfExporter.closingLabelsForTest(
          book(ClosingReferenceMode.loop),
          startElevation: 100,
          bmName: 'BM-1',
          l10n: en,
        ),
        ['Closing BM: BM-1 (loop)', 'Closing RL: 100.000 m'],
      );
      expect(
        PdfExporter.closingLabelsForTest(
          book(ClosingReferenceMode.benchmark, bmId: 3, elevation: 101.25),
          startElevation: 100,
          bmName: 'BM-1',
          closingBmName: 'BM-2',
          l10n: ko,
        ),
        ['폐합 BM: BM-2', '폐합 표고: 101.250 m'],
      );
      expect(
        PdfExporter.closingLabelsForTest(
          book(ClosingReferenceMode.none),
          startElevation: 100,
          bmName: 'BM-1',
          l10n: en,
        ),
        isEmpty,
      );

      final closure = LevelClosureCheck.compute(
        measurements,
        startElevation: 100,
        closingElevation: 100,
        tolerance: const MisclosureTolerance.fixed(5),
      );
      final rows = PdfExporter.checkRowsForTest(closure, l10n: en);
      expect(rows[1].last, ('Final - Start', '0.001'));
      expect(rows[2], [
        ('Closing RL', '100.000'),
        ('Misclosure', '+0.0010'),
        ('Allowed', '±0.0050'),
      ]);

      final noClosing = PdfExporter.checkRowsForTest(
        LevelClosureCheck.compute(measurements, startElevation: 100),
        l10n: en,
      );
      expect(noClosing.last, [('Misclosure', 'n/a (no closing RL)')]);
    });

    test('builds with a closing reference in both languages', () async {
      for (final l10n in [en, ko]) {
        final bytes = await PdfExporter.generateFieldBookPdf(
          fieldBook: book(ClosingReferenceMode.loop),
          measurements: measurements,
          bmName: 'BM-1',
          startElevation: 100,
          tolerance: const MisclosureTolerance.sqrtSetups(5),
          proSettings: const ProPdfSettings(includeCheckJudgement: true),
          l10n: l10n,
        );
        expect(bytes.length, greaterThan(1000));
      }
    });
  });

  test('summary report uses the misclosure when known', () {
    final rows = SubmissionSummaryReport.buildRows([
      FieldBookSummaryInput(
        fieldBook: book(ClosingReferenceMode.loop),
        bmName: 'BM-1',
        startElevation: 100,
        measurements: measurements,
      ),
      FieldBookSummaryInput(
        fieldBook: book(ClosingReferenceMode.manual, elevation: 99.99),
        bmName: 'BM-1',
        startElevation: 100,
        measurements: measurements,
      ),
      FieldBookSummaryInput(
        fieldBook: book(ClosingReferenceMode.none),
        bmName: 'BM-1',
        startElevation: 100,
        measurements: measurements,
      ),
    ], l10n: en);
    expect(rows[0].misclosure, closeTo(0.001, 1e-9));
    expect(rows[0].judgement, 'Within tolerance');
    expect(rows[1].judgement, 'Check required');
    expect(rows[2].misclosure, isNull);
    expect(rows[2].judgement, 'Within tolerance');

    final summaryCsv = SubmissionSummaryReport.generateCsv([
      FieldBookSummaryInput(
        fieldBook: book(ClosingReferenceMode.loop),
        bmName: 'BM-1',
        startElevation: 100,
        measurements: measurements,
      ),
    ], l10n: en);
    expect(summaryCsv, contains(',+0.0010,Within tolerance'));
  });
}
