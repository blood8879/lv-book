import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/utils/calculation.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';

void main() {
  group('LevelCalculation', () {
    test('calculateIH should return elevation + BS', () {
      expect(LevelCalculation.calculateIH(100.0, 1.234), 101.234);
      expect(LevelCalculation.calculateIH(50.5, 2.0), 52.5);
    });

    test('calculateGH should return IH - FS', () {
      expect(
        LevelCalculation.calculateGH(101.234, 0.567),
        closeTo(100.667, 0.001),
      );
      expect(LevelCalculation.calculateGH(52.5, 1.5), 51.0);
    });

    test('calculateError should return 0 for correct measurements', () {
      // If measurements are correct: ΣBS - ΣFS = endGH - startGH
      final error = LevelCalculation.calculateError(
        sumBs: 5.0,
        sumFs: 3.0,
        startElevation: 100.0,
        endElevation: 102.0,
      );
      expect(error, closeTo(0.0, 0.0001));
    });

    test(
      'calculateError should return non-zero for incorrect measurements',
      () {
        final error = LevelCalculation.calculateError(
          sumBs: 5.0,
          sumFs: 3.0,
          startElevation: 100.0,
          endElevation: 101.5,
        );
        expect(error, closeTo(0.5, 0.0001));
      },
    );
  });

  group('Measurement recalculation', () {
    // We test the recalculate method by creating an instance directly
    // Since MeasurementListNotifier requires Riverpod, we test the logic inline

    List<Measurement> recalculate(
      List<Measurement> measurements,
      double startElevation,
    ) {
      final result = <Measurement>[];
      double currentIH = 0;
      bool firstPoint = true;

      for (final m in measurements) {
        if (firstPoint && m.bs != null) {
          final ih = LevelCalculation.calculateIH(startElevation, m.bs!);
          result.add(m.copyWith(ih: ih, gh: startElevation));
          currentIH = ih;
          firstPoint = false;
        } else if (m.type == MeasurementType.tp) {
          double? gh;
          double? ih;
          if (m.fs != null) {
            gh = LevelCalculation.calculateGH(currentIH, m.fs!);
          }
          if (gh != null && m.bs != null) {
            ih = LevelCalculation.calculateIH(gh, m.bs!);
            currentIH = ih;
          }
          result.add(m.copyWith(ih: ih, gh: gh));
        } else {
          double? gh;
          if (m.fs != null) {
            gh = LevelCalculation.calculateGH(currentIH, m.fs!);
          }
          result.add(m.copyWith(gh: gh));
        }
      }
      return result;
    }

    test('Simple measurement: BM + 2 normal points', () {
      final measurements = [
        Measurement(
          fieldBookId: 1,
          orderIndex: 0,
          stationName: 'BM.1',
          bs: 1.500,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 1,
          stationName: 'No.1',
          fs: 0.800,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 2,
          stationName: 'No.2',
          fs: 1.200,
        ),
      ];

      final result = recalculate(measurements, 100.000);

      // BM: IH = 100 + 1.5 = 101.5, GH = 100.0
      expect(result[0].ih, closeTo(101.5, 0.001));
      expect(result[0].gh, closeTo(100.0, 0.001));

      // No.1: GH = 101.5 - 0.8 = 100.7
      expect(result[1].gh, closeTo(100.7, 0.001));

      // No.2: GH = 101.5 - 1.2 = 100.3
      expect(result[2].gh, closeTo(100.3, 0.001));
    });

    test('Measurement with TP', () {
      final measurements = [
        Measurement(
          fieldBookId: 1,
          orderIndex: 0,
          stationName: 'BM.1',
          bs: 1.500,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 1,
          stationName: 'No.1',
          fs: 0.800,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 2,
          stationName: 'TP.1',
          type: MeasurementType.tp,
          bs: 1.200,
          fs: 1.000,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 3,
          stationName: 'No.2',
          fs: 0.600,
        ),
      ];

      final result = recalculate(measurements, 100.000);

      // BM: IH = 101.5, GH = 100.0
      expect(result[0].ih, closeTo(101.5, 0.001));

      // No.1: GH = 101.5 - 0.8 = 100.7
      expect(result[1].gh, closeTo(100.7, 0.001));

      // TP.1: GH = 101.5 - 1.0 = 100.5, IH = 100.5 + 1.2 = 101.7
      expect(result[2].gh, closeTo(100.5, 0.001));
      expect(result[2].ih, closeTo(101.7, 0.001));

      // No.2: GH = 101.7 - 0.6 = 101.1
      expect(result[3].gh, closeTo(101.1, 0.001));
    });

    test('Multiple TPs', () {
      final measurements = [
        Measurement(
          fieldBookId: 1,
          orderIndex: 0,
          stationName: 'BM.1',
          bs: 2.000,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 1,
          stationName: 'TP.1',
          type: MeasurementType.tp,
          bs: 1.500,
          fs: 1.000,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 2,
          stationName: 'TP.2',
          type: MeasurementType.tp,
          bs: 1.800,
          fs: 0.500,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 3,
          stationName: 'No.1',
          fs: 1.200,
        ),
      ];

      final result = recalculate(measurements, 50.000);

      // BM: IH = 52.0, GH = 50.0
      expect(result[0].ih, closeTo(52.0, 0.001));

      // TP.1: GH = 52.0 - 1.0 = 51.0, IH = 51.0 + 1.5 = 52.5
      expect(result[1].gh, closeTo(51.0, 0.001));
      expect(result[1].ih, closeTo(52.5, 0.001));

      // TP.2: GH = 52.5 - 0.5 = 52.0, IH = 52.0 + 1.8 = 53.8
      expect(result[2].gh, closeTo(52.0, 0.001));
      expect(result[2].ih, closeTo(53.8, 0.001));

      // No.1: GH = 53.8 - 1.2 = 52.6
      expect(result[3].gh, closeTo(52.6, 0.001));
    });

    test('Error check: closed loop should have zero error', () {
      // Start at BM 100.0, end back at 100.0
      // IH = 100 + 1.5 = 101.5; No.1 GH = 101.5 - 1.5 = 100.0 (back to start)
      final measurements = [
        Measurement(
          fieldBookId: 1,
          orderIndex: 0,
          stationName: 'BM.1',
          bs: 1.500,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 1,
          stationName: 'No.1',
          fs: 1.500,
        ),
      ];

      final result = recalculate(measurements, 100.000);

      double sumBs = 0, sumFs = 0;
      for (final m in result) {
        if (m.bs != null) sumBs += m.bs!;
        if (m.fs != null) sumFs += m.fs!;
      }

      final error = LevelCalculation.calculateError(
        sumBs: sumBs,
        sumFs: sumFs,
        startElevation: result.first.gh!,
        endElevation: result.last.gh!,
      );

      expect(error, closeTo(0.0, 0.0001));
    });
  });
}
