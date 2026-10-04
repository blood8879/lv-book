import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  // BM(100) → 중간점 A → TP1 → 중간점 B → 종점
  final measurements = [
    Measurement(
      fieldBookId: 1,
      orderIndex: 0,
      stationName: 'BM.1',
      bs: 1.500,
      ih: 101.500,
      gh: 100.000,
    ),
    Measurement(
      fieldBookId: 1,
      orderIndex: 1,
      stationName: 'A',
      fs: 0.800,
      gh: 100.700,
    ),
    Measurement(
      fieldBookId: 1,
      orderIndex: 2,
      stationName: 'TP1',
      type: MeasurementType.tp,
      bs: 1.200,
      fs: 1.000,
      ih: 101.700,
      gh: 100.500,
    ),
    Measurement(
      fieldBookId: 1,
      orderIndex: 3,
      stationName: 'B',
      fs: 2.000,
      gh: 99.700,
    ),
    Measurement(
      fieldBookId: 1,
      orderIndex: 4,
      stationName: 'END',
      fs: 1.300,
      gh: 100.400,
    ),
  ];

  test('ΣFS excludes intermediate sights and matches GH difference', () {
    final sums = LevelCheckSums.from(measurements, startElevation: 100);

    expect(sums.sumBs, closeTo(2.700, 1e-9));
    // TP1 (1.000) + 종점 (1.300); 중간점 A/B excluded.
    expect(sums.sumFs, closeTo(2.300, 1e-9));
    expect(sums.difference, closeTo(sums.lastGh - sums.firstGh, 1e-9));
    expect(sums.firstGh, 100.000);
    expect(sums.lastGh, 100.400);
    expect(
      sums.error,
      closeTo(LevelClosure.error(measurements, startElevation: 100), 1e-12),
    );
  });

  test('CSV summary prints carry-forward ΣFS', () {
    final csv = CsvExporter.generateFieldBookCsv(
      fieldBook: FieldBook(projectId: 1, title: '검산', date: DateTime(2026)),
      measurements: measurements,
      bmName: 'BM.1',
      startElevation: 100,
      l10n: l10nKo,
    );

    expect(csv, contains('ΣBS,2.700,ΣFS,2.300'));
    expect(csv, contains('ΣBS - ΣFS,0.400'));
  });
}
