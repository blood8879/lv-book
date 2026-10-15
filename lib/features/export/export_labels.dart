import '../../l10n/l10n.dart';
import '../fieldbook/domain/design_level.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import '../fieldbook/domain/misclosure.dart';
import '../fieldbook/domain/reduction.dart';

/// Export-document labels for domain enums, in the export (app) language.
String exportReviewStatusLabel(
  AppLocalizations l10n,
  FieldBookReviewStatus status,
) => switch (status) {
  FieldBookReviewStatus.draft => l10n.exportReviewStatusDraft,
  FieldBookReviewStatus.reviewed => l10n.exportReviewStatusReviewed,
  FieldBookReviewStatus.needsCheck => l10n.exportReviewStatusNeedsCheck,
};

/// 'Height of instrument' / 'Rise and fall' (기고식 / 승강식).
String exportReductionMethodLabel(
  AppLocalizations l10n,
  ReductionMethod method,
) => switch (method) {
  ReductionMethod.heightOfInstrument => l10n.exportReductionHi,
  ReductionMethod.riseAndFall => l10n.exportReductionRiseFall,
};

/// Columns of the measurement table.
enum ExportColumn {
  no,
  station,
  bs,
  intermediate,
  fs,
  hi,
  rise,
  fall,
  rl,
  remarks,

  /// Design level (계획고); only for books that show design levels.
  design,

  /// Cut (+) / fill (−) = RL − design level.
  cutFill,
}

/// English and Spanish exports use the standard level book layout
/// BS | IS | FS (VAt | VI | VAd) for both methods; Korean exports keep their
/// original layout (intermediate sights stay in the FS column) so existing
/// users see no change.
bool exportUsesIntermediateColumn(AppLocalizations l10n) =>
    !l10n.localeName.startsWith('ko');

/// No. / Station / BS / [IS] / FS / HI or Rise, Fall / RL / Remarks.
/// With [design] (see `exportsDesignColumns`), Design / Cut-Fill follow
/// Remarks at the end (CSV, so older importers' column positions never
/// shift) or, with [designBeforeRemarks], sit next to RL (PDF).
List<ExportColumn> exportTableColumns({
  ReductionMethod method = ReductionMethod.heightOfInstrument,
  bool intermediateSights = false,
  bool design = false,
  bool designBeforeRemarks = false,
}) => [
  ExportColumn.no,
  ExportColumn.station,
  ExportColumn.bs,
  if (intermediateSights) ExportColumn.intermediate,
  ExportColumn.fs,
  if (method == ReductionMethod.riseAndFall) ...[
    ExportColumn.rise,
    ExportColumn.fall,
  ] else
    ExportColumn.hi,
  ExportColumn.rl,
  if (design && designBeforeRemarks) ...[
    ExportColumn.design,
    ExportColumn.cutFill,
  ],
  ExportColumn.remarks,
  if (design && !designBeforeRemarks) ...[
    ExportColumn.design,
    ExportColumn.cutFill,
  ],
];

String exportColumnHeader(AppLocalizations l10n, ExportColumn column) =>
    switch (column) {
      ExportColumn.no => l10n.exportColumnNo,
      ExportColumn.station => l10n.exportColumnStation,
      ExportColumn.bs => l10n.exportColumnBs,
      ExportColumn.intermediate => l10n.exportColumnIs,
      ExportColumn.fs => l10n.exportColumnFs,
      ExportColumn.hi => l10n.exportColumnHi,
      ExportColumn.rise => l10n.exportColumnRise,
      ExportColumn.fall => l10n.exportColumnFall,
      ExportColumn.rl => l10n.exportColumnRl,
      ExportColumn.remarks => l10n.exportColumnRemarks,
      ExportColumn.design => l10n.exportColumnDesign,
      ExportColumn.cutFill => l10n.exportColumnCutFill,
    };

/// Measurement table headers (defaults: No. / Station / BS / FS / HI / RL /
/// Remarks).
List<String> exportTableHeaders(
  AppLocalizations l10n, {
  ReductionMethod method = ReductionMethod.heightOfInstrument,
  bool intermediateSights = false,
}) => [
  for (final column in exportTableColumns(
    method: method,
    intermediateSights: intermediateSights,
  ))
    exportColumnHeader(l10n, column),
];

/// Measurement table cells for [columns]; [empty] fills a missing value
/// ('-' in PDF, '' in CSV). Readings/RLs keep 3 decimals. With an IS column,
/// intermediate sights ([intermediateSightFlags]) move from FS to IS. Rise
/// and fall are printed unsigned in their own column (0 counts as a rise).
/// Cut/fill is signed ('0.125' / '-0.040', [formatCutFillSigned]) unless
/// [cutFillText] formats it (PDF: 'C 0.125' / 'F 0.040').
List<List<String>> exportTableRows(
  List<Measurement> measurements, {
  required List<ExportColumn> columns,
  String empty = '',
  String Function(double cutFill) cutFillText = formatCutFillSigned,
}) {
  String fmt(double? value) => value?.toStringAsFixed(3) ?? empty;
  String cutFill(Measurement m) {
    final value = measurementCutFill(m);
    return value == null ? empty : cutFillText(value);
  }

  final riseFall = riseFallOf(measurements);
  final intermediate = columns.contains(ExportColumn.intermediate)
      ? intermediateSightFlags(measurements)
      : List.filled(measurements.length, false);
  return [
    for (var i = 0; i < measurements.length; i++)
      [
        for (final column in columns)
          switch (column) {
            ExportColumn.no => '${i + 1}',
            ExportColumn.station => measurements[i].stationName,
            ExportColumn.bs => fmt(measurements[i].bs),
            ExportColumn.intermediate =>
              intermediate[i] ? fmt(measurements[i].fs) : empty,
            ExportColumn.fs =>
              intermediate[i] ? empty : fmt(measurements[i].fs),
            ExportColumn.hi => fmt(measurements[i].ih),
            ExportColumn.rise =>
              riseFall[i] != null && riseFall[i]! >= 0
                  ? riseFall[i]!.toStringAsFixed(3)
                  : empty,
            ExportColumn.fall =>
              riseFall[i] != null && riseFall[i]! < 0
                  ? (-riseFall[i]!).toStringAsFixed(3)
                  : empty,
            ExportColumn.rl => fmt(measurements[i].gh),
            ExportColumn.remarks =>
              measurements[i].type == MeasurementType.tp ? 'TP' : '',
            ExportColumn.design => fmt(measurements[i].designLevel),
            ExportColumn.cutFill => cutFill(measurements[i]),
          },
      ],
  ];
}

/// '100.000 m' / '100.000 ft'.
String exportLength(double value, LengthUnit unit) =>
    '${value.toStringAsFixed(3)} ${unit.symbol}';
