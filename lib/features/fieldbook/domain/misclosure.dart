import 'dart:math' as math;

import 'measurement.dart';
import 'reduction.dart';

/// Floating-point slack used by every tolerance comparison (same as
/// `ExportJudgement.isSuitable`), so a misclosure of exactly the allowed value
/// is judged within tolerance.
const double toleranceEpsilon = 1e-9;

/// The arithmetic check (ΣBS − ΣFS = Final RL − Start RL) only proves the
/// book was reduced consistently; readings are entered to 3 decimals (1 mm or
/// 0.001 ft), so anything beyond that means a hand-edited or imported RL does
/// not match its readings.
const double arithmeticCheckTolerance = 0.001;

/// App-level length unit. Readings are stored as entered; the unit only
/// changes labels ('m' / 'ft') and the unit the tolerance is entered in.
/// Changing it never converts stored numbers. Persisted as [name].
enum LengthUnit {
  metres,
  feet;

  /// Label printed next to readings and RLs.
  String get symbol => this == metres ? 'm' : 'ft';

  /// Unit the misclosure allowance is entered in: mm for metres, ft for feet.
  String get toleranceSymbol => this == metres ? 'mm' : 'ft';

  static LengthUnit parse(Object? value) =>
      LengthUnit.values.where((unit) => unit.name == value).firstOrNull ??
      LengthUnit.metres;
}

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
  /// A fixed allowance (mm for metres, ft for feet).
  fixed,

  /// c·√n (mm for metres, ft for feet), n = number of instrument setups.
  sqrtSetups;

  static MisclosureToleranceMode parse(Object? value) =>
      MisclosureToleranceMode.values
          .where((mode) => mode.name == value)
          .firstOrNull ??
      MisclosureToleranceMode.fixed;
}

/// App-level misclosure tolerance rule, together with the app [unit].
///
/// Metres: the allowance is entered in mm ([fixedMm] / [coefficientMm]).
/// Feet: it is entered in ft ([fixedFt] / [coefficientFt]). Both pairs are
/// kept so switching the unit back and forth never loses a setting.
class MisclosureTolerance {
  /// 1 mm keeps the behaviour of versions before the closing reference.
  static const double defaultFixedMm = 1.0;
  static const double defaultCoefficientMm = 5.0;
  static const double minMm = 0.1;
  static const double maxMm = 100.0;

  /// Feet defaults: 0.01 ft fixed, c = 0.02 ft (≈ 5 mm).
  static const double defaultFixedFt = 0.01;
  static const double defaultCoefficientFt = 0.02;
  static const double minFt = 0.0005;
  static const double maxFt = 0.3;

  static const defaults = MisclosureTolerance();

  final MisclosureToleranceMode mode;
  final double fixedMm;
  final double coefficientMm;
  final LengthUnit unit;
  final double fixedFt;
  final double coefficientFt;

  const MisclosureTolerance({
    this.mode = MisclosureToleranceMode.fixed,
    this.fixedMm = defaultFixedMm,
    this.coefficientMm = defaultCoefficientMm,
    this.unit = LengthUnit.metres,
    this.fixedFt = defaultFixedFt,
    this.coefficientFt = defaultCoefficientFt,
  });

  const MisclosureTolerance.fixed(double mm)
    : mode = MisclosureToleranceMode.fixed,
      fixedMm = mm,
      coefficientMm = defaultCoefficientMm,
      unit = LengthUnit.metres,
      fixedFt = defaultFixedFt,
      coefficientFt = defaultCoefficientFt;

  const MisclosureTolerance.sqrtSetups(double coefficient)
    : mode = MisclosureToleranceMode.sqrtSetups,
      fixedMm = defaultFixedMm,
      coefficientMm = coefficient,
      unit = LengthUnit.metres,
      fixedFt = defaultFixedFt,
      coefficientFt = defaultCoefficientFt;

  /// Valid mm value for either mode: finite and within [minMm]..[maxMm].
  static bool isValidMm(double? value) =>
      isValidEntry(value, LengthUnit.metres);

  /// Parses user input ("5", "2.5"; a decimal comma is accepted). Returns
  /// null when it is not a valid mm value.
  static double? parseMm(String text) => parseEntry(text, LengthUnit.metres);

  static double minEntry(LengthUnit unit) =>
      unit == LengthUnit.metres ? minMm : minFt;

  static double maxEntry(LengthUnit unit) =>
      unit == LengthUnit.metres ? maxMm : maxFt;

  /// Valid allowance in the entry unit of [unit] (mm or ft).
  static bool isValidEntry(double? value, LengthUnit unit) =>
      value != null &&
      value.isFinite &&
      value >= minEntry(unit) &&
      value <= maxEntry(unit);

