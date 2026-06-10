import 'package:csv/csv.dart';

import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';

class CsvImportResult {
  final FieldBook? fieldBook;
  final List<Measurement> measurements;
  final List<String> errors;

  const CsvImportResult({
    required this.fieldBook,
    required this.measurements,
    required this.errors,
  });
}

class CsvImporter {
  static CsvImportResult parse(
    String csv, {
    required int projectId,
    required DateTime fallbackDate,
  }) {
    final normalizedCsv = csv.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(normalizedCsv);
    final errors = <String>[];
    String title = '가져온 야장';
    DateTime date = fallbackDate;
    double? startElevation;
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
      final value = row[1].toString();
      if (label == '야장명') title = value;
      if (label == '날짜') date = DateTime.tryParse(value) ?? fallbackDate;
      if (label == 'BM 표고') startElevation = double.tryParse(value);
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
      ),
      measurements: measurements,
      errors: const [],
    );
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
        manualTp: note == 'TP',
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
