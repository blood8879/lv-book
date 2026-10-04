import 'dart:math' as math;

import 'measurement.dart';

/// Floating-point slack used by every tolerance comparison (same as
/// `ExportJudgement.isSuitable`), so a misclosure of exactly the allowed value
/// is judged within tolerance.
const double toleranceEpsilon = 1e-9;

/// The arithmetic check (ΣBS − ΣFS = Final RL − Start RL) only proves the
/// book was reduced consistently; readings are entered to 1 mm, so anything
/// beyond 1 mm means a hand-edited or imported RL does not match its readings.
const double arithmeticCheckTolerance = 0.001;

/// What the run closes on. The persisted value is [name].
///
/// - [none]: no known closing RL; only the arithmetic check is available.
/// - [loop]: the run returns to the start BM; closing RL = Start RL (follows
///   later edits of Start RL).
/// - [benchmark]: another project BM; its elevation is snapshotted into
///   `FieldBook.closingElevation` when selected (like `startElevation`), so a
///   later BM edit or deletion never silently changes an old book.
/// - [manual]: a known RL typed by the user.
enum ClosingReferenceMode {
  none,
  loop,
  benchmark,
  manual;

  static ClosingReferenceMode parse(Object? value) =>
      ClosingReferenceMode.values
          .where((mode) => mode.name == value)
          .firstOrNull ??
      ClosingReferenceMode.none;
}

/// How the allowed misclosure is computed. Persisted as [name].
enum MisclosureToleranceMode {
  /// A fixed allowance in mm.
  fixed,

  /// c·√n mm, n = number of instrument setups.
  sqrtSetups;

  static MisclosureToleranceMode parse(Object? value) =>
      MisclosureToleranceMode.values
          .where((mode) => mode.name == value)
          .firstOrNull ??
      MisclosureToleranceMode.fixed;
}

/// App-level misclosure tolerance rule.
class MisclosureTolerance {
  /// 1 mm keeps the behaviour of versions before the closing reference.
  static const double defaultFixedMm = 1.0;
  static const double defaultCoefficientMm = 5.0;
  static const double minMm = 0.1;
  static const double maxMm = 100.0;

  static const defaults = MisclosureTolerance();

  final MisclosureToleranceMode mode;
  final double fixedMm;
  final double coefficientMm;

  const MisclosureTolerance({
    this.mode = MisclosureToleranceMode.fixed,
    this.fixedMm = defaultFixedMm,
    this.coefficientMm = defaultCoefficientMm,
  });

  const MisclosureTolerance.fixed(double mm)
    : mode = MisclosureToleranceMode.fixed,
      fixedMm = mm,
      coefficientMm = defaultCoefficientMm;

  const MisclosureTolerance.sqrtSetups(double coefficient)
    : mode = MisclosureToleranceMode.sqrtSetups,
      fixedMm = defaultFixedMm,
      coefficientMm = coefficient;

  /// Valid mm value for either mode: finite and within [minMm]..[maxMm].
  static bool isValidMm(double? value) =>
      value != null && value.isFinite && value >= minMm && value <= maxMm;

  /// Parses user input ("5", "2.5"; a decimal comma is accepted). Returns
  /// null when it is not a valid mm value.
  static double? parseMm(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    return isValidMm(value) ? value : null;
  }

  /// Allowed |misclosure| in metres for a run with [setups] instrument
  /// setups (at least one setup is assumed).
  double allowedMeters(int setups) {
    switch (mode) {
      case MisclosureToleranceMode.fixed:
        return fixedMm / 1000;
      case MisclosureToleranceMode.sqrtSetups:
        return coefficientMm * math.sqrt(math.max(setups, 1)) / 1000;
    }
  }

  bool isWithin(double misclosure, {required int setups}) =>
      misclosure.abs() <= allowedMeters(setups) + toleranceEpsilon;

  @override
  bool operator ==(Object other) =>
      other is MisclosureTolerance &&
      other.mode == mode &&
      other.fixedMm == fixedMm &&
      other.coefficientMm == coefficientMm;

  @override
  int get hashCode => Object.hash(mode, fixedMm, coefficientMm);
}

/// Closure check of one leveling run: the always-on arithmetic check and,
/// when a closing RL is known, the real misclosure (Final RL − closing RL)
/// judged against the [MisclosureTolerance].
class LevelClosureCheck {
  final LevelCheckSums sums;

  /// ΣBS − ΣFS − (Final RL − Start RL); ~0 for a book reduced by the app.
  final double arithmeticError;

  /// Instrument setups: observed rows that establish an HI (rows with a BS).
  final int setups;

  /// Known RL the run should close on; null when no closing reference.
  final double? closingElevation;

  /// Allowed |misclosure| in metres.
  final double allowed;

  const LevelClosureCheck({
    required this.sums,
    required this.arithmeticError,
    required this.setups,
    required this.closingElevation,
    required this.allowed,
  });

  factory LevelClosureCheck.compute(
    List<Measurement> measurements, {
    required double startElevation,
    double? closingElevation,
    MisclosureTolerance tolerance = MisclosureTolerance.defaults,
  }) {
    final setups = countSetups(measurements);
    return LevelClosureCheck(
      sums: LevelCheckSums.from(measurements, startElevation: startElevation),
      arithmeticError: LevelClosure.error(
        measurements,
        startElevation: startElevation,
      ),
      setups: setups,
      closingElevation: closingElevation,
      allowed: tolerance.allowedMeters(setups),
    );
  }

  /// Rows that establish an HI: every observed row with a BS (the first
  /// setup on the start BM and each turning point).
  static int countSetups(List<Measurement> measurements) =>
      measurements.where((m) => m.bs != null).length;

  bool get hasClosing => closingElevation != null;

  double get finalRl => sums.lastGh;

  /// Final RL − closing RL; null when no closing RL is known.
  double? get misclosure =>
      closingElevation == null ? null : finalRl - closingElevation!;

  bool get arithmeticOk =>
      arithmeticError.abs() <= arithmeticCheckTolerance + toleranceEpsilon;

  /// Null when no closing RL is known (nothing to judge).
  bool? get withinTolerance {
    final value = misclosure;
    if (value == null) return null;
    return value.abs() <= allowed + toleranceEpsilon;
  }

  /// Overall judgement: arithmetic check balances and, when known, the
  /// misclosure is within the allowed value.
  bool get isSuitable => arithmeticOk && (withinTolerance ?? true);
}

/// Misclosure text: 4 decimals with an explicit sign ('+0.0010', '-0.0020',
/// '0.0000'). Never locale-formatted.
String formatMisclosure(double value) {
  final fixed = value.toStringAsFixed(4);
  if (double.parse(fixed) == 0) return 0.toStringAsFixed(4);
  return value > 0 ? '+$fixed' : fixed;
}

/// Allowed misclosure text: '±0.0050'.
String formatAllowedMisclosure(double meters) =>
    '±${meters.toStringAsFixed(4)}';
