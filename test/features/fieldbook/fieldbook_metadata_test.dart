import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';

void main() {
  test('metadata saves and reloads with field book', () {
    final fieldBook = FieldBook(
      projectId: 1,
      title: 'A구간 야장',
      date: DateTime(2026, 6, 3),
      surveyor: '김측량',
      checker: '박검측',
      instrument: '레벨기-01',
      weather: '맑음',
      workSection: 'STA.0+000~0+120',
      jobNumber: 'LV-2026-01',
    );

    final reloaded = FieldBook.fromMap(fieldBook.toMap());

    expect(reloaded.surveyor, '김측량');
    expect(reloaded.checker, '박검측');
    expect(reloaded.instrument, '레벨기-01');
    expect(reloaded.weather, '맑음');
    expect(reloaded.workSection, 'STA.0+000~0+120');
    expect(reloaded.jobNumber, 'LV-2026-01');
  });

  test('empty metadata is omitted from exports', () {
    final csv = CsvExporter.generateFieldBookCsv(
      fieldBook: FieldBook(
        projectId: 1,
        title: '빈 메타 야장',
        date: DateTime(2026, 6, 3),
      ),
      measurements: const [],
      bmName: 'BM.1',
      startElevation: 100,
    );

    expect(csv, isNot(contains('측량자')));
    expect(csv, isNot(contains('검측자')));
    expect(csv, isNot(contains('작업구간')));
  });
}
