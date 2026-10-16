import 'dart:typed_data';

import 'package:excel_community/excel_community.dart' as xl;
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../fieldbook/domain/design_level.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import '../fieldbook/domain/misclosure.dart';
import '../fieldbook/domain/reduction.dart';
import '../pro/pro_pdf_settings.dart';
import 'export_judgement.dart';
import 'export_labels.dart';

/// Native Excel (.xlsx) level book: one worksheet with the header block, the
/// measurement table (same columns and order as the PDF) and the check
/// footer. Readings, RLs and check values are numeric cells shown with 3
/// decimals (misclosure 4), so they can be summed or charted in Excel;
/// labels follow the app language like the PDF/CSV.
class XlsxExporter {
  /// MIME type for the share sheet (receiving apps pick Excel/Sheets).
  static const mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// Readings, RLs, sums: 3 decimals like every other export.
  static final _reading = xl.CustomNumericNumFormat(formatCode: '0.000');

  /// Misclosure: signed, 4 decimals ('+0.0012', see [formatMisclosure]).
  static final _misclosure = xl.CustomNumericNumFormat(
    formatCode: '+0.0000;-0.0000;0.0000',
  );

  /// Allowed misclosure: '±0.0050' ([formatAllowedMisclosure]).
  static final _allowed = xl.CustomNumericNumFormat(formatCode: '"±"0.0000');

  static Uint8List generateFieldBookXlsx({
    required FieldBook fieldBook,
    required List<Measurement> measurements,
    required String bmName,
    required double startElevation,
    String? closingBmName,
    String projectName = '',
    MisclosureTolerance tolerance = MisclosureTolerance.defaults,
    ProPdfSettings? proSettings,
    required AppLocalizations l10n,
  }) {
    final excel = xl.Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final sheetName = sheetNameFor(l10n);
    excel.rename(defaultSheet, sheetName);
    final sheet = excel[sheetName];
    final writer = _SheetWriter(sheet);

    // Lettered cut/fill ('C 0.125' / 'F 0.040') while the cell stays a
    // signed number (cut +, fill −) like the CSV.
    final cut = _quoted(l10n.exportCutLetter);
    final fill = _quoted(l10n.exportFillLetter);
    final cutFillFormat = xl.CustomNumericNumFormat(
      formatCode: '"$cut "0.000;"$fill "0.000;0.000',
    );

    // Header block (same fields as the CSV, plus the project name).
    writer.row([l10n.exportDocTitle], style: _titleStyle);
    if (proSettings?.hasBranding == true) {
      writer.pair(l10n.exportFieldCompany, proSettings!.companyName.trim());
      writer.pair(l10n.exportFieldAuthor, proSettings.authorName.trim());
    }
    writer.pair(l10n.exportFieldProject, projectName.trim());
    writer.pair(l10n.exportFieldTitle, fieldBook.title);
    writer.pair(
      l10n.exportFieldDate,
      DateFormat('yyyy-MM-dd').format(fieldBook.date),
    );
    writer.pair(l10n.exportFieldSurveyor, fieldBook.surveyor?.trim());
    writer.pair(l10n.exportFieldChecker, fieldBook.checker?.trim());
    writer.pair(l10n.exportFieldInstrument, fieldBook.instrument?.trim());
    writer.pair(l10n.exportFieldWeather, fieldBook.weather?.trim());
    writer.pair(l10n.exportFieldSection, fieldBook.workSection?.trim());
    writer.pair(l10n.exportFieldJobNumber, fieldBook.jobNumber?.trim());
    if (proSettings != null) {
      writer.pair(
        l10n.exportFieldReviewStatus,
        exportReviewStatusLabel(l10n, fieldBook.reviewStatus),
      );
      writer.pair(l10n.exportFieldReviewMemo, fieldBook.reviewMemo?.trim());
      writer.pair(
        l10n.exportFieldReviewDate,
        fieldBook.reviewedAt == null
            ? null
            : DateFormat('yyyy-MM-dd').format(fieldBook.reviewedAt!),
      );
    }
    writer.pair(l10n.exportFieldStartBm, bmName);
    writer.pair(l10n.exportFieldBmElevation, startElevation);
    final method = fieldBook.reductionMethod;
    writer.pair(
      l10n.exportFieldReductionMethod,
      exportReductionMethodLabel(l10n, method),
    );
    writer.pair(l10n.exportFieldUnit, tolerance.unit.symbol);
    writer.pair(l10n.exportFieldRouteLength, fieldBook.routeLength);
    final closingElevation = fieldBook.closingElevationFor(startElevation);
    if (closingElevation != null) {
      writer.pair(l10n.exportFieldClosingBm, switch (fieldBook.closingMode) {
        ClosingReferenceMode.loop => l10n.exportClosingLoopName(bmName),
        ClosingReferenceMode.benchmark => closingBmName,
        _ => null,
      });
      writer.pair(l10n.exportFieldClosingRl, closingElevation);
    }
    writer.blank();

    // Measurement table: the PDF layout (design columns next to RL).
    final columns = exportTableColumns(
      method: method,
      intermediateSights: exportUsesIntermediateColumn(l10n),
      design: exportsDesignColumns(fieldBook, measurements),
      designBeforeRemarks: true,
    );
    writer.row([
      for (final c in columns) exportColumnHeader(l10n, c),
    ], style: _tableHeaderStyle);
    for (final values in exportTableValues(measurements, columns: columns)) {
      writer.row(
        values,
        formatFor: (c) =>
            columns[c] == ExportColumn.cutFill ? cutFillFormat : _reading,
      );
    }
    writer.blank();

    // Check footer: the PDF check box items, one per row.
    final closure = LevelClosureCheck.compute(
      measurements,
      startElevation: startElevation,
      closingElevation: closingElevation,
      tolerance: tolerance,
      method: method,
      routeLength: fieldBook.routeLength,
    );
    for (final (label, value, format) in checkItems(closure, l10n: l10n)) {
      if (value == null) {
        writer.row([label], style: _boldStyle);
      } else {
        writer.row([label, value], formatFor: (_) => format ?? _reading);
      }
    }
    // Shown by default; follows the PDF's "include judgement" setting.
    if (proSettings?.includeCheckJudgement ?? true) {
      writer.row([
        l10n.exportCheckResult,
        ExportJudgement.labelForClosure(closure, l10n: l10n),
      ], style: _boldStyle);
    }

    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 16);
    for (var c = 2; c < columns.length; c++) {
      sheet.setColumnWidth(c, 12);
    }

