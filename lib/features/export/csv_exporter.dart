import 'package:csv/csv.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import '../pro/pro_pdf_settings.dart';
import 'export_judgement.dart';
import 'package:intl/intl.dart';

class CsvExporter {
  /// UTF-8 byte order mark. Excel needs it to open Korean CSV correctly.
  static const utf8Bom = '\uFEFF';

  /// Prepends [utf8Bom] for writing a CSV file (no-op if already present).
  static String withBom(String csv) =>
      csv.startsWith(utf8Bom) ? csv : '$utf8Bom$csv';

  static String generateFieldBookCsv({
    required FieldBook fieldBook,
    required List<Measurement> measurements,
    required String bmName,
    required double startElevation,
    ProPdfSettings? proSettings,
  }) {
    final rows = <List<dynamic>>[];

    // Header info
    rows.add(['직접수준측량 야장']);
    if (proSettings?.hasBranding == true) {
      if (proSettings!.companyName.trim().isNotEmpty) {
        rows.add(['회사명', proSettings.companyName.trim()]);
      }
      if (proSettings.authorName.trim().isNotEmpty) {
        rows.add(['작성자', proSettings.authorName.trim()]);
      }
    }
    rows.add(['야장명', fieldBook.title]);
    rows.add(['날짜', DateFormat('yyyy-MM-dd').format(fieldBook.date)]);
    _addMetadata(rows, '측량자', fieldBook.surveyor);
    _addMetadata(rows, '검측자', fieldBook.checker);
    _addMetadata(rows, '장비', fieldBook.instrument);
    _addMetadata(rows, '날씨', fieldBook.weather);
    _addMetadata(rows, '작업구간', fieldBook.workSection);
    _addMetadata(rows, '공사번호', fieldBook.jobNumber);
    if (proSettings != null) {
      rows.add(['검토 상태', fieldBook.reviewStatus.label]);
      _addMetadata(rows, '검토 메모', fieldBook.reviewMemo);
      _addMetadata(
        rows,
        '검토일',
        fieldBook.reviewedAt == null
            ? null
            : DateFormat('yyyy-MM-dd').format(fieldBook.reviewedAt!),
      );
    }
    rows.add(['시작 BM', bmName]);
    rows.add(['BM 표고', startElevation.toStringAsFixed(3)]);
    rows.add([]);

    // Table header
    rows.add(['No.', '측점명', '후시(BS)', '전시(FS)', '기계고(IH)', '지반고(GH)', '비고']);

    // Data rows
    for (int i = 0; i < measurements.length; i++) {
      final m = measurements[i];
      rows.add([
        i + 1,
        m.stationName,
        m.bs?.toStringAsFixed(3) ?? '',
        m.fs?.toStringAsFixed(3) ?? '',
        m.ih?.toStringAsFixed(3) ?? '',
        m.gh?.toStringAsFixed(3) ?? '',
        m.type == MeasurementType.tp ? 'TP' : '',
      ]);
    }

    // Summary (검산): ΣFS counts only turning points and the final point so
    // that ΣBS − ΣFS equals 최종 GH − 시작 GH, consistent with LevelClosure.
    final sums = LevelCheckSums.from(
      measurements,
      startElevation: startElevation,
    );
    rows.add([]);
    rows.add([
      'ΣBS',
      sums.sumBs.toStringAsFixed(3),
      'ΣFS',
      sums.sumFs.toStringAsFixed(3),
    ]);
    rows.add(['ΣBS - ΣFS', sums.difference.toStringAsFixed(3)]);
    if (proSettings?.includeCheckJudgement == true) {
      final error = LevelClosure.error(
        measurements,
        startElevation: startElevation,
      );
      rows.add(['오차', error.toStringAsFixed(4)]);
      rows.add(['검산 판정', ExportJudgement.label(error)]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  static void _addMetadata(
    List<List<dynamic>> rows,
    String label,
    String? value,
  ) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    rows.add([label, trimmed]);
  }
}
