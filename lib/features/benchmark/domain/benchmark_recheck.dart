import 'benchmark.dart';

class BenchMarkRecheck {
  static const defaultStaleDays = 30;

  static List<BenchMark> selectableForFieldBook(List<BenchMark> benchmarks) {
    return benchmarks.where((bm) => bm.isSelectableForFieldBook).toList();
  }

  static String? warningFor(
    BenchMark bm, {
    required DateTime now,
    int staleDays = defaultStaleDays,
  }) {
    if (bm.status == BenchMarkStatus.stopped) {
      return '사용 중지 BM입니다. 새 야장의 시작 BM으로 사용할 수 없습니다.';
    }
    if (bm.status == BenchMarkStatus.damagedSuspected) {
      return '훼손 의심 BM입니다. 사용 전 현장에서 재확인하세요.';
    }
    final verifiedAt = bm.lastVerifiedAt;
    if (verifiedAt == null) return '최종 확인일이 없습니다. 재확인 필요';
    if (now.difference(verifiedAt).inDays > staleDays) {
      return '마지막 확인 후 $staleDays일이 지났습니다. 재확인 필요';
    }
    return null;
  }
}
