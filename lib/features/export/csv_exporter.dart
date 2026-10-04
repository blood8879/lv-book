import 'package:csv/csv.dart';
import '../../l10n/l10n.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import '../fieldbook/domain/misclosure.dart';
import '../pro/pro_pdf_settings.dart';
import 'export_judgement.dart';
import 'export_labels.dart';
import 'package:intl/intl.dart';

class CsvExporter {
  /// UTF-8 byte order mark. Excel needs it to open Korean CSV correctly.
  static const utf8Bom = '\uFEFF';

  /// Prepends [utf8Bom] for writing a CSV file (no-op if already present).
  static String withBom(String csv) =>
      csv.startsWith(utf8Bom) ? csv : '$utf8Bom$csv';

  /// Labels follow the app language ([l10n]); `CsvImporter` accepts both the
  /// Korean and English labels, and the 'TP' remark marker is not localized.
  static String generateFieldBookCsv({
    required FieldBook fieldBook,
    required List<Measurement> measurements,
    required String bmName,
    required double startElevation,
    String? closingBmName,
    MisclosureTolerance tolerance = MisclosureTolerance.defaults,
    ProPdfSettings? proSettings,
    required AppLocalizations l10n,
  }) {
    final rows = <List<dynamic>>[];

    // Header info
    rows.add([l10n.exportDocTitle]);
    if (proSettings?.hasBranding == true) {
      if (proSettings!.companyName.trim().isNotEmpty) {
        rows.add([l10n.exportFieldCompany, proSettings.companyName.trim()]);
      }
      if (proSettings.authorName.trim().isNotEmpty) {
        rows.add([l10n.exportFieldAuthor, proSettings.authorName.trim()]);
      }
    }
    rows.add([l10n.exportFieldTitle, fieldBook.title]);
    rows.add([
      l10n.exportFieldDate,
      DateFormat('yyyy-MM-dd').format(fieldBook.date),
    ]);
    _addMetadata(rows, l10n.exportFieldSurveyor, fieldBook.surveyor);
    _addMetadata(rows, l10n.exportFieldChecker, fieldBook.checker);
    _addMetadata(rows, l10n.exportFieldInstrument, fieldBook.instrument);
    _addMetadata(rows, l10n.exportFieldWeather, fieldBook.weather);
    _addMetadata(rows, l10n.exportFieldSection, fieldBook.workSection);
    _addMetadata(rows, l10n.exportFieldJobNumber, fieldBook.jobNumber);
    if (proSettings != null) {
      rows.add([
        l10n.exportFieldReviewStatus,
        exportReviewStatusLabel(l10n, fieldBook.reviewStatus),
      ]);
      _addMetadata(rows, l10n.exportFieldReviewMemo, fieldBook.reviewMemo);
      _addMetadata(
        rows,
        l10n.exportFieldReviewDate,
        fieldBook.reviewedAt == null
            ? null
            : DateFormat('yyyy-MM-dd').format(fieldBook.reviewedAt!),
      );
    }
    rows.add([l10n.exportFieldStartBm, bmName]);
    rows.add([l10n.exportFieldBmElevation, startElevation.toStringAsFixed(3)]);
    // Closing reference (absent when none). A loop writes the start BM name
    // with the start RL, which `CsvImporter` reads back as a loop.
    final closingElevation = fieldBook.closingElevationFor(startElevation);
    if (closingElevation != null) {
      final closingName = switch (fieldBook.closingMode) {
        ClosingReferenceMode.loop => bmName,
        ClosingReferenceMode.benchmark => closingBmName,
        _ => null,
      };
      _addMetadata(rows, l10n.exportFieldClosingBm, closingName);
      rows.add([
        l10n.exportFieldClosingRl,
        closingElevation.toStringAsFixed(3),
      ]);
    }
    rows.add([]);

    // Table header
    rows.add(exportTableHeaders(l10n));

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
    final closure = LevelClosureCheck.compute(
      measurements,
      startElevation: startElevation,
      closingElevation: closingElevation,
      tolerance: tolerance,
    );
    final sums = closure.sums;
    rows.add([]);
    rows.add([
      'ΣBS',
      sums.sumBs.toStringAsFixed(3),
      'ΣFS',
      sums.sumFs.toStringAsFixed(3),
    ]);
    rows.add([l10n.exportCheckDifference, sums.difference.toStringAsFixed(3)]);
    rows.add([
      l10n.exportCheckRlDifference,
      (sums.lastGh - sums.firstGh).toStringAsFixed(3),
    ]);
    if (proSettings?.includeCheckJudgement == true) {
      final misclosure = closure.misclosure;
      if (misclosure == null) {
        rows.add([
          l10n.exportCheckMisclosure,
          l10n.exportCheckMisclosureUnavailable,
        ]);
      } else {
        rows.add([l10n.exportCheckMisclosure, formatMisclosure(misclosure)]);
        rows.add([
          l10n.exportCheckAllowed,
          formatAllowedMisclosure(closure.allowed),
        ]);
      }
      rows.add([
        l10n.exportCheckResult,
        ExportJudgement.labelFor(closure.isSuitable, l10n: l10n),
      ]);
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
