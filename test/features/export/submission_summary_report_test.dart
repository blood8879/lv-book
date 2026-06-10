import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/submission_summary_report.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';

void main() {
  test(
    'summary report includes closure error and judgement per field book',
    () {
      final rows = SubmissionSummaryReport.buildRows([
        FieldBookSummaryInput(
          fieldBook: FieldBook(
            projectId: 1,
            title: '적합 야장',
            date: DateTime(2026, 6, 8),
            workSection: 'A구간',
            surveyor: '김측량',
          ),
          bmName: 'BM.1',
          startElevation: 100,
          measurements: [
            Measurement(
              fieldBookId: 1,
              orderIndex: 0,
              stationName: 'BM.1',
              bs: 1,
            ),
            Measurement(
              fieldBookId: 1,
              orderIndex: 1,
              stationName: 'No.1',
              fs: 1,
            ),
          ],
        ),
        FieldBookSummaryInput(
          fieldBook: FieldBook(
            projectId: 1,
            title: '확인 야장',
            date: DateTime(2026, 6, 8),
          ),
          bmName: 'BM.2',
          startElevation: 100,
          measurements: [
            Measurement(
              fieldBookId: 2,
              orderIndex: 0,
              stationName: 'BM.2',
              fs: 1,
            ),
          ],
        ),
      ]);

      expect(rows.map((row) => row.judgement), containsAll(['적합', '확인 필요']));
    },
  );

  test('summary report rejects empty field book selection', () {
    expect(
      () => SubmissionSummaryReport.buildRows(const []),
      throwsA(isA<SubmissionSummaryException>()),
    );
  });
}
