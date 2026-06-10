import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import '../fieldbook/domain/measurement_validation.dart';

class SubmissionSummaryException implements Exception {
  final String message;

  const SubmissionSummaryException(this.message);

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
  final double closureError;
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
    required this.closureError,
    required this.judgement,
  });
}

class SubmissionSummaryReport {
  static List<SubmissionSummaryRow> buildRows(
    List<FieldBookSummaryInput> inputs,
  ) {
    if (inputs.isEmpty) {
      throw const SubmissionSummaryException('요약할 야장을 선택하세요.');
    }

    return [for (final input in inputs) _buildRow(input)];
  }

  static String generateCsv(List<FieldBookSummaryInput> inputs) {
    final rows = buildRows(inputs);
    final buffer = StringBuffer()
      ..writeln('야장명,날짜,시작 BM,작업구간,측량자,검토 상태,검토 메모,검토일,오차,검산 판정');
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
          row.closureError.toStringAsFixed(4),
          row.judgement,
        ].map(_csvCell).join(','),
      );
    }
    return buffer.toString();
  }

  static SubmissionSummaryRow _buildRow(FieldBookSummaryInput input) {
    final validation = MeasurementValidation.validate(
      measurements: input.measurements,
      startElevation: input.startElevation,
    );
    return SubmissionSummaryRow(
      title: input.fieldBook.title,
      date: input.fieldBook.date,
      bmName: input.bmName,
      workSection: input.fieldBook.workSection?.trim() ?? '',
      surveyor: input.fieldBook.surveyor?.trim() ?? '',
      reviewStatus: input.fieldBook.reviewStatus.label,
      reviewMemo: input.fieldBook.reviewMemo?.trim() ?? '',
      reviewedAt: input.fieldBook.reviewedAt,
      closureError: validation.closureError,
      judgement: validation.judgementLabel,
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
