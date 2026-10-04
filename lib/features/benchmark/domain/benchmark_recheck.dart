import '../../../l10n/l10n.dart';
import 'benchmark.dart';

/// Why a BM should be re-checked before use. UI maps it to text with
/// [BenchMarkRecheck.messageFor].
enum BenchMarkRecheckWarning {
  outOfService,
  possiblyDamaged,
  noVerifiedDate,
  stale,
}

class BenchMarkRecheck {
  static const defaultStaleDays = 30;

  static List<BenchMark> selectableForFieldBook(List<BenchMark> benchmarks) {
    return benchmarks.where((bm) => bm.isSelectableForFieldBook).toList();
  }

  static BenchMarkRecheckWarning? warningCodeFor(
    BenchMark bm, {
    required DateTime now,
    int staleDays = defaultStaleDays,
  }) {
    if (bm.status == BenchMarkStatus.stopped) {
      return BenchMarkRecheckWarning.outOfService;
    }
    if (bm.status == BenchMarkStatus.damagedSuspected) {
      return BenchMarkRecheckWarning.possiblyDamaged;
    }
    final verifiedAt = bm.lastVerifiedAt;
    if (verifiedAt == null) return BenchMarkRecheckWarning.noVerifiedDate;
    if (now.difference(verifiedAt).inDays > staleDays) {
      return BenchMarkRecheckWarning.stale;
    }
    return null;
  }

  static String messageFor(
    AppLocalizations l10n,
    BenchMarkRecheckWarning warning, {
    int staleDays = defaultStaleDays,
  }) => switch (warning) {
    BenchMarkRecheckWarning.outOfService => l10n.benchmarkRecheckOutOfService,
    BenchMarkRecheckWarning.possiblyDamaged =>
      l10n.benchmarkRecheckPossiblyDamaged,
    BenchMarkRecheckWarning.noVerifiedDate =>
      l10n.benchmarkRecheckNoVerifiedDate,
    BenchMarkRecheckWarning.stale => l10n.benchmarkRecheckStale(staleDays),
  };

  /// Warning text in [l10n] (Korean when omitted, for legacy callers).
  /// Widgets should pass `context.l10n`.
  static String? warningFor(
    BenchMark bm, {
    required DateTime now,
    int staleDays = defaultStaleDays,
    AppLocalizations? l10n,
  }) {
    final code = warningCodeFor(bm, now: now, staleDays: staleDays);
    if (code == null) return null;
    return messageFor(l10n ?? l10nKo, code, staleDays: staleDays);
  }
}
