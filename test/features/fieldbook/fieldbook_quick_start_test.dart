import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook_quick_start.dart';

void main() {
  test('new field book suggests latest project metadata', () {
    final oldBook = FieldBook(
      projectId: 1,
      title: '이전 야장',
      date: DateTime(2026, 6, 1),
      startBmId: 7,
      startElevation: 100.123,
      surveyor: '김오래',
      checker: '박검측',
      instrument: 'LV-1',
      weather: '맑음',
      workSection: 'A구간',
      jobNumber: 'J-1',
    );
    final latestBook = FieldBook(
      projectId: 1,
      title: '최근 야장',
      date: DateTime(2026, 6, 3),
      startBmId: 8,
      startElevation: 101.456,
      surveyor: '김최근',
      checker: '최검측',
      instrument: 'LV-2',
      weather: '흐림',
      workSection: 'B구간',
      jobNumber: 'J-2',
    );

    final suggestion = FieldBookQuickStart.suggest(
      fieldBooks: [oldBook, latestBook],
      benchmarks: [
        BenchMark(id: 8, projectId: 1, name: 'BM.8', elevation: 101.456),
      ],
    );

    expect(suggestion.surveyor, '김최근');
    expect(suggestion.instrument, 'LV-2');
    expect(suggestion.workSection, 'B구간');
    expect(suggestion.startBm?.name, 'BM.8');
  });

  test('empty project opens blank quick start fields', () {
    final suggestion = FieldBookQuickStart.suggest(
      fieldBooks: const [],
      benchmarks: const [],
    );

    expect(suggestion.surveyor, isNull);
    expect(suggestion.instrument, isNull);
    expect(suggestion.startBm, isNull);
    expect(suggestion.useCustomBm, isTrue);
  });
}
