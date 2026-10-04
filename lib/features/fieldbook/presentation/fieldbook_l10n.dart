import '../../../l10n/l10n.dart';
import '../domain/fieldbook.dart';
import '../domain/measurement_validation.dart';

/// Maps field book domain codes to text in the app language. Also used by
/// exports (pass the same [AppLocalizations] the document is rendered in).

extension FieldBookReviewStatusL10n on FieldBookReviewStatus {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    FieldBookReviewStatus.draft => l10n.fieldbookStatusDraft,
    FieldBookReviewStatus.reviewed => l10n.fieldbookStatusReviewed,
    FieldBookReviewStatus.needsCheck => l10n.fieldbookStatusNeedsCheck,
  };
}

extension MeasurementCheckL10n on MeasurementCheck {
  String localizedLabel(AppLocalizations l10n) => switch (this) {
    MeasurementCheck.stationRows => l10n.fieldbookCheckStationRows,
    MeasurementCheck.firstBs => l10n.fieldbookCheckFirstBs,
    MeasurementCheck.lastFs => l10n.fieldbookCheckLastFs,
    MeasurementCheck.tpComplete => l10n.fieldbookCheckTpComplete,
    MeasurementCheck.emptyRows => l10n.fieldbookCheckEmptyRows,
    MeasurementCheck.tolerance => l10n.fieldbookCheckTolerance,
  };
}

extension MeasurementIssueL10n on MeasurementIssue {
  String localizedMessage(AppLocalizations l10n) => switch (this) {
    MeasurementIssue.noStationRows => l10n.fieldbookIssueNoStationRows,
    MeasurementIssue.firstBsMissing => l10n.fieldbookIssueFirstBsMissing,
    MeasurementIssue.lastFsMissing => l10n.fieldbookIssueLastFsMissing,
    MeasurementIssue.tpIncomplete => l10n.fieldbookIssueTpIncomplete,
    MeasurementIssue.emptyRows => l10n.fieldbookIssueEmptyRows,
    MeasurementIssue.exceedsTolerance => l10n.fieldbookIssueExceedsTolerance,
  };
}

extension MeasurementValidationResultL10n on MeasurementValidationResult {
  /// "Within tolerance" / "Check required" (적합 / 확인 필요).
  String localizedJudgement(AppLocalizations l10n) => canExport
      ? l10n.coreJudgementWithinTolerance
      : l10n.coreJudgementCheckRequired;

  List<String> localizedMessages(AppLocalizations l10n) => [
    for (final issue in issues) issue.localizedMessage(l10n),
  ];
}
