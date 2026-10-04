import '../../l10n/l10n.dart';

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
}
