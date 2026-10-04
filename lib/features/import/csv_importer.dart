import 'package:csv/csv.dart';

import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';

class CsvImportResult {
  final FieldBook? fieldBook;
  final List<Measurement> measurements;
  final List<String> errors;

  /// Non-fatal issues (e.g. unparseable date) the user should be told about.
  final List<String> warnings;

  const CsvImportResult({
    required this.fieldBook,
    required this.measurements,
    required this.errors,
    this.warnings = const [],
  });
}

class CsvImporter {
  static const utf8OnlyMessage =
      'UTF-8 CSV만 지원합니다. 글자가 깨진 문자가 있어 가져올 수 없습니다. '
      'Excel에서 "CSV UTF-8(쉼표로 분리)" 형식으로 다시 저장해 주세요.';

  static CsvImportResult parse(
    String csv, {
    required int projectId,
    required DateTime fallbackDate,
  }) {
    if (csv.contains('\uFFFD')) {
      return const CsvImportResult(
        fieldBook: null,
        measurements: [],
        errors: [utf8OnlyMessage],
      );
    }
    final withoutBom = csv.startsWith('\uFEFF') ? csv.substring(1) : csv;
    final normalizedCsv = withoutBom
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(normalizedCsv);
    final errors = <String>[];
    final warnings = <String>[];
    String title = '가져온 야장';
    DateTime date = fallbackDate;
    var dateFound = false;
    double? startElevation;
    final metadata = <String, String>{};
    var tableHeaderIndex = -1;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final label = row.first.toString().replaceAll('\ufeff', '').trim();
      if (label == 'No.' ||
          row.any((cell) => cell.toString().trim() == '측점명')) {
        tableHeaderIndex = i;
        break;
      }
      if (row.length < 2) continue;
      final value = row[1].toString().trim();
      if (label == '야장명' && value.isNotEmpty) title = value;
      if (label == '날짜') {
        dateFound = true;
        final parsed = parseDate(value);
        if (parsed != null) {
          date = parsed;
        } else {
          warnings.add(
            '날짜 "$value"를 인식할 수 없어 ${_formatDate(fallbackDate)}로 '
            '설정했습니다.',
          );
        }
      }
      if (label == 'BM 표고') startElevation = double.tryParse(value);
      if (_metadataLabels.contains(label) && value.isNotEmpty) {
        metadata[label] = value;
      }
    }
    if (!dateFound) {
      warnings.add('날짜 항목이 없어 ${_formatDate(fallbackDate)}로 설정했습니다.');
    }

    if (tableHeaderIndex < 0) {
      return const CsvImportResult(
        fieldBook: null,
        measurements: [],
        errors: ['측량 표 헤더를 찾을 수 없습니다.'],
      );
    }

    final measurements = <Measurement>[];
    for (var i = tableHeaderIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        break;
      }
      if (row.first.toString().startsWith('Σ')) break;
      final stationName = _cell(row, 1);
      if (stationName.isEmpty) continue;

      final parsed = _parseMeasurementRow(
        row,
        rowNumber: i + 1,
        orderIndex: measurements.length,
        fieldBookId: 0,
      );
      if (parsed.error != null) {
        errors.add(parsed.error!);
      } else {
        measurements.add(parsed.measurement!);
      }
    }
    _classifyTurningPoints(measurements);

    if (errors.isNotEmpty) {
      return CsvImportResult(
        fieldBook: null,
        measurements: const [],
        errors: errors,
      );
    }

    return CsvImportResult(
      fieldBook: FieldBook(
        projectId: projectId,
        title: title,
        date: date,
        startElevation: startElevation,
        surveyor: metadata['측량자'],
        checker: metadata['검측자'],
        instrument: metadata['장비'],
        weather: metadata['날씨'],
        workSection: metadata['작업구간'],
        jobNumber: metadata['공사번호'],
      ),
      measurements: measurements,
      errors: const [],
      warnings: warnings,
    );
  }

  static const _metadataLabels = {'측량자', '검측자', '장비', '날씨', '작업구간', '공사번호'};

  /// Parses yyyy-MM-dd, yyyy/M/d, yyyy.M.d (optionally trailing '.') and ISO
  /// timestamps. Returns null for invalid dates such as 2026-02-31.
  static DateTime? parseDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    final match = RegExp(
      r'^(\d{4})\s*[-/.]\s*(\d{1,2})\s*[-/.]\s*(\d{1,2})\.?$',
    ).firstMatch(text);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return date;
    }
    return DateTime.tryParse(text);
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Mirrors the edit screen's auto TP detection: after the first BS, a row
  /// with both BS and FS is a turning point automatically. A row marked 'TP'
  /// in the CSV that would not be auto-detected is kept as a manual TP.
  static void _classifyTurningPoints(List<Measurement> measurements) {
    var firstBsFound = false;
    for (var i = 0; i < measurements.length; i++) {
      final m = measurements[i];
      final autoTp = firstBsFound && m.bs != null && m.fs != null;
      final markedTp = m.type == MeasurementType.tp;
      measurements[i] = m.copyWith(
        type: autoTp || markedTp ? MeasurementType.tp : MeasurementType.normal,
        manualTp: markedTp && !autoTp,
      );
      if (m.bs != null) firstBsFound = true;
    }
  }

  static _ParsedMeasurement _parseMeasurementRow(
    List<dynamic> row, {
    required int rowNumber,
    required int orderIndex,
    required int fieldBookId,
  }) {
    final bs = _parseDouble(_cell(row, 2), rowNumber, '후시(BS)');
    if (bs.error != null) return _ParsedMeasurement.error(bs.error!);
    final fs = _parseDouble(_cell(row, 3), rowNumber, '전시(FS)');
    if (fs.error != null) return _ParsedMeasurement.error(fs.error!);
    final ih = _parseDouble(_cell(row, 4), rowNumber, '기계고(IH)');
    if (ih.error != null) return _ParsedMeasurement.error(ih.error!);
    final gh = _parseDouble(_cell(row, 5), rowNumber, '지반고(GH)');
    if (gh.error != null) return _ParsedMeasurement.error(gh.error!);
    final note = _cell(row, 6);

    return _ParsedMeasurement.value(
      Measurement(
        fieldBookId: fieldBookId,
        orderIndex: orderIndex,
        stationName: _cell(row, 1),
        type: note == 'TP' ? MeasurementType.tp : MeasurementType.normal,
        bs: bs.value,
        fs: fs.value,
        ih: ih.value,
        gh: gh.value,
      ),
    );
  }

  static String _cell(List<dynamic> row, int index) {
    if (index >= row.length) return '';
    return row[index].toString().trim();
  }

  static _ParsedDouble _parseDouble(String value, int rowNumber, String label) {
    if (value.isEmpty) return const _ParsedDouble.value(null);
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return _ParsedDouble.error('$rowNumber행 $label 숫자 형식이 올바르지 않습니다.');
    }
    return _ParsedDouble.value(parsed);
  }
}

class _ParsedMeasurement {
  final Measurement? measurement;
  final String? error;

  const _ParsedMeasurement.value(this.measurement) : error = null;
  const _ParsedMeasurement.error(this.error) : measurement = null;
}

class _ParsedDouble {
  final double? value;
  final String? error;

  const _ParsedDouble.value(this.value) : error = null;
  const _ParsedDouble.error(this.error) : value = null;
}
