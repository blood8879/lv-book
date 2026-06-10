import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook_templates.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';

void main() {
  test('duplicate field book copies station names without readings', () {
    final source = FieldBook(
      id: 10,
      projectId: 1,
      title: '원본',
      date: DateTime(2026, 6, 3),
      surveyor: '김측량',
    );
    final duplicate = FieldBookTemplates.duplicateStructure(
      source: source,
      measurements: [
        Measurement(fieldBookId: 10, orderIndex: 0, stationName: 'BM.1', bs: 1),
      ],
      newDate: DateTime(2026, 6, 4),
    );

    expect(duplicate.fieldBook.title, '원본 복사');
    expect(duplicate.fieldBook.surveyor, '김측량');
    expect(duplicate.measurements.single.stationName, 'BM.1');
    expect(duplicate.measurements.single.bs, isNull);
    expect(duplicate.measurements.single.fs, isNull);
  });

  test('station template generates requested row count', () {
    final rows = FieldBookTemplates.noPrefixRows(fieldBookId: 1, count: 10);

    expect(rows.length, 10);
    expect(rows.first.stationName, 'No.1');
    expect(rows.last.stationName, 'No.10');
  });
}
