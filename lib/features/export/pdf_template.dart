import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import '../pro/pro_pdf_settings.dart';
import 'export_judgement.dart';
import 'package:intl/intl.dart';

class PdfExporter {
  static Future<Uint8List> generateFieldBookPdf({
    required FieldBook fieldBook,
    required List<Measurement> measurements,
    required String bmName,
    required double startElevation,
    ProPdfSettings? proSettings,
  }) async {
    final ttf = await _loadKoreanFont();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) =>
            _buildHeader(fieldBook, bmName, startElevation, ttf, proSettings),
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
          _buildTable(measurements, ttf),
          pw.SizedBox(height: 16),
          _buildSummary(measurements, startElevation, ttf, proSettings),
          if (proSettings?.includeSignatureLines == true) ...[
            pw.SizedBox(height: 20),
            _buildSignatureLines(ttf),
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
                    ? '회사명 미입력'
                    : proSettings.companyName.trim(),
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (proSettings.authorName.trim().isNotEmpty)
                pw.Text(
                  '작성자: ${proSettings.authorName.trim()}',
                  style: pw.TextStyle(font: ttf, fontSize: 10),
                ),
            ],
          ),
          pw.SizedBox(height: 8),
        ],
        pw.Center(
          child: pw.Text(
            proSettings == null
                ? '직접수준측량 야장'
                : '직접수준측량 야장 · ${proSettings.documentTemplate.title}',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '야장명: ${fieldBook.title}',
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
            pw.Text(
              '날짜: ${DateFormat('yyyy-MM-dd').format(fieldBook.date)}',
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '시작 BM: $bmName',
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
            pw.Text(
              'BM 표고: ${startElevation.toStringAsFixed(3)} m',
              style: pw.TextStyle(font: ttf, fontSize: 12),
            ),
          ],
        ),
        ..._metadataRows(fieldBook, ttf),
        if (fieldBook.memo != null && fieldBook.memo!.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4),
            child: pw.Text(
              '메모: ${fieldBook.memo}',
              style: pw.TextStyle(font: ttf, fontSize: 10),
            ),
          ),
        pw.Divider(),
      ],
    );
  }

  static List<pw.Widget> _metadataRows(FieldBook fieldBook, pw.Font ttf) {
    final items = metadataLabelsForTest(fieldBook);
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

  static List<String> metadataLabelsForTest(FieldBook fieldBook) {
    return [
      if (fieldBook.surveyor?.trim().isNotEmpty == true)
        '측량자: ${fieldBook.surveyor!.trim()}',
      if (fieldBook.checker?.trim().isNotEmpty == true)
        '검측자: ${fieldBook.checker!.trim()}',
      if (fieldBook.instrument?.trim().isNotEmpty == true)
        '장비: ${fieldBook.instrument!.trim()}',
      if (fieldBook.weather?.trim().isNotEmpty == true)
        '날씨: ${fieldBook.weather!.trim()}',
      if (fieldBook.workSection?.trim().isNotEmpty == true)
        '작업구간: ${fieldBook.workSection!.trim()}',
      if (fieldBook.jobNumber?.trim().isNotEmpty == true)
        '공사번호: ${fieldBook.jobNumber!.trim()}',
      '검토 상태: ${fieldBook.reviewStatus.label}',
      if (fieldBook.reviewedAt != null)
        '검토일: ${DateFormat('yyyy-MM-dd').format(fieldBook.reviewedAt!)}',
      if (fieldBook.reviewMemo?.trim().isNotEmpty == true)
        '검토 메모: ${fieldBook.reviewMemo!.trim()}',
    ];
  }

  static pw.Widget _buildTable(List<Measurement> measurements, pw.Font ttf) {
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
      border: pw.TableBorder.all(width: 0.5),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      headers: ['No.', '측점명', '후시(BS)', '전시(FS)', '기계고(IH)', '지반고(GH)', '비고'],
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
  ) {
    double sumBs = 0;
    double sumFs = 0;
    for (final m in measurements) {
      if (m.bs != null) sumBs += m.bs!;
      if (m.fs != null) sumFs += m.fs!;
    }

    final firstGh = measurements.isNotEmpty
        ? (measurements.first.gh ?? startElevation)
        : startElevation;
    final lastGh = measurements.isNotEmpty
        ? (measurements.last.gh ?? firstGh)
        : firstGh;
    final error = sumBs - sumFs - (lastGh - firstGh);
    final isOk = ExportJudgement.isSuitable(error);

    final style = pw.TextStyle(font: ttf, fontSize: 10);

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '검산',
            style: pw.TextStyle(
              font: ttf,
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('ΣBS = ${sumBs.toStringAsFixed(3)}', style: style),
              pw.Text('ΣFS = ${sumFs.toStringAsFixed(3)}', style: style),
              pw.Text(
                'ΣBS - ΣFS = ${(sumBs - sumFs).toStringAsFixed(3)}',
                style: style,
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('시작 GH = ${firstGh.toStringAsFixed(3)}', style: style),
              pw.Text('최종 GH = ${lastGh.toStringAsFixed(3)}', style: style),
              pw.Text(
                '오차 = ${error.toStringAsFixed(4)}',
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
                horizontal: 8,
                vertical: 5,
              ),
              decoration: pw.BoxDecoration(
                color: isOk ? PdfColors.green50 : PdfColors.red50,
                border: pw.Border.all(
                  color: isOk ? PdfColors.green : PdfColors.red,
                  width: 0.5,
                ),
              ),
              child: pw.Text(
                '검산 판정: ${isOk ? '적합' : '확인 필요'}',
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

  static pw.Widget _buildSignatureLines(pw.Font ttf) {
    pw.Widget cell(String title) {
      return pw.Expanded(
        child: pw.Container(
          height: 54,
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          child: pw.Column(
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Center(
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(font: ttf, fontSize: 10),
                  ),
                ),
              ),
              pw.Expanded(child: pw.SizedBox()),
            ],
          ),
        ),
      );
    }

    return pw.Row(children: [cell('작성'), cell('검토'), cell('승인')]);
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
