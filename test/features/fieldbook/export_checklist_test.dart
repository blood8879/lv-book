import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_validation.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';

void main() {
  test('valid field book shows all checklist items passing', () {
    final result = MeasurementValidation.validate(
      measurements: [
        Measurement(
          fieldBookId: 1,
          orderIndex: 0,
          stationName: 'BM.1',
          bs: 1.2,
          ih: 101.2,
          gh: 100,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 1,
          stationName: 'TP.1',
          type: MeasurementType.tp,
          bs: 0.8,
          fs: 1.2,
          ih: 100.8,
          gh: 100,
          manualTp: true,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 2,
          stationName: 'BM.2',
          fs: 0.8,
          gh: 100,
        ),
      ],
      startElevation: 100,
      tolerance: const MisclosureTolerance.fixed(1),
    );

    expect(result.canExport, isTrue);
    expect(result.checklist, isNotEmpty);
    expect(result.checklist.every((item) => item.passed), isTrue);
  });

  test('missing first BS blocks export from checklist', () {
    final result = MeasurementValidation.validate(
      measurements: [
        Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'No.1', fs: 1),
      ],
      startElevation: 100,
    );

    expect(result.canExport, isFalse);
    expect(
      result.checklist.where((item) => !item.passed).map((item) => item.label),
      contains('첫 BS'),
    );
  });
}