  /// Parses an allowance typed in the entry unit of [unit] (mm or ft).
  static double? parseEntry(String text, LengthUnit unit) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    return isValidEntry(value, unit) ? value : null;
  }

  /// Fixed allowance in the entry unit (mm or ft) of [unit].
  double get fixedEntry => unit == LengthUnit.metres ? fixedMm : fixedFt;

  /// c in the entry unit (mm or ft) of [unit].
  double get coefficientEntry =>
      unit == LengthUnit.metres ? coefficientMm : coefficientFt;

  /// Allowed |misclosure| in the reading unit (m or ft) for a run with
  /// [setups] instrument setups (at least one setup is assumed).
  double allowed(int setups) {
    final value = switch (mode) {
      MisclosureToleranceMode.fixed => fixedEntry,
      MisclosureToleranceMode.sqrtSetups =>
        coefficientEntry * math.sqrt(math.max(setups, 1)),
    };
    return unit == LengthUnit.metres ? value / 1000 : value;
  }

  bool isWithin(double misclosure, {required int setups}) =>
      misclosure.abs() <= allowed(setups) + toleranceEpsilon;

  MisclosureTolerance copyWith({
    MisclosureToleranceMode? mode,
    double? fixedMm,
    double? coefficientMm,
    LengthUnit? unit,
    double? fixedFt,
    double? coefficientFt,
  }) => MisclosureTolerance(
    mode: mode ?? this.mode,
    fixedMm: fixedMm ?? this.fixedMm,
    coefficientMm: coefficientMm ?? this.coefficientMm,
    unit: unit ?? this.unit,
    fixedFt: fixedFt ?? this.fixedFt,
    coefficientFt: coefficientFt ?? this.coefficientFt,
  );

  /// Copy with the allowance of [mode] set to [value] in the entry unit of
  /// the current [unit].
  MisclosureTolerance withEntry(MisclosureToleranceMode mode, double value) {
    final metres = unit == LengthUnit.metres;
    final fixed = mode == MisclosureToleranceMode.fixed;
    return copyWith(
      mode: mode,
      fixedMm: metres && fixed ? value : null,
      coefficientMm: metres && !fixed ? value : null,
      fixedFt: !metres && fixed ? value : null,
      coefficientFt: !metres && !fixed ? value : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MisclosureTolerance &&
      other.mode == mode &&
      other.fixedMm == fixedMm &&
      other.coefficientMm == coefficientMm &&
      other.unit == unit &&
      other.fixedFt == fixedFt &&
      other.coefficientFt == coefficientFt;

  @override
  int get hashCode =>
      Object.hash(mode, fixedMm, coefficientMm, unit, fixedFt, coefficientFt);
}

/// Closure check of one leveling run: the always-on arithmetic check and,
/// when a closing RL is known, the real misclosure (Final RL − closing RL)
/// judged against the [MisclosureTolerance]. Rise-and-fall books add the
/// check ΣRise − ΣFall = Final RL − Start RL.
class LevelClosureCheck {
  final LevelCheckSums sums;

  /// ΣRise / ΣFall (computed for every book; judged for rise and fall).
  final RiseFallSums riseFall;

  /// Presentation of the book; [ReductionMethod.riseAndFall] makes
  /// [riseFallOk] part of [isSuitable].
  final ReductionMethod method;

  /// ΣBS − ΣFS − (Final RL − Start RL); ~0 for a book reduced by the app.
  final double arithmeticError;

  /// Instrument setups: observed rows that establish an HI (rows with a BS).
  final int setups;

  /// Known RL the run should close on; null when no closing reference.
  final double? closingElevation;

  /// Allowed |misclosure| in the reading unit (m or ft).
  final double allowed;

  const LevelClosureCheck({
    required this.sums,
    this.riseFall = const RiseFallSums(sumRise: 0, sumFall: 0),
    this.method = ReductionMethod.heightOfInstrument,
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
    ReductionMethod method = ReductionMethod.heightOfInstrument,
  }) {
    final setups = countSetups(measurements);
    return LevelClosureCheck(
      sums: LevelCheckSums.from(measurements, startElevation: startElevation),
      riseFall: RiseFallSums.from(measurements),
      method: method,
      arithmeticError: LevelClosure.error(
        measurements,
        startElevation: startElevation,
      ),
      setups: setups,
      closingElevation: closingElevation,
      allowed: tolerance.allowed(setups),
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

  /// (ΣRise − ΣFall) − (Final RL − Start RL); ~0 for a consistent book.
  double get riseFallError =>
      riseFall.difference - (sums.lastGh - sums.firstGh);

  /// Rise-and-fall check: ΣRise − ΣFall = ΣBS − ΣFS = Final RL − Start RL.
  bool get riseFallOk =>
      riseFallError.abs() <= arithmeticCheckTolerance + toleranceEpsilon &&
      (riseFall.difference - sums.difference).abs() <=
          arithmeticCheckTolerance + toleranceEpsilon;

  /// Null when no closing RL is known (nothing to judge).
  bool? get withinTolerance {
    final value = misclosure;
    if (value == null) return null;
    return value.abs() <= allowed + toleranceEpsilon;
  }

  /// Overall judgement: arithmetic check balances (and, for rise and fall,
  /// the rise/fall check) and, when known, the misclosure is within the
  /// allowed value.
  bool get isSuitable =>
      arithmeticOk &&
      (method != ReductionMethod.riseAndFall || riseFallOk) &&
      (withinTolerance ?? true);
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
