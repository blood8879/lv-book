import 'fieldbook.dart';
import 'measurement.dart';

/// Whether a cut/fill value is a cut (ground above design), a fill (ground
/// below design) or on grade (0 at 3 decimals).
enum CutFillKind { cut, fill, onGrade }

/// Cut (+) / fill (−) of one row: RL − design level. Positive is a cut
/// (절토, ground above design), negative a fill (성토). Null unless the row
/// has both an RL and a design level. Unit-agnostic: RL and design level are
/// in the book's length unit (m or ft), and so is the result.
double? cutFillOf({required double? rl, required double? design}) {
  if (rl == null || design == null) return null;
  return rl - design;
}

/// [cutFillOf] for a stored measurement (RL = its GH).
double? measurementCutFill(Measurement m) =>
    cutFillOf(rl: m.gh, design: m.designLevel);

/// Cut / fill / on grade, judged at the printed precision (3 decimals like
/// RL), so '0.000' is never labelled as a cut or a fill.
CutFillKind cutFillKindOf(double value) {
  if (_roundsToZero(value)) return CutFillKind.onGrade;
  return value > 0 ? CutFillKind.cut : CutFillKind.fill;
}

bool _roundsToZero(double value) =>
    double.parse(value.abs().toStringAsFixed(3)) == 0;

/// Unsigned magnitude with 3 decimals (the RL format for m and ft).
String formatCutFillMagnitude(double value) => _roundsToZero(value)
    ? 0.toStringAsFixed(3)
    : value.abs().toStringAsFixed(3);

/// Lettered cut/fill text: 'C 0.125' / 'F 0.040' / '0.000' with the
/// localized letters ([cutLetter] e.g. 'C' / '절', [fillLetter] 'F' / '성').
String formatCutFill(
  double value, {
  required String cutLetter,
  required String fillLetter,
}) => switch (cutFillKindOf(value)) {
  CutFillKind.cut => '$cutLetter ${formatCutFillMagnitude(value)}',
  CutFillKind.fill => '$fillLetter ${formatCutFillMagnitude(value)}',
  CutFillKind.onGrade => formatCutFillMagnitude(value),
};

/// Signed machine-readable text for CSV: '0.125' (cut) / '-0.040' (fill),
/// '0.000' on grade (never '-0.000').
String formatCutFillSigned(double value) =>
    _roundsToZero(value) ? 0.toStringAsFixed(3) : value.toStringAsFixed(3);

/// Exports print the Design / Cut-Fill columns only when the book shows the
/// design column and at least one row has a design level; otherwise the
/// export layout is exactly as before the feature existed.
bool exportsDesignColumns(
  FieldBook fieldBook,
  List<Measurement> measurements,
) =>
    fieldBook.showDesignLevel && measurements.any((m) => m.designLevel != null);
