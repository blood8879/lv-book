import 'measurement.dart';
import 'misclosure.dart';

/// Export checklist entries. UI text comes from l10n
/// (`fieldbook_l10n.dart`); [MeasurementValidationItem.label] is the legacy
/// Korean text.
enum MeasurementCheck {
  stationRows,
  firstBs,
  lastFs,
  tpComplete,
  emptyRows,

  /// ΣBS − ΣFS = Final RL − Start RL (always checked).
  arithmetic,

  /// |misclosure| ≤ allowed; only present when a closing RL is known.
  tolerance,
}

/// Problems found by [MeasurementValidation]. UI text comes from l10n
/// (`fieldbook_l10n.dart`); [MeasurementValidationResult.messages] is the
/// legacy Korean text.
enum MeasurementIssue {
  noStationRows,
  firstBsMissing,
  lastFsMissing,
  tpIncomplete,
  emptyRows,
  exceedsTolerance,
  arithmeticMismatch,
}

const _koCheckLabels = {
  MeasurementCheck.stationRows: '측점 행',
  MeasurementCheck.firstBs: '첫 BS',
  MeasurementCheck.lastFs: '마지막 FS',
  MeasurementCheck.tpComplete: 'TP 완성',
  MeasurementCheck.emptyRows: '빈 행',
  MeasurementCheck.arithmetic: '검산',
  MeasurementCheck.tolerance: '허용오차',
};

const _koPassedMessages = {
  MeasurementCheck.stationRows: '측점 행이 있습니다.',
  MeasurementCheck.firstBs: '첫 행에 BS가 있습니다.',
  MeasurementCheck.lastFs: '마지막 관측값이 정리되었습니다.',
  MeasurementCheck.tpComplete: 'TP 행이 완성되었습니다.',
  MeasurementCheck.emptyRows: '측정값 없는 행이 없습니다.',
  MeasurementCheck.arithmetic: '검산이 맞습니다.',
  MeasurementCheck.tolerance: '허용오차 이내입니다.',
};

const _koFailedMessages = {
  MeasurementCheck.stationRows: '측점 행이 필요합니다.',
  MeasurementCheck.firstBs: '첫 행에는 후시(BS)가 필요합니다.',
  MeasurementCheck.lastFs: '마지막 행에는 전시(FS)가 필요합니다.',
  MeasurementCheck.tpComplete: 'TP 행에는 BS와 FS가 모두 필요합니다.',
  MeasurementCheck.emptyRows: '측정값이 없는 행을 정리하세요.',
  MeasurementCheck.arithmetic: '검산이 맞지 않습니다.',
  MeasurementCheck.tolerance: '허용오차를 초과했습니다.',
};

const _koIssueMessages = {
  MeasurementIssue.noStationRows: '측점 행이 필요합니다.',
  MeasurementIssue.firstBsMissing: '첫 행에는 후시(BS)가 필요합니다.',
  MeasurementIssue.lastFsMissing: '마지막 행에는 전시(FS)가 필요합니다.',
  MeasurementIssue.tpIncomplete: 'TP 행에는 후시(BS)와 전시(FS)가 모두 필요합니다.',
  MeasurementIssue.emptyRows: '측정값이 없는 행을 정리하세요.',
  MeasurementIssue.exceedsTolerance: '허용오차를 초과했습니다.',
  MeasurementIssue.arithmeticMismatch: '검산이 맞지 않습니다.',
};

class MeasurementValidationItem {
  final MeasurementCheck check;
  final bool passed;
  final bool blocksExport;

  const MeasurementValidationItem({
    required this.check,
    required this.passed,
    this.blocksExport = false,
  });

  /// Korean label (legacy; UI uses `check.localizedLabel(l10n)`).
  String get label => _koCheckLabels[check]!;

  /// Korean message (legacy).
  String get message =>
      passed ? _koPassedMessages[check]! : _koFailedMessages[check]!;
}

class MeasurementValidationResult {
  final bool canExport;
  final List<MeasurementIssue> issues;

  /// Closure check of the observed rows (null when there are none).
  final LevelClosureCheck? closure;
  final List<MeasurementValidationItem> checklist;

  const MeasurementValidationResult({
    required this.canExport,
    required this.issues,
    this.closure,
    this.checklist = const [],
  });

  /// Final RL − closing RL; null when no closing RL is known.
  double? get misclosure => closure?.misclosure;

  /// Arithmetic check residual ΣBS − ΣFS − (Final RL − Start RL).
  double get arithmeticError => closure?.arithmeticError ?? 0;

