import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/benchmark/domain/benchmark_recheck.dart';
import 'package:lv_book/l10n/l10n.dart';

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

  test('recheck warnings keep Korean text and translate to English', () {
    final en = l10nFor(const Locale('en'));
    final now = DateTime(2026, 6, 8);
    final stale = BenchMark(
      id: 1,
      projectId: 1,
      name: 'BM.1',
      elevation: 100,
      lastVerifiedAt: DateTime(2026, 4, 1),
    );
    final damaged = stale.copyWith(status: BenchMarkStatus.damagedSuspected);
    final stopped = stale.copyWith(status: BenchMarkStatus.stopped);

    expect(
      BenchMarkRecheck.warningFor(stale, now: now),
      '마지막 확인 후 30일이 지났습니다. 재확인 필요',
    );
    expect(
      BenchMarkRecheck.warningFor(damaged, now: now),
      '훼손 의심 BM입니다. 사용 전 현장에서 재확인하세요.',
    );
    expect(
      BenchMarkRecheck.warningFor(stopped, now: now),
      '사용 중지 BM입니다. 새 야장의 시작 BM으로 사용할 수 없습니다.',
    );
    expect(
      BenchMarkRecheck.warningFor(stale, now: now, l10n: en),
      '30 days since the last check. Re-check required',
    );
    expect(
      BenchMarkRecheck.warningCodeFor(damaged, now: now),
      BenchMarkRecheckWarning.possiblyDamaged,
    );
    expect(BenchMarkStatus.stopped.localizedLabel(en), 'Out of service');
  });
}
