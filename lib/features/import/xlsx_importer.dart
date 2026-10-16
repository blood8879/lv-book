import 'package:excel_community/excel_community.dart' as xl;

import '../../l10n/l10n.dart';
import '../fieldbook/domain/misclosure.dart';
import 'csv_importer.dart';

/// Imports Excel workbooks (.xlsx): files exported by Lv Book
/// (`XlsxExporter`, any app language) and hand-made sheets with a
/// recognisable header row (Station / 측점 / No., BS / 후시, IS / 중간시,
/// FS / 전시, Remarks / 비고, ...).
///
/// The worksheet is turned into rows of text cells and parsed by
/// [CsvImporter.parseRows], so labels, metadata, TP flags and errors behave
/// like the CSV import. Calculated columns are ignored and recomputed.
class XlsxImporter {
  /// The table header must start within this many rows of a sheet. Our own
  /// exports put up to ~23 header-block rows above it.
  static const headerSearchRows = 40;

  /// Rows/columns read per sheet; a level book never comes close, and it
  /// keeps a stray cell at XFD1048576 from allocating millions of cells.
  static const _maxRows = 20000;
  static const _maxColumns = 64;

  /// An .xlsx is a zip archive ('PK').
  static bool isXlsx(List<int> bytes) =>
      bytes.length >= 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;

  /// OLE compound file: an old binary .xls or a password-protected
  /// (encrypted) workbook, neither of which can be read.
  static bool isLegacyOrEncrypted(List<int> bytes) =>
      bytes.length >= 8 &&
      bytes[0] == 0xD0 &&
      bytes[1] == 0xCF &&
      bytes[2] == 0x11 &&
      bytes[3] == 0xE0 &&
      bytes[4] == 0xA1 &&
      bytes[5] == 0xB1 &&
      bytes[6] == 0x1A &&
      bytes[7] == 0xE1;

  /// Never throws: unreadable files come back as a localized error.
  static CsvImportResult parse(
    List<int> bytes, {
    required int projectId,
    required DateTime fallbackDate,
    required AppLocalizations l10n,
    LengthUnit? appUnit,
  }) {
    if (isLegacyOrEncrypted(bytes)) return _error(l10n.exportImportXlsxLegacy);
    if (!isXlsx(bytes)) return _error(l10n.exportImportXlsxUnreadable);

    final List<List<String>>? rows;
    try {
      rows = _tableSheetRows(xl.Excel.decodeBytes(bytes));
    } catch (_) {
      // The package throws ArgumentError/UnsupportedError/RangeError/... for
      // damaged archives and XML.
      return _error(l10n.exportImportXlsxUnreadable);
    }
    if (rows == null) return _error(l10n.exportImportHeaderNotFound);
    return CsvImporter.parseRows(
      rows,
      projectId: projectId,
      fallbackDate: fallbackDate,
      l10n: l10n,
      appUnit: appUnit,
      spreadsheet: true,
    );
  }

  /// Rows of the first sheet with a table header in its first
  /// [headerSearchRows] rows, or null when no sheet has one.
  static List<List<String>>? _tableSheetRows(xl.Excel excel) {
    for (final sheet in excel.tables.values) {
      final rowCount = sheet.maxRows.clamp(0, _maxRows);
      final head = [
        for (var r = 0; r < rowCount && r < headerSearchRows; r++)
          _rowText(sheet, r),
      ];
      if (head.any((row) => CsvImporter.spreadsheetColumnsOf(row) != null)) {
        return [
          ...head,
          for (var r = head.length; r < rowCount; r++) _rowText(sheet, r),
        ];
      }
    }
    return null;
  }

  static List<String> _rowText(xl.Sheet sheet, int rowIndex) => [
    for (final cell in sheet.row(rowIndex).take(_maxColumns))
      cellText(cell?.value),
  ];

  /// Cell text as the CSV importer reads it: numbers without float noise
  /// ('1.0' → '1'), dates as yyyy-MM-dd, formulas as their cached result
  /// (empty when the file has none).
  static String cellText(xl.CellValue? value) => switch (value) {
    null => '',
    xl.TextCellValue() => value.toString(),
    xl.IntCellValue(:final value) => '$value',
    xl.DoubleCellValue(:final value) =>
      value == value.roundToDouble() && value.abs() < 1e15
          ? '${value.toInt()}'
          : '$value',
    xl.DateCellValue(:final year, :final month, :final day) ||
    xl.DateTimeCellValue(:final year, :final month, :final day) =>
      '${year.toString().padLeft(4, '0')}-'
          '${month.toString().padLeft(2, '0')}-'
          '${day.toString().padLeft(2, '0')}',
    xl.FormulaCellValue(:final cachedValue) => cellText(cachedValue),
    xl.BoolCellValue() || xl.TimeCellValue() => value.toString(),
  };

  static CsvImportResult _error(String message) => CsvImportResult(
    fieldBook: null,
    measurements: const [],
    errors: [message],
  );
}