  /// Korean judgement (legacy; UI uses `localizedJudgement(l10n)`).
  String get judgementLabel => canExport ? '적합' : '확인 필요';

  /// Korean messages (legacy; UI maps [issues] with l10n).
  List<String> get messages => [
    for (final issue in issues) _koIssueMessages[issue]!,
  ];

  bool get hasBlockingFailures =>
      checklist.any((item) => item.blocksExport && !item.passed);
}

class MeasurementValidation {
  /// Drops trailing rows that have no BS/FS yet (e.g. station names prepared
  /// by '구조 복제' but not measured). They are kept in the field book but must
  /// not count as the last observed station or block export as empty rows.
  /// Unmeasured rows between observed rows are still reported.
  static List<Measurement> trimTrailingUnmeasured(
    List<Measurement> measurements,
  ) {
    var end = measurements.length;
    while (end > 0 &&
        measurements[end - 1].bs == null &&
        measurements[end - 1].fs == null) {
      end--;
    }
    return end == measurements.length
        ? measurements
        : measurements.sublist(0, end);
  }

  /// [closingElevation] is the known RL the run closes on (see
  /// `FieldBook.closingElevationFor`); without it only the arithmetic check
  /// is judged. Exceeding the tolerance or a failed arithmetic check is a
  /// warning ([MeasurementValidationResult.canExport] false, export still
  /// allowed after confirmation); only structural problems block export.
  static MeasurementValidationResult validate({
    required List<Measurement> measurements,
    required double startElevation,
    double? closingElevation,
    MisclosureTolerance tolerance = MisclosureTolerance.defaults,
  }) {
    final issues = <MeasurementIssue>[];
    final rows = trimTrailingUnmeasured(
      measurements.where((row) => row.stationName.trim().isNotEmpty).toList(),
    );

    if (rows.isEmpty) {
      return const MeasurementValidationResult(
        canExport: false,
        issues: [MeasurementIssue.noStationRows],
        checklist: [
          MeasurementValidationItem(
            check: MeasurementCheck.stationRows,
            passed: false,
            blocksExport: true,
          ),
        ],
      );
    }

    final hasFirstBs = rows.first.bs != null;
    final hasLastFs = rows.last.fs != null || rows.length == 1;
    final tpComplete = rows
        .where((row) => row.type == MeasurementType.tp || row.manualTp)
        .every((row) => row.bs != null && row.fs != null);
    final hasNoIncompleteRows = rows.every(
      (row) => row.bs != null || row.fs != null || row.gh != null,
    );

    if (!hasFirstBs) issues.add(MeasurementIssue.firstBsMissing);
    if (!hasLastFs) issues.add(MeasurementIssue.lastFsMissing);
    if (!tpComplete) issues.add(MeasurementIssue.tpIncomplete);
    if (!hasNoIncompleteRows) issues.add(MeasurementIssue.emptyRows);

    final closure = LevelClosureCheck.compute(
      rows,
      startElevation: startElevation,
      closingElevation: closingElevation,
      tolerance: tolerance,
    );
    final withinTolerance = closure.withinTolerance;
    final structuralOk = issues.isEmpty;
    if (structuralOk && !closure.arithmeticOk) {
      issues.add(MeasurementIssue.arithmeticMismatch);
    }
    if (structuralOk && withinTolerance == false) {
      issues.add(MeasurementIssue.exceedsTolerance);
    }
    final isSuitable = structuralOk && closure.isSuitable;

    final checklist = [
      MeasurementValidationItem(
        check: MeasurementCheck.firstBs,
        passed: hasFirstBs,
        blocksExport: true,
      ),
      MeasurementValidationItem(
        check: MeasurementCheck.lastFs,
        passed: hasLastFs,
        blocksExport: true,
      ),
      MeasurementValidationItem(
        check: MeasurementCheck.tpComplete,
        passed: tpComplete,
        blocksExport: true,
      ),
      MeasurementValidationItem(
        check: MeasurementCheck.emptyRows,
        passed: hasNoIncompleteRows,
        blocksExport: true,
      ),
      MeasurementValidationItem(
        check: MeasurementCheck.arithmetic,
        passed: closure.arithmeticOk,
      ),
      if (withinTolerance != null)
        MeasurementValidationItem(
          check: MeasurementCheck.tolerance,
          passed: withinTolerance,
        ),
    ];

    return MeasurementValidationResult(
      canExport: isSuitable,
      issues: issues,
      closure: closure,
      checklist: checklist,
    );
  }
}
