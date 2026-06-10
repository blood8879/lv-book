import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/export/pdf_template.dart';
import 'package:lv_book/features/export/project_submission_package.dart';
import 'package:lv_book/features/export/submission_summary_report.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('unknown stored review status falls back to draft', () {
    final fieldBook = FieldBook.fromMap({
      'id': 1,
      'project_id': 1,
      'title': '검토 야장',
      'date': DateTime(2026, 6, 8).toIso8601String(),
      'review_status': 'unknown_from_old_db',
      'created_at': DateTime(2026, 6, 8).toIso8601String(),
    });

    expect(fieldBook.reviewStatus, FieldBookReviewStatus.draft);
    expect(fieldBook.reviewStatus.label, '작성중');
  });

  test('legacy stored review statuses map to current local statuses', () {
    expect(
      FieldBookReviewStatusLabel.parse('approved'),
      FieldBookReviewStatus.reviewed,
    );
    expect(
      FieldBookReviewStatusLabel.parse('rejected'),
      FieldBookReviewStatus.needsCheck,
    );
    expect(
      FieldBookReviewStatusLabel.parse('inReview'),
      FieldBookReviewStatus.needsCheck,
    );
  });

  test('review metadata round-trips and can be cleared with copyWith', () {
    final fieldBook = _reviewedFieldBook();
    final mapped = FieldBook.fromMap(fieldBook.toMap());

    expect(mapped.reviewStatus, FieldBookReviewStatus.reviewed);
    expect(mapped.toMap()['review_status'], 'reviewed');
    expect(mapped.reviewMemo, '감리 확인 완료');
    expect(mapped.reviewedAt, DateTime(2026, 6, 8));

    final cleared = mapped.copyWith(reviewMemo: null, reviewedAt: null);
    expect(cleared.reviewStatus, FieldBookReviewStatus.reviewed);
    expect(cleared.reviewMemo, isNull);
    expect(cleared.reviewedAt, isNull);
  });

  test('review status memo and date appear in Pro CSV output', () {
    final csv = CsvExporter.generateFieldBookCsv(
      fieldBook: _reviewedFieldBook(),
      measurements: _measurements(),
      bmName: 'BM.1',
      startElevation: 100,
      proSettings: const ProPdfSettings(),
    );

    expect(csv, contains('검토 상태,검토완료'));
    expect(csv, contains('검토 메모,감리 확인 완료'));
    expect(csv, contains('검토일,2026-06-08'));
  });

  test(
    'review status memo and date are included in Pro PDF metadata',
    () async {
      final fieldBook = _reviewedFieldBook();
      final labels = PdfExporter.metadataLabelsForTest(fieldBook);

      expect(labels, contains('검토 상태: 검토완료'));
      expect(labels, contains('검토 메모: 감리 확인 완료'));
      expect(labels, contains('검토일: 2026-06-08'));

      final bytes = await PdfExporter.generateFieldBookPdf(
        fieldBook: fieldBook,
        measurements: _measurements(),
        bmName: 'BM.1',
        startElevation: 100,
        proSettings: const ProPdfSettings(),
      );

      expect(bytes.length, greaterThan(1000));
      expect(latin1.decode(bytes, allowInvalid: true), contains('NotoSansKR'));
    },
  );

  test('review status appears in summary and submission manifest', () {
    final fieldBook = _reviewedFieldBook().copyWith(id: 1);
    final summary = SubmissionSummaryReport.generateCsv([
      FieldBookSummaryInput(
        fieldBook: fieldBook,
        bmName: 'BM.1',
        startElevation: 100,
        measurements: _measurements(),
      ),
    ]);
    final manifest = ProjectSubmissionPackage.buildManifest(
      projectName: '현장 A',
      fieldBooks: [fieldBook],
      measurementsByFieldBookId: {1: _measurements()},
      fileNames: const ['야장.pdf'],
    );

    expect(summary, contains('검토완료'));
    expect(summary, contains('감리 확인 완료'));
    expect(summary, contains('2026-06-08'));
    expect(manifest, contains('검토 상태 검토완료'));
    expect(manifest, contains('검토 메모: 감리 확인 완료'));
    expect(manifest, contains('검토일: 2026-06-08'));
  });

  test('summary report includes needs-check review status', () {
    final fieldBook = _reviewedFieldBook().copyWith(
      id: 1,
      reviewStatus: FieldBookReviewStatus.needsCheck,
      reviewMemo: '재확인 필요',
    );
    final summary = SubmissionSummaryReport.generateCsv([
      FieldBookSummaryInput(
        fieldBook: fieldBook,
        bmName: 'BM.1',
        startElevation: 100,
        measurements: _measurements(),
      ),
    ]);

    expect(summary, contains('확인필요'));
    expect(summary, contains('재확인 필요'));
  });
}

FieldBook _reviewedFieldBook() {
  return FieldBook(
    projectId: 1,
    title: '검토 야장',
    date: DateTime(2026, 6, 8),
    reviewStatus: FieldBookReviewStatus.reviewed,
    reviewMemo: '감리 확인 완료',
    reviewedAt: DateTime(2026, 6, 8),
  );
}

List<Measurement> _measurements() {
  return [
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
      fs: 1,
      gh: 100,
    ),
  ];
}
