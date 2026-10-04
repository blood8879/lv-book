import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/export/export_judgement.dart';
import 'package:lv_book/features/export/submission_summary_report.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_validation.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  test(
    'exactly tolerance closure error is suitable across export judgement',
    () {
      final fieldBook = FieldBook(
        projectId: 1,
        title: '경계 야장',
        date: DateTime(2026, 6, 8),
      );
      final measurements = [
        Measurement(
          fieldBookId: 1,
          orderIndex: 0,
          stationName: 'BM.1',
          bs: 1,
          gh: 100,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 1,
          stationName: 'END',
          fs: 0.999,
          gh: 100,
        ),
      ];

      final validation = MeasurementValidation.validate(
        measurements: measurements,
        startElevation: 100,
      );
      final csv = CsvExporter.generateFieldBookCsv(
        fieldBook: fieldBook,
        measurements: measurements,
        bmName: 'BM.1',
        startElevation: 100,
        proSettings: const ProPdfSettings(includeCheckJudgement: true),
        l10n: l10nKo,
      );
      final summary = SubmissionSummaryReport.buildRows([
        FieldBookSummaryInput(
          fieldBook: fieldBook,
          bmName: 'BM.1',
          startElevation: 100,
          measurements: measurements,
        ),
      ], l10n: l10nKo).single;

      expect(ExportJudgement.isSuitable(0.001), isTrue);
      expect(validation.judgementLabel, '적합');
      expect(csv, contains('검산 판정,적합'));
      expect(summary.judgement, '적합');
    },
  );
}
