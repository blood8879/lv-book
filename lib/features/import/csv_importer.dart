import 'package:csv/csv.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../../l10n/l10n.dart';
import '../export/export_labels.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import '../fieldbook/domain/misclosure.dart';
import '../fieldbook/domain/reduction.dart';

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

/// Metadata rows the importer understands.
enum _CsvField {
  title,
  date,
  bmElevation,
  surveyor,
  checker,
  instrument,
  weather,
  section,
  jobNumber,
  startBm,
  closingBm,
  closingRl,
  reductionMethod,
  unit,
}

/// Imports CSV files exported by Lv Book in either language.
///
/// Labels are matched against both the Korean labels (every file exported
/// before English support, and Korean-language exports) and the English
/// labels, case-insensitively. Errors and warnings are returned in the
/// language of [l10n].
class CsvImporter {
  /// Accepted metadata labels (lowercased) per field. Keep in sync with
  /// `CsvExporter` / the `exportField*` keys; never remove a legacy label.
  static const Map<String, _CsvField> _metadataAliases = {
    '야장명': _CsvField.title,
    'level book': _CsvField.title,
    'level book name': _CsvField.title,
    'title': _CsvField.title,
    '날짜': _CsvField.date,
    'date': _CsvField.date,
    'bm 표고': _CsvField.bmElevation,
    'bm elevation': _CsvField.bmElevation,
    'bm rl': _CsvField.bmElevation,
    '측량자': _CsvField.surveyor,
    'surveyor': _CsvField.surveyor,
    '검측자': _CsvField.checker,
    'checker': _CsvField.checker,
    '장비': _CsvField.instrument,
    'instrument': _CsvField.instrument,
    '날씨': _CsvField.weather,
    'weather': _CsvField.weather,
    '작업구간': _CsvField.section,
    'section': _CsvField.section,
    'work section': _CsvField.section,
    '공사번호': _CsvField.jobNumber,
    'job no.': _CsvField.jobNumber,
    'job no': _CsvField.jobNumber,
    'job number': _CsvField.jobNumber,
    '시작 bm': _CsvField.startBm,
    'start bm': _CsvField.startBm,
    '폐합 bm': _CsvField.closingBm,
    'closing bm': _CsvField.closingBm,
    '폐합 표고': _CsvField.closingRl,
    'closing rl': _CsvField.closingRl,
    'closing elevation': _CsvField.closingRl,
    '기입 방식': _CsvField.reductionMethod,
    'reduction method': _CsvField.reductionMethod,
    'reduction': _CsvField.reductionMethod,
    'booking method': _CsvField.reductionMethod,
    '단위': _CsvField.unit,
    'unit': _CsvField.unit,
    'units': _CsvField.unit,
  };

  /// Reduction method values (lowercased) meaning rise and fall; anything
  /// else (including '기고식' / 'Height of instrument') is HI.
  static const _riseFallValues = {
    'rise and fall',
    'rise & fall',
    'rise/fall',
    'r&f',
    'riseandfall',
    '승강식',
    '승강',
  };

  static const _unitValues = {
    'm': LengthUnit.metres,
    'metre': LengthUnit.metres,
    'metres': LengthUnit.metres,
    'meter': LengthUnit.metres,
    'meters': LengthUnit.metres,
    '미터': LengthUnit.metres,
    'ft': LengthUnit.feet,
    'foot': LengthUnit.feet,
    'feet': LengthUnit.feet,
    '피트': LengthUnit.feet,
  };

  /// Table header labels (lowercased) per column: every label either
  /// language exports, plus common spellings. Files without recognisable
  /// BS/FS headers use the legacy fixed layout ([_legacyColumns]).
  static final Map<String, ExportColumn> _columnAliases = () {
    final map = <String, ExportColumn>{
      'backsight': ExportColumn.bs,
      'backsight (bs)': ExportColumn.bs,
      'foresight': ExportColumn.fs,
      'foresight (fs)': ExportColumn.fs,
      'intermediate sight': ExportColumn.intermediate,
      'intermediate': ExportColumn.intermediate,
      'is': ExportColumn.intermediate,
      'ih': ExportColumn.hi,
      'gh': ExportColumn.rl,
      'reduced level': ExportColumn.rl,
      'no': ExportColumn.no,
    };
    for (final strings in [l10nKo, l10nFor(const Locale('en'))]) {
      for (final column in ExportColumn.values) {
        map[_normalize(exportColumnHeader(strings, column))] = column;
      }
    }
    return map;
  }();

