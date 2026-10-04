import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_validation.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';

void main() {
  test('valid closed loop displays suitable judgement', () {
    final result = MeasurementValidation.validate(
      measurements: [
        Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'BM.1', bs: 1),
        Measurement(fieldBookId: 1, orderIndex: 1, stationName: 'No.1', fs: 1),
      ],
      startElevation: 100,
      tolerance: const MisclosureTolerance.fixed(1),
    );

    expect(result.judgementLabel, '적합');
    expect(result.canExport, isTrue);
  });

  test('missing first BS blocks export with message', () {
    final result = MeasurementValidation.validate(
      measurements: [
        Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'No.1', fs: 1),
      ],
      startElevation: 100,
      tolerance: const MisclosureTolerance.fixed(1),
    );

    expect(result.canExport, isFalse);
    expect(result.messages, contains('첫 행에는 후시(BS)가 필요합니다.'));
  });
}
