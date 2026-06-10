import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_row_actions.dart';

void main() {
  test('insert and duplicate keep row order and recalculation stable', () {
    final rows = [
      Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'BM.1', bs: 1),
      Measurement(fieldBookId: 1, orderIndex: 1, stationName: 'No.1', fs: 0.5),
    ];

    final inserted = MeasurementRowActions.insertBelow(
      rows,
      index: 0,
      fieldBookId: 1,
      stationName: 'No.0',
    );
    final duplicated = MeasurementRowActions.duplicate(
      inserted,
      index: 1,
      fieldBookId: 1,
    );

    expect(duplicated.map((row) => row.orderIndex), [0, 1, 2, 3]);
    expect(duplicated[2].stationName, 'No.0 복사');
  });

  test('manual TP override persists after reopen', () {
    final row = Measurement(
      fieldBookId: 1,
      orderIndex: 1,
      stationName: 'TP.1',
      bs: 1.2,
      fs: 0.8,
    ).copyWith(type: MeasurementType.tp, manualTp: true);

    final reloaded = Measurement.fromMap(row.toMap());

    expect(reloaded.type, MeasurementType.tp);
    expect(reloaded.manualTp, isTrue);
  });
}