  /// Column positions of files exported before the header was mapped:
  /// No. / Station / BS / FS / HI / RL / Remarks.
  static const _legacyColumns = {
    ExportColumn.no: 0,
    ExportColumn.station: 1,
    ExportColumn.bs: 2,
    ExportColumn.fs: 3,
    ExportColumn.hi: 4,
    ExportColumn.rl: 5,
    ExportColumn.remarks: 6,
  };

  static Map<ExportColumn, int> _columnsOf(List<dynamic> header) {
    final columns = <ExportColumn, int>{};
    for (var i = 0; i < header.length; i++) {
      final column = _columnAliases[_normalize(header[i])];
      if (column != null) columns.putIfAbsent(column, () => i);
    }
    final mapped =
        columns.containsKey(ExportColumn.bs) &&
        columns.containsKey(ExportColumn.fs) &&
        columns.containsKey(ExportColumn.station);
    return mapped ? columns : _legacyColumns;
  }

  /// Table header cells that mark the start of the measurement table.
  static const _rowNumberHeaders = {'no.', 'no'};
  static const _stationHeaders = {'측점명', 'station'};

  /// Remarks values that mark a turning point (Korean and English files).
  static const _turningPointMarkers = {'tp', 't.p.', 'turning point', '전환점'};

  static String _normalize(Object? cell) =>
      cell.toString().replaceAll('\ufeff', '').trim().toLowerCase();

