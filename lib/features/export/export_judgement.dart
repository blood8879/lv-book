import '../../l10n/l10n.dart';
import '../fieldbook/domain/misclosure.dart';

class ExportJudgement {
  static const defaultTolerance = 0.001;

  static bool isSuitable(
    double closureError, {
    double tolerance = defaultTolerance,
  }) {
    return closureError.abs() <= tolerance + 1e-9;
  }

  /// Judgement text ("Within tolerance" / "Check required"). Defaults to
  /// Korean for legacy callers; exports pass the app-language [l10n].
  static String label(
    double closureError, {
    double tolerance = defaultTolerance,
    AppLocalizations? l10n,
  }) {
    final strings = l10n ?? l10nKo;
    return isSuitable(closureError, tolerance: tolerance)
        ? strings.coreJudgementWithinTolerance
        : strings.coreJudgementCheckRequired;
  }

  /// Judgement text of a closure check: like [labelFor], but a K·√L rule
  /// without a route length says the tolerance is unavailable instead of
  /// judging against a guessed allowance.
  static String labelForClosure(
    LevelClosureCheck closure, {
    required AppLocalizations l10n,
  }) => closure.toleranceUnavailable
      ? l10n.exportJudgementToleranceUnavailable
      : labelFor(closure.isSuitable, l10n: l10n);

  /// Judgement text for an already-computed result (e.g.
  /// `LevelClosureCheck.isSuitable`).
  static String labelFor(bool suitable, {AppLocalizations? l10n}) {
    final strings = l10n ?? l10nKo;
    return suitable
        ? strings.coreJudgementWithinTolerance
        : strings.coreJudgementCheckRequired;
  }
}
