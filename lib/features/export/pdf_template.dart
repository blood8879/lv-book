import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../l10n/l10n.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import '../pro/pro_pdf_settings.dart';
import 'export_judgement.dart';
import 'export_labels.dart';
import 'package:intl/intl.dart';

class PdfExporter {
  static Future<Uint8List> generateFieldBookPdf({
    required FieldBook fieldBook,
    required List<Measurement> measurements,
    required String bmName,
    required double startElevation,
    ProPdfSettings? proSettings,
    required AppLocalizations l10n,
  }) async {
    final ttf = await _loadKoreanFont();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _buildHeader(
          fieldBook,
          bmName,
          startElevation,
          ttf,
          proSettings,
          l10n,
        ),
        footer: (context) => _buildFooter(context, ttf, proSettings),
        build: (context) => [
          if (proSettings?.watermarkText.trim().isNotEmpty == true)
            pw.Center(
              child: pw.Text(
                proSettings!.watermarkText.trim(),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey400,
                ),
              ),
            ),
          pw.SizedBox(height: 12),
          _buildTable(measurements, ttf, l10n),
          pw.SizedBox(height: 16),
          _buildSummary(measurements, startElevation, ttf, proSettings, l10n),
          if (proSettings?.includeSignatureLines == true) ...[
            pw.SizedBox(height: 20),
            _buildSignatureLines(ttf, proSettings, l10n),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static Future<pw.Font> _loadKoreanFont() async {
    try {
      final bytes = await rootBundle.load(
        'assets/fonts/NotoSansKR-Regular.ttf',
      );
      return pw.Font.ttf(bytes);
    } catch (_) {
      return PdfGoogleFonts.notoSansKRRegular();
    }
  }

  static pw.Widget _buildHeader(
    FieldBook fieldBook,
    String bmName,
    double startElevation,
    pw.Font ttf,
    ProPdfSettings? proSettings,
    AppLocalizations l10n,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (proSettings?.hasBranding == true) ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                proSettings!.companyName.trim().isEmpty
                    ? l10n.exportCompanyNotSet
                    : proSettings.companyName.trim(),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (proSettings.authorName.trim().isNotEmpty)
                pw.Text(
                  l10n.exportLabelValue(
                    l10n.exportFieldAuthor,
                    proSettings.authorName.trim(),
                  ),
                  style: pw.TextStyle(font: ttf, fontSize: 10),
                ),
            ],
          ),
          pw.SizedBox(height: 8),
        ],
        pw.Center(
          child: pw.Text(
            proSettings == null
                ? l10n.exportDocTitle
                : l10n.exportDocTitleWithTemplate(
                    proSettings.documentTemplate.label(l10n),
                  ),
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
            pw.Text(
              l10n.exportLabelValue(l10n.exportFieldTitle, fieldBook.title),
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
            pw.Text(
              l10n.exportLabelValue(
                l10n.exportFieldDate,
                DateFormat('yyyy-MM-dd').format(fieldBook.date),
              ),
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              l10n.exportLabelValue(l10n.exportFieldStartBm, bmName),
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
            pw.Text(
              l10n.exportLabelValue(
                l10n.exportFieldBmElevation,
                '${startElevation.toStringAsFixed(3)} m',
              ),
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
          ],
        ),
        ..._metadataRows(fieldBook, ttf, l10n),
        if (fieldBook.memo != null && fieldBook.memo!.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              l10n.exportLabelValue(l10n.exportFieldMemo, fieldBook.memo!),
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
          ),
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 0.7, color: PdfColors.grey500),
      ],
    );
  }

  static List<pw.Widget> _metadataRows(
    FieldBook fieldBook,
    pw.Font ttf,
    AppLocalizations l10n,
  ) {
    final items = metadataLabelsForTest(fieldBook, l10n: l10n);
    if (items.isEmpty) return const [];
    return [
      pw.SizedBox(height: 4),
      pw.Wrap(
        spacing: 10,
        runSpacing: 2,
        children: [
          for (final item in items)
            pw.Text(item, style: pw.TextStyle(font: ttf, fontSize: 10)),
        ],
      ),
    ];
  }

  static List<String> metadataLabelsForTest(
    FieldBook fieldBook, {
    required AppLocalizations l10n,
  }) {
    String item(String label, String value) =>
        l10n.exportLabelValue(label, value);
    return [
      if (fieldBook.surveyor?.trim().isNotEmpty == true)
        item(l10n.exportFieldSurveyor, fieldBook.surveyor!.trim()),
      if (fieldBook.checker?.trim().isNotEmpty == true)
        item(l10n.exportFieldChecker, fieldBook.checker!.trim()),
      if (fieldBook.instrument?.trim().isNotEmpty == true)
        item(l10n.exportFieldInstrument, fieldBook.instrument!.trim()),
      if (fieldBook.weather?.trim().isNotEmpty == true)
        item(l10n.exportFieldWeather, fieldBook.weather!.trim()),
      if (fieldBook.workSection?.trim().isNotEmpty == true)
        item(l10n.exportFieldSection, fieldBook.workSection!.trim()),
      if (fieldBook.jobNumber?.trim().isNotEmpty == true)
        item(l10n.exportFieldJobNumber, fieldBook.jobNumber!.trim()),
      item(
        l10n.exportFieldReviewStatus,
        exportReviewStatusLabel(l10n, fieldBook.reviewStatus),
      ),
      if (fieldBook.reviewedAt != null)
        item(
          l10n.exportFieldReviewDate,
          DateFormat('yyyy-MM-dd').format(fieldBook.reviewedAt!),
        ),
      if (fieldBook.reviewMemo?.trim().isNotEmpty == true)
        item(l10n.exportFieldReviewMemo, fieldBook.reviewMemo!.trim()),
    ];
  }

  static pw.Widget _buildTable(
    List<Measurement> measurements,
    pw.Font ttf,
    AppLocalizations l10n,
  ) {
    final style = pw.TextStyle(font: ttf, fontSize: 10);
    final headerStyle = pw.TextStyle(
      font: ttf,
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );

    return pw.TableHelper.fromTextArray(
      headerStyle: headerStyle,
      cellStyle: style,
      headerAlignment: pw.Alignment.center,
      cellAlignment: pw.Alignment.center,
      cellHeight: 22,
      headerPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      cellPadding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.7),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headers: exportTableHeaders(l10n),
      data: measurements.asMap().entries.map((entry) {
        final i = entry.key;
        final m = entry.value;
        return [
          '${i + 1}',
          m.stationName,
          m.bs?.toStringAsFixed(3) ?? '-',
          m.fs?.toStringAsFixed(3) ?? '-',
          m.ih?.toStringAsFixed(3) ?? '-',
          m.gh?.toStringAsFixed(3) ?? '-',
          m.type == MeasurementType.tp ? 'TP' : '',
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildSummary(
    List<Measurement> measurements,
    double startElevation,
    pw.Font ttf,
    ProPdfSettings? proSettings,
    AppLocalizations l10n,
  ) {
    final sums = LevelCheckSums.from(
      measurements,
      startElevation: startElevation,
    );
    final sumBs = sums.sumBs;
    final sumFs = sums.sumFs;
    final firstGh = sums.firstGh;
    final lastGh = sums.lastGh;
    final error = LevelClosure.error(
      measurements,
      startElevation: startElevation,
    );
    final isOk = ExportJudgement.isSuitable(error);

    final style = pw.TextStyle(font: ttf, fontSize: 10);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey500, width: 0.7),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.exportCheckTitle,
            style: pw.TextStyle(
              font: ttf,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                l10n.exportCheckValue('ΣBS', sumBs.toStringAsFixed(3)),
                style: style,
              ),
              pw.Text(
                l10n.exportCheckValue('ΣFS', sumFs.toStringAsFixed(3)),
                style: style,
              ),
              pw.Text(
                l10n.exportCheckValue(
                  l10n.exportCheckDifference,
                  (sumBs - sumFs).toStringAsFixed(3),
                ),
                style: style,
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                l10n.exportCheckValue(
                  l10n.exportCheckStartRl,
                  firstGh.toStringAsFixed(3),
                ),
                style: style,
              ),
              pw.Text(
                l10n.exportCheckValue(
                  l10n.exportCheckFinalRl,
                  lastGh.toStringAsFixed(3),
                ),
                style: style,
              ),
              pw.Text(
                l10n.exportCheckValue(
                  l10n.exportCheckMisclosure,
                  error.toStringAsFixed(4),
                ),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: isOk ? PdfColors.green : PdfColors.red,
                ),
              ),
            ],
          ),
          if (proSettings?.includeCheckJudgement == true) ...[
            pw.SizedBox(height: 6),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: isOk ? PdfColors.green50 : PdfColors.red50,
                border: pw.Border.all(
                  color: isOk ? PdfColors.green : PdfColors.red,
                  width: 0.8,
                ),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                l10n.exportLabelValue(
                  l10n.exportCheckResult,
                  ExportJudgement.label(error, l10n: l10n),
                ),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: isOk ? PdfColors.green800 : PdfColors.red800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureLines(
    pw.Font ttf,
    ProPdfSettings? proSettings,
    AppLocalizations l10n,
  ) {
    pw.MemoryImage? signatureImage;
    final signature = proSettings?.signaturePng.trim() ?? '';
    if (signature.isNotEmpty) {
      try {
        signatureImage = pw.MemoryImage(base64Decode(signature));
      } catch (_) {
        signatureImage = null;
      }
    }

    pw.Widget cell(String title, {pw.MemoryImage? image}) {
      return pw.Expanded(
        child: pw.Container(
          height: 72,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey500, width: 0.7),
          ),
          child: pw.Column(
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 5),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey500, width: 0.7),
                  ),
                ),
                child: pw.Center(
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.Expanded(
                child: image == null
                    ? pw.SizedBox()
                    : pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Image(image, fit: pw.BoxFit.contain),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        cell(l10n.exportSignaturePrepared, image: signatureImage),
        pw.SizedBox(width: 8),
        cell(l10n.exportSignatureChecked),
        pw.SizedBox(width: 8),
        cell(l10n.exportSignatureApproved),
      ],
    );
  }

  static pw.Widget _buildFooter(
    pw.Context context,
    pw.Font ttf,
    ProPdfSettings? proSettings,
  ) {
    final footerNote = proSettings?.footerNote.trim() ?? '';
    return pw.Container(
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            footerNote,
            style: pw.TextStyle(font: ttf, fontSize: 9, color: PdfColors.grey),
          ),
          pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(font: ttf, fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }
}
