import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/benchmark/domain/benchmark_recheck.dart';

void main() {
  test('stale BM displays recheck warning during field book creation', () {
    final bm = BenchMark(
      id: 1,
      projectId: 1,
      name: 'BM.1',
      elevation: 100,
      lastVerifiedAt: DateTime(2026, 4, 1),
    );

    final warning = BenchMarkRecheck.warningFor(bm, now: DateTime(2026, 6, 8));

    expect(warning, contains('재확인 필요'));
  });

  test('stopped BM is excluded from start BM selector', () {
    final stopped = BenchMark(
      id: 1,
      projectId: 1,
      name: 'BM.STOP',
      elevation: 100,
      status: BenchMarkStatus.stopped,
    );

    final selectable = BenchMarkRecheck.selectableForFieldBook([stopped]);

    expect(selectable, isEmpty);
  });
}