    return Uint8List.fromList(excel.encode()!);
  }

  /// Worksheet name: the localized "Level book" without the characters
  /// Excel rejects, at most 31 characters.
  static String sheetNameFor(AppLocalizations l10n) {
    final name = l10n.exportXlsxSheetName
        .replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ')
        .trim();
    if (name.isEmpty) return 'Sheet1';
    return name.length > 31 ? name.substring(0, 31) : name;
  }

  /// Check footer items as (label, value, number format); a null value is a
  /// section title. Same labels and order as the PDF check box
  /// ([PdfExporter.checkRowsForTest]), with numbers instead of text.
  static List<(String, Object?, xl.NumFormat?)> checkItems(
    LevelClosureCheck closure, {
    required AppLocalizations l10n,
  }) {
    final sums = closure.sums;
    final misclosure = closure.misclosure;
    return [
      (
        closure.hasClosing
            ? l10n.exportCheckTitleWithClosure
            : l10n.exportCheckTitle,
        null,
        null,
      ),
      (l10n.exportCheckSumBs, sums.sumBs, null),
      (l10n.exportCheckSumFs, sums.sumFs, null),
      (l10n.exportCheckDifference, sums.difference, null),
      (l10n.exportCheckStartRl, sums.firstGh, null),
      (l10n.exportCheckFinalRl, sums.lastGh, null),
      (l10n.exportCheckRlDifference, sums.lastGh - sums.firstGh, null),
      if (closure.method == ReductionMethod.riseAndFall) ...[
        (l10n.exportCheckSumRise, closure.riseFall.sumRise, null),
        (l10n.exportCheckSumFall, closure.riseFall.sumFall, null),
        (l10n.exportCheckRiseFallDifference, closure.riseFall.difference, null),
      ],
      if (misclosure == null)
        (
          l10n.exportCheckMisclosure,
          l10n.exportCheckMisclosureUnavailable,
          null,
        )
      else ...[
        (l10n.exportFieldClosingRl, closure.closingElevation!, null),
        (l10n.exportCheckMisclosure, _round(misclosure, 4), _misclosure),
        closure.allowed == null
            ? (
                l10n.exportCheckAllowed,
                l10n.exportCheckAllowedUnavailable,
                null,
              )
            : (l10n.exportCheckAllowed, _round(closure.allowed!, 4), _allowed),
        if (closure.allowedFormula != null)
          (l10n.exportCheckToleranceRule, closure.allowedFormula!, null),
      ],
    ];
  }

  /// Rounds to [decimals] (misclosure: the printed precision, so the stored
  /// value matches the PDF text); never returns -0.
  static double _round(double value, int decimals) {
    final rounded = double.parse(value.toStringAsFixed(decimals));
    return rounded == 0 ? 0 : rounded;
  }

  /// Escapes a literal for a quoted number-format section.
  static String _quoted(String text) => text.replaceAll('"', '');

  static final _titleStyle = xl.CellStyle(bold: true, fontSize: 14);
  static final _boldStyle = xl.CellStyle(bold: true);
  static final _tableHeaderStyle = xl.CellStyle(
    bold: true,
    horizontalAlign: xl.HorizontalAlign.Center,
    backgroundColorHex: xl.ExcelColor.fromHexString('#EEEEEE'),
  );
}

/// Appends rows to a sheet: [String] → text, [int] → integer, [double] →
/// number with the column's format, null or '' → empty cell.
class _SheetWriter {
  final xl.Sheet sheet;
  int _row = 0;

  _SheetWriter(this.sheet);

  void blank() => _row++;

  /// Header field (label | value); skipped when the value is empty.
  void pair(String label, Object? value) {
    if (value == null || (value is String && value.isEmpty)) return;
    row([label, value]);
  }

  void row(
    List<Object?> values, {
    xl.CellStyle? style,
    xl.NumFormat Function(int column)? formatFor,
  }) {
    for (var c = 0; c < values.length; c++) {
      final value = values[c];
      if (value == null || value == '') continue;
      final cell = sheet.cell(
        xl.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: _row),
      );
      switch (value) {
        case final int number:
          cell.value = xl.IntCellValue(number);
        case final double number:
          // 6 decimals drop float noise (102.16399999999999 → 102.164)
          // without rounding away entered precision.
          cell.value = xl.DoubleCellValue(XlsxExporter._round(number, 6));
          cell.cellStyle = (style ?? xl.CellStyle()).copyWith(
            numberFormat: formatFor?.call(c) ?? XlsxExporter._reading,
          );
          continue;
        default:
          cell.value = xl.TextCellValue('$value');
      }
      if (style != null) cell.cellStyle = style;
    }
    _row++;
  }
}
