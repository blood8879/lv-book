import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/import/csv_importer.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  test('imports CSV exported by Lv Book into a new field book', () {
    final csv = CsvExporter.generateFieldBookCsv(
      fieldBook: FieldBook(
        projectId: 1,
        title: '가져오기 야장',
        date: DateTime(2026, 6, 3),
      ),
      measurements: [
        Measurement(
          fieldBookId: 1,
          orderIndex: 0,
          stationName: 'BM.1',
          bs: 1,
          ih: 101,
          gh: 100,
        ),
      ],
      bmName: 'BM.1',
      startElevation: 100,
      l10n: l10nKo,
    );

    final result = CsvImporter.parse(
      csv,
      projectId: 1,
      fallbackDate: DateTime(2026, 6, 3),
      l10n: l10nKo,
    );

    expect(result.errors, isEmpty);
    expect(result.fieldBook?.title, '가져오기 야장');
    expect(result.measurements.single.stationName, 'BM.1');
    expect(result.measurements.single.bs, 1);
  });

  test('malformed numeric cell is reported with row number', () {
    const csv =
        '직접수준측량 야장\n야장명,오류\n날짜,2026-06-03\n시작 BM,BM.1\nBM 표고,100.000\n\nNo.,측점명,후시(BS),전시(FS),기계고(IH),지반고(GH),비고\n1,BM.1,abc,,,\n';

    final result = CsvImporter.parse(
      csv,
      projectId: 1,
      fallbackDate: DateTime(2026, 6, 3),
      l10n: l10nKo,
    );

    expect(result.fieldBook, isNull);
    expect(result.errors.single, contains('8행'));
  });
}