  /// [appUnit] (the app's length unit) adds a warning when the file states
  /// another unit; numbers are never converted.
  static CsvImportResult parse(
    String csv, {
    required int projectId,
    required DateTime fallbackDate,
    required AppLocalizations l10n,
    LengthUnit? appUnit,
  }) {
    if (csv.contains('\uFFFD')) {
      return CsvImportResult(
        fieldBook: null,
        measurements: const [],
        errors: [l10n.exportImportUtf8Only],
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
    String title = l10n.exportImportDefaultTitle;
    DateTime date = fallbackDate;
    var dateFound = false;
    double? startElevation;
    double? closingElevation;
    ReductionMethod? reductionMethod;
    LengthUnit? fileUnit;
    final metadata = <_CsvField, String>{};
    var tableHeaderIndex = -1;

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;
      final label = _normalize(row.first);
      if (_rowNumberHeaders.contains(label) ||
          row.any((cell) => _stationHeaders.contains(_normalize(cell)))) {
        tableHeaderIndex = i;
        break;
      }
      if (row.length < 2) continue;
      final value = row[1].toString().trim();
      final field = _metadataAliases[label];
      if (field == null) continue;
      switch (field) {
        case _CsvField.title:
          if (value.isNotEmpty) title = value;
        case _CsvField.date:
          dateFound = true;
          final parsed = parseDate(value);
          if (parsed != null) {
            date = parsed;
          } else {
            warnings.add(
              l10n.exportImportDateUnrecognized(
                value,
                _formatDate(fallbackDate),
              ),
            );
          }
        case _CsvField.bmElevation:
          startElevation = double.tryParse(value);
        case _CsvField.closingRl:
          closingElevation = double.tryParse(value);
        case _CsvField.reductionMethod:
          reductionMethod = _riseFallValues.contains(value.toLowerCase())
              ? ReductionMethod.riseAndFall
              : ReductionMethod.heightOfInstrument;
        case _CsvField.unit:
          fileUnit = _unitValues[value.toLowerCase()];
        case _CsvField.startBm || _CsvField.closingBm:
          if (value.isNotEmpty) metadata[field] = value;
        case _CsvField.surveyor ||
            _CsvField.checker ||
            _CsvField.instrument ||
            _CsvField.weather ||
            _CsvField.section ||
            _CsvField.jobNumber:
          if (value.isNotEmpty) metadata[field] = value;
      }
    }
    if (!dateFound) {
      warnings.add(l10n.exportImportDateMissing(_formatDate(fallbackDate)));
    }

    if (tableHeaderIndex < 0) {
      return CsvImportResult(
        fieldBook: null,
        measurements: const [],
        errors: [l10n.exportImportHeaderNotFound],
      );
    }

    final columns = _columnsOf(rows[tableHeaderIndex]);
    if (appUnit != null && fileUnit != null && fileUnit != appUnit) {
      warnings.add(
        l10n.exportImportUnitMismatch(fileUnit.symbol, appUnit.symbol),
      );
    }
    final measurements = <Measurement>[];
    for (var i = tableHeaderIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
        break;
      }
      if (row.first.toString().startsWith('Σ')) break;
      final stationName = _cell(row, columns[ExportColumn.station]);
      if (stationName.isEmpty) continue;

      final parsed = _parseMeasurementRow(
        row,
        columns: columns,
        rowNumber: i + 1,
        orderIndex: measurements.length,
        fieldBookId: 0,
        l10n: l10n,
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

    // BM ids cannot be resolved from a CSV, so a closing BM is kept as its
    // RL (manual closing). Closing on the start BM at the start RL is a loop.
    final closingMode = closingElevation == null
        ? ClosingReferenceMode.none
        : metadata[_CsvField.closingBm] != null &&
              metadata[_CsvField.closingBm] == metadata[_CsvField.startBm] &&
              startElevation != null &&
              (closingElevation - startElevation).abs() <= toleranceEpsilon
        ? ClosingReferenceMode.loop
        : ClosingReferenceMode.manual;

    return CsvImportResult(
      fieldBook: FieldBook(
        projectId: projectId,
        title: title,
        date: date,
        startElevation: startElevation,
        closingMode: closingMode,
        closingElevation: closingMode == ClosingReferenceMode.manual
            ? closingElevation
            : null,
        // Files without the method row: rise/fall columns imply rise and
        // fall, otherwise HI (every file exported before it existed).
        reductionMethod:
            reductionMethod ??
            (columns.containsKey(ExportColumn.rise)
                ? ReductionMethod.riseAndFall
                : ReductionMethod.heightOfInstrument),
        surveyor: metadata[_CsvField.surveyor],
        checker: metadata[_CsvField.checker],
        instrument: metadata[_CsvField.instrument],
        weather: metadata[_CsvField.weather],
        workSection: metadata[_CsvField.section],
        jobNumber: metadata[_CsvField.jobNumber],
      ),
      measurements: measurements,
      errors: const [],
      warnings: warnings,
    );
  }

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
    required Map<ExportColumn, int> columns,
    required int rowNumber,
    required int orderIndex,
    required int fieldBookId,
    required AppLocalizations l10n,
  }) {
    _ParsedDouble number(ExportColumn column, String label) =>
        _parseDouble(_cell(row, columns[column]), rowNumber, label, l10n);

    final bs = number(ExportColumn.bs, l10n.exportColumnBs);
    if (bs.error != null) return _ParsedMeasurement.error(bs.error!);
    final fs = number(ExportColumn.fs, l10n.exportColumnFs);
    if (fs.error != null) return _ParsedMeasurement.error(fs.error!);
    // English exports print intermediate sights under IS; they are FS
    // readings on FS-only rows.
    final intermediate = number(ExportColumn.intermediate, l10n.exportColumnIs);
    if (intermediate.error != null) {
      return _ParsedMeasurement.error(intermediate.error!);
    }
    final ih = number(ExportColumn.hi, l10n.exportColumnHi);
    if (ih.error != null) return _ParsedMeasurement.error(ih.error!);
    final gh = number(ExportColumn.rl, l10n.exportColumnRl);
    if (gh.error != null) return _ParsedMeasurement.error(gh.error!);
    final note = _cell(row, columns[ExportColumn.remarks]);

    return _ParsedMeasurement.value(
      Measurement(
        fieldBookId: fieldBookId,
        orderIndex: orderIndex,
        stationName: _cell(row, columns[ExportColumn.station]),
        type: _turningPointMarkers.contains(note.toLowerCase())
            ? MeasurementType.tp
            : MeasurementType.normal,
        bs: bs.value,
        fs: fs.value ?? intermediate.value,
        ih: ih.value,
        gh: gh.value,
      ),
    );
  }

  static String _cell(List<dynamic> row, int? index) {
    if (index == null || index >= row.length) return '';
    return row[index].toString().trim();
  }

  static _ParsedDouble _parseDouble(
    String value,
    int rowNumber,
    String label,
    AppLocalizations l10n,
  ) {
    if (value.isEmpty) return const _ParsedDouble.value(null);
    final parsed = double.tryParse(value);
    if (parsed == null) {
      return _ParsedDouble.error(
        l10n.exportImportInvalidNumber(rowNumber, label),
      );
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
