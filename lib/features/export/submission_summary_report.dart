import '../../l10n/l10n.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import '../fieldbook/domain/measurement_validation.dart';
import '../fieldbook/domain/misclosure.dart';
import 'export_labels.dart';

enum SubmissionSummaryError { noSelection }

class SubmissionSummaryException implements Exception {
  final SubmissionSummaryError code;

  const SubmissionSummaryException(this.code);

  String localizedMessage(AppLocalizations l10n) => switch (code) {
    SubmissionSummaryError.noSelection => l10n.exportSummaryNoSelection,
  };

  /// Legacy Korean message; prefer [localizedMessage].
  String get message => localizedMessage(l10nKo);

  @override
  String toString() => message;
}

class FieldBookSummaryInput {
  final FieldBook fieldBook;
  final String bmName;
  final double startElevation;
  final List<Measurement> measurements;

  const FieldBookSummaryInput({
    required this.fieldBook,
    required this.bmName,
    required this.startElevation,
    required this.measurements,
  });
}

class SubmissionSummaryRow {
  final String title;
  final DateTime date;
  final String bmName;
  final String workSection;
  final String surveyor;
  final String reviewStatus;
  final String reviewMemo;
  final DateTime? reviewedAt;

  /// Final RL − closing RL; null when the book has no closing reference.
  final double? misclosure;
  final String judgement;

  const SubmissionSummaryRow({
    required this.title,
    required this.date,
    required this.bmName,
    required this.workSection,
    required this.surveyor,
    required this.reviewStatus,
    required this.reviewMemo,
    required this.reviewedAt,
    required this.misclosure,
    required this.judgement,
  });
}

class SubmissionSummaryReport {
  static List<SubmissionSummaryRow> buildRows(
    List<FieldBookSummaryInput> inputs, {
    MisclosureTolerance tolerance = MisclosureTolerance.defaults,
    required AppLocalizations l10n,
  }) {
    if (inputs.isEmpty) {
      throw const SubmissionSummaryException(
        SubmissionSummaryError.noSelection,
      );
    }

    return [for (final input in inputs) _buildRow(input, tolerance, l10n)];
  }

  static String generateCsv(
    List<FieldBookSummaryInput> inputs, {
    MisclosureTolerance tolerance = MisclosureTolerance.defaults,
    required AppLocalizations l10n,
  }) {
    final rows = buildRows(inputs, tolerance: tolerance, l10n: l10n);
    final buffer = StringBuffer()
      ..writeln(
        [
          l10n.exportFieldTitle,
          l10n.exportFieldDate,
          l10n.exportFieldStartBm,
          l10n.exportFieldSection,
          l10n.exportFieldSurveyor,
          l10n.exportFieldReviewStatus,
          l10n.exportFieldReviewMemo,
          l10n.exportFieldReviewDate,
          l10n.exportCheckMisclosure,
          l10n.exportCheckResult,
        ].map(_csvCell).join(','),
      );
    for (final row in rows) {
      buffer.writeln(
        [
          row.title,
          _formatDate(row.date),
          row.bmName,
          row.workSection,
          row.surveyor,
          row.reviewStatus,
          row.reviewMemo,
          row.reviewedAt == null ? '' : _formatDate(row.reviewedAt!),
          row.misclosure == null
              ? l10n.exportCheckMisclosureUnavailable
              : formatMisclosure(row.misclosure!),
          row.judgement,
        ].map(_csvCell).join(','),
      );
    }
    return buffer.toString();
  }

  static SubmissionSummaryRow _buildRow(
    FieldBookSummaryInput input,
    MisclosureTolerance tolerance,
    AppLocalizations l10n,
  ) {
    final validation = MeasurementValidation.validate(
      measurements: input.measurements,
      startElevation: input.startElevation,
      closingElevation: input.fieldBook.closingElevationFor(
        input.startElevation,
      ),
      tolerance: tolerance,
      method: input.fieldBook.reductionMethod,
    );
    return SubmissionSummaryRow(
      title: input.fieldBook.title,
      date: input.fieldBook.date,
      bmName: input.bmName,
      workSection: input.fieldBook.workSection?.trim() ?? '',
      surveyor: input.fieldBook.surveyor?.trim() ?? '',
      reviewStatus: exportReviewStatusLabel(l10n, input.fieldBook.reviewStatus),
      reviewMemo: input.fieldBook.reviewMemo?.trim() ?? '',
      reviewedAt: input.fieldBook.reviewedAt,
      misclosure: validation.misclosure,
      judgement: validation.canExport
          ? l10n.coreJudgementWithinTolerance
          : l10n.coreJudgementCheckRequired,
    );
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _csvCell(String value) {
    if (!value.contains(',') && !value.contains('"') && !value.contains('\n')) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }
}
