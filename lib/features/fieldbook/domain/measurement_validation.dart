import 'measurement.dart';
import '../../export/export_judgement.dart';

class MeasurementValidationItem {
  final String label;
  final bool passed;
  final String message;
  final bool blocksExport;

  const MeasurementValidationItem({
    required this.label,
    required this.passed,
    required this.message,
    this.blocksExport = false,
  });
}

class MeasurementValidationResult {
  final bool canExport;
  final String judgementLabel;
  final List<String> messages;
  final double closureError;
  final List<MeasurementValidationItem> checklist;

  const MeasurementValidationResult({
    required this.canExport,
    required this.judgementLabel,
    required this.messages,
    required this.closureError,
    this.checklist = const [],
  });

  bool get hasBlockingFailures =>
      checklist.any((item) => item.blocksExport && !item.passed);
}

class MeasurementValidation {
  static MeasurementValidationResult validate({
    required List<Measurement> measurements,
    required double startElevation,
    double tolerance = 0.001,
  }) {
    final messages = <String>[];
    final rows = measurements
        .where((row) => row.stationName.trim().isNotEmpty)
        .toList();

    if (rows.isEmpty) {
      const item = MeasurementValidationItem(
        label: '측점 행',
        passed: false,
        message: '측점 행이 필요합니다.',
        blocksExport: true,
      );
      return const MeasurementValidationResult(
        canExport: false,
        judgementLabel: '확인 필요',
        messages: ['측점 행이 필요합니다.'],
        closureError: 0,
        checklist: [item],
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

    if (!hasFirstBs) messages.add('첫 행에는 후시(BS)가 필요합니다.');
    if (!hasLastFs) messages.add('마지막 행에는 전시(FS)가 필요합니다.');
    if (!tpComplete) messages.add('TP 행에는 후시(BS)와 전시(FS)가 모두 필요합니다.');
    if (!hasNoIncompleteRows) messages.add('측정값이 없는 행을 정리하세요.');

    final sumBs = rows.fold<double>(0, (sum, row) => sum + (row.bs ?? 0));
    final sumFs = rows.fold<double>(0, (sum, row) => sum + (row.fs ?? 0));
    final firstGh = rows.first.gh ?? startElevation;
    final lastGh = rows.last.gh ?? (startElevation + sumBs - sumFs);
    final closureError = sumBs - sumFs - (lastGh - firstGh);
    final isSuitable =
        messages.isEmpty &&
        ExportJudgement.isSuitable(closureError, tolerance: tolerance);

    if (!isSuitable && messages.isEmpty) {
      messages.add('허용오차를 초과했습니다.');
    }

    final checklist = [
      MeasurementValidationItem(
        label: '첫 BS',
        passed: hasFirstBs,
        message: hasFirstBs ? '첫 행에 BS가 있습니다.' : '첫 행에는 후시(BS)가 필요합니다.',
        blocksExport: true,
      ),
      MeasurementValidationItem(
        label: '마지막 FS',
        passed: hasLastFs,
        message: hasLastFs ? '마지막 관측값이 정리되었습니다.' : '마지막 행에는 전시(FS)가 필요합니다.',
        blocksExport: true,
      ),
      MeasurementValidationItem(
        label: 'TP 완성',
        passed: tpComplete,
        message: tpComplete ? 'TP 행이 완성되었습니다.' : 'TP 행에는 BS와 FS가 모두 필요합니다.',
        blocksExport: true,
      ),
      MeasurementValidationItem(
        label: '빈 행',
        passed: hasNoIncompleteRows,
        message: hasNoIncompleteRows ? '측정값 없는 행이 없습니다.' : '측정값이 없는 행을 정리하세요.',
        blocksExport: true,
      ),
      MeasurementValidationItem(
        label: '허용오차',
        passed: ExportJudgement.isSuitable(closureError, tolerance: tolerance),
        message: ExportJudgement.isSuitable(closureError, tolerance: tolerance)
            ? '허용오차 이내입니다.'
            : '허용오차를 초과했습니다.',
      ),
    ];

    return MeasurementValidationResult(
      canExport: isSuitable,
      judgementLabel: isSuitable ? '적합' : '확인 필요',
      messages: messages,
      closureError: closureError,
      checklist: checklist,
    );
  }
}
