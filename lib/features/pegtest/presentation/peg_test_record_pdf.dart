import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../l10n/l10n.dart';
import '../../export/pdf_template.dart';
import '../../fieldbook/domain/misclosure.dart';
import '../../pro/pro_pdf_settings.dart';
import '../../settings/misclosure_tolerance_repository.dart';
import '../domain/peg_test_record.dart';
import 'peg_test_screen.dart';

/// One-page "Two-peg test record" PDF: metadata, the setup 1/2 readings,
/// results, tolerance and verdict, and signature boxes. Uses the field book
/// PDF conventions (NotoSansKR, company / author header, registered
/// signature, footer note from the PDF document settings).
class PegTestRecordPdf {
  static final _dateTime = DateFormat('yyyy-MM-dd HH:mm');

  static Future<Uint8List> generate({
    required PegTestRecord record,
    required AppLocalizations l10n,
    ProPdfSettings? proSettings,
  }) async {
    final ttf = await PdfExporter.loadDocumentFont();
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            ..._header(record, ttf, proSettings, l10n),
            pw.SizedBox(height: 14),
            _sectionTitle(l10n.pegTestReadingsTitle, ttf),
            pw.SizedBox(height: 6),
            _readingsTable(record, ttf, l10n),
            pw.SizedBox(height: 6),
            pw.Text(
              l10n.exportLabelValue(
                l10n.pegTestDistanceLabel(record.unit.symbol),
                record.pegDistance.toStringAsFixed(3),
              ),
              style: pw.TextStyle(font: ttf, fontSize: 11),
            ),
            pw.SizedBox(height: 14),
            _results(record, ttf, l10n),
            if (record.note != null) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                l10n.exportLabelValue(l10n.pegTestNoteLabel, record.note!),
                style: pw.TextStyle(font: ttf, fontSize: 10),
              ),
            ],
            pw.Spacer(),
            PdfExporter.buildSignatureLines(ttf, proSettings, l10n),
            if (proSettings?.footerNote.trim().isNotEmpty == true) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                proSettings!.footerNote.trim(),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 9,
                  color: PdfColors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return pdf.save();
  }

  /// Header items ('Date: …', 'Instrument: …', …) as printed; also used by
  /// tests. Missing instrument / observer print as '-'.
  static List<String> headerItemsForTest(
    PegTestRecord record,
    AppLocalizations l10n,
  ) {
    String item(String label, String value) =>
        l10n.exportLabelValue(label, value);
    return [
      item(l10n.exportFieldDate, _dateTime.format(record.createdAt)),
      item(l10n.pegTestInstrumentLabel, record.instrument ?? '-'),
      item(l10n.pegTestObserverLabel, record.observer ?? '-'),
      item(l10n.exportFieldUnit, record.unit.symbol),
    ];
  }

  /// Result rows (label, value) in print order; also used by tests.
  static List<(String, String)> resultRowsForTest(
    PegTestRecord record,
    AppLocalizations l10n,
  ) {
    final test = record.test;
    final unit = record.unit;
    return [
      (
        l10n.pegTestTrueDifference,
        '${formatSigned(test.trueDifference, 3)} ${unit.symbol}',
      ),
      (l10n.pegTestCorrectReading, formatPegTestReading(test.expectedB2, unit)),
      (l10n.pegTestCollimationError, formatPegTestError(test.error, unit)),
      (
        l10n.pegTestErrorPer100(unit.symbol),
        formatPegTestError(test.errorPer100, unit),
      ),
      (l10n.pegTestAngle, formatArcSeconds(test.arcSeconds)),
      (
        l10n.pegTestToleranceLabel,
        l10n.pegTestToleranceValue(
          formatToleranceValue(test.toleranceEntry),
          unit.toleranceSymbol,
        ),
      ),
    ];
  }

  static List<pw.Widget> _header(
    PegTestRecord record,
    pw.Font ttf,
    ProPdfSettings? proSettings,
    AppLocalizations l10n,
  ) {
    final company = proSettings?.companyName.trim() ?? '';
    final author = proSettings?.authorName.trim() ?? '';
    final items = headerItemsForTest(record, l10n);
    final style = pw.TextStyle(font: ttf, fontSize: 11);
    return [
      if (company.isNotEmpty || author.isNotEmpty) ...[
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              company,
              style: pw.TextStyle(
                font: ttf,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (author.isNotEmpty)
              pw.Text(
                l10n.exportLabelValue(l10n.exportFieldAuthor, author),
                style: pw.TextStyle(font: ttf, fontSize: 10),
              ),
          ],
        ),
        pw.SizedBox(height: 8),
      ],
      pw.Center(
        child: pw.Text(
          l10n.pegTestRecordTitle,
          style: pw.TextStyle(
            font: ttf,
            fontSize: 21,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ),
      pw.SizedBox(height: 14),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(items[0], style: style),
          pw.Text(items[3], style: style),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(items[1], style: style),
          pw.Text(items[2], style: style),
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Divider(thickness: 0.7, color: PdfColors.grey500),
    ];
  }

  static pw.Widget _sectionTitle(String text, pw.Font ttf) => pw.Text(
    text,
    style: pw.TextStyle(
      font: ttf,
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    ),
  );

  static pw.Widget _readingsTable(
    PegTestRecord record,
    pw.Font ttf,
    AppLocalizations l10n,
  ) {
    final symbol = record.unit.symbol;
    String reading(double value) => value.toStringAsFixed(3);
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        font: ttf,
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      cellHeight: 22,
      headerPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.7),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      headers: [
        '',
        l10n.pegTestReadingALabel(symbol),
        l10n.pegTestReadingBLabel(symbol),
      ],
      data: [
        [l10n.pegTestSetup1Title, reading(record.a1), reading(record.b1)],
        [l10n.pegTestSetup2Title, reading(record.a2), reading(record.b2)],
      ],
    );
  }

  static pw.Widget _results(
    PegTestRecord record,
    pw.Font ttf,
    AppLocalizations l10n,
  ) {
    final test = record.test;
    final ok = test.withinTolerance;
    final style = pw.TextStyle(font: ttf, fontSize: 10.5);
    final valueStyle = style.copyWith(fontWeight: pw.FontWeight.bold);
    final rows = resultRowsForTest(record, l10n);
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey500, width: 0.7),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(l10n.pegTestResultTitle, ttf),
          for (final (label, value) in rows) ...[
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(label, style: style),
                pw.Text(value, style: valueStyle),
              ],
            ),
          ],
          if (test.error.abs() > toleranceEpsilon) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              test.error > 0
                  ? l10n.pegTestInclinedUp
                  : l10n.pegTestInclinedDown,
              style: style.copyWith(fontSize: 9.5, color: PdfColors.grey700),
            ),
          ],
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: ok ? PdfColors.green50 : PdfColors.orange50,
              border: pw.Border.all(
                color: ok ? PdfColors.green : PdfColors.orange,
                width: 0.8,
              ),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              l10n.exportLabelValue(
                l10n.pegTestSummaryResult,
                pegTestVerdict(l10n, test),
              ),
              style: pw.TextStyle(
                font: ttf,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: ok ? PdfColors.green800 : PdfColors.orange800,
              ),
            ),
          ),
          if (!ok) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              l10n.pegTestAdjustInstruction(
                test.expectedB2.toStringAsFixed(3),
                record.unit.symbol,
              ),
              style: style.copyWith(fontSize: 9.5),
            ),
          ],
        ],
      ),
    );
  }
}
