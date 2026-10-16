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

  /// Unit of a level book's route length (L in K·√L): km for metres, mi
  /// (statute miles) for feet.
  String get routeSymbol => this == metres ? 'km' : 'mi';

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
  sqrtSetups,

  /// K·√L: K in mm and L in km (metres), or K in ft and L in miles (feet);
  /// L is the book's route length ([FieldBook.routeLength]). Without a route
  /// length the allowance is unavailable, never guessed.
  sqrtDistance;

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

  /// K·√L defaults and presets: survey-order K values in mm·√km (metres)
  /// and typical US values in ft·√mi (feet).
  static const double defaultDistanceKMm = 10.0;
  static const double defaultDistanceKFt = 0.035;
  static const distancePresetsMm = [2.5, 5.0, 10.0, 15.0, 20.0];
  static const distancePresetsFt = [0.017, 0.035, 0.05];

  static List<double> distancePresets(LengthUnit unit) =>
      unit == LengthUnit.metres ? distancePresetsMm : distancePresetsFt;

  static const defaults = MisclosureTolerance();

  final MisclosureToleranceMode mode;
  final double fixedMm;
  final double coefficientMm;
  final LengthUnit unit;
  final double fixedFt;
  final double coefficientFt;

  /// K of [MisclosureToleranceMode.sqrtDistance] (mm·√km / ft·√mi); kept
  /// apart from the c of c·√n so switching modes never loses either.
  final double distanceKMm;
  final double distanceKFt;

  const MisclosureTolerance({
    this.mode = MisclosureToleranceMode.fixed,
    this.fixedMm = defaultFixedMm,
    this.coefficientMm = defaultCoefficientMm,
    this.unit = LengthUnit.metres,
    this.fixedFt = defaultFixedFt,
    this.coefficientFt = defaultCoefficientFt,
    this.distanceKMm = defaultDistanceKMm,
    this.distanceKFt = defaultDistanceKFt,
  });

  const MisclosureTolerance.fixed(double mm)
    : mode = MisclosureToleranceMode.fixed,
      fixedMm = mm,
      coefficientMm = defaultCoefficientMm,
      unit = LengthUnit.metres,
      fixedFt = defaultFixedFt,
      coefficientFt = defaultCoefficientFt,
      distanceKMm = defaultDistanceKMm,
      distanceKFt = defaultDistanceKFt;

  const MisclosureTolerance.sqrtSetups(double coefficient)
    : mode = MisclosureToleranceMode.sqrtSetups,
      fixedMm = defaultFixedMm,
      coefficientMm = coefficient,
      unit = LengthUnit.metres,
      fixedFt = defaultFixedFt,
      coefficientFt = defaultCoefficientFt,
      distanceKMm = defaultDistanceKMm,
      distanceKFt = defaultDistanceKFt;

  /// K·√L in metres mode, K in mm·√km.
  const MisclosureTolerance.sqrtDistance(double kMm)
    : mode = MisclosureToleranceMode.sqrtDistance,
      fixedMm = defaultFixedMm,
      coefficientMm = defaultCoefficientMm,
      unit = LengthUnit.metres,
      fixedFt = defaultFixedFt,
      coefficientFt = defaultCoefficientFt,
      distanceKMm = kMm,
      distanceKFt = defaultDistanceKFt;

  /// Valid route length (km or mi): finite and > 0.
  static bool isValidRouteLength(double? value) =>
      value != null && value.isFinite && value > 0;

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

  /// K of K·√L in the entry unit (mm or ft) of [unit].
  double get distanceKEntry =>
      unit == LengthUnit.metres ? distanceKMm : distanceKFt;

  /// Coefficient of [mode] in the entry unit: the fixed allowance, c or K.
  double entryFor(MisclosureToleranceMode mode) => switch (mode) {
    MisclosureToleranceMode.fixed => fixedEntry,
    MisclosureToleranceMode.sqrtSetups => coefficientEntry,
    MisclosureToleranceMode.sqrtDistance => distanceKEntry,
  };

  /// Whether the allowance needs the book's route length.
  bool get needsRouteLength => mode == MisclosureToleranceMode.sqrtDistance;

  /// Allowed |misclosure| in the entry unit (mm or ft); null when K·√L has
  /// no valid [routeLength] (km or mi).
  double? allowedEntry(int setups, {double? routeLength}) => switch (mode) {
    MisclosureToleranceMode.fixed => fixedEntry,
    MisclosureToleranceMode.sqrtSetups =>
      coefficientEntry * math.sqrt(math.max(setups, 1)),
    MisclosureToleranceMode.sqrtDistance =>
      isValidRouteLength(routeLength)
          ? distanceKEntry * math.sqrt(routeLength!)
          : null,
  };

  /// Allowed |misclosure| in the reading unit (m or ft) for a run with
  /// [setups] instrument setups (at least one setup is assumed) and, for
  /// K·√L, the route length; null when it cannot be computed.
  double? allowed(int setups, {double? routeLength}) {
    final value = allowedEntry(setups, routeLength: routeLength);
    if (value == null) return null;
    return unit == LengthUnit.metres ? value / 1000 : value;
  }

  /// False also when the allowance is unavailable.
  bool isWithin(double misclosure, {required int setups, double? routeLength}) {
    final limit = allowed(setups, routeLength: routeLength);
    return limit != null && misclosure.abs() <= limit + toleranceEpsilon;
  }

  /// The allowance with its numbers, e.g. '±10 mm·√2.40 km = ±15.5 mm',
  /// '±5 mm·√4 = ±10.0 mm', '±0.035 ft·√1.50 mi = ±0.043 ft'; null for a
  /// fixed allowance (the value says it all) or without a route length.
  /// Symbols only, so the text is the same in every language.
  String? formula(int setups, {double? routeLength}) {
    final value = allowedEntry(setups, routeLength: routeLength);
    if (value == null) return null;
    final symbol = unit.toleranceSymbol;
    final result = unit == LengthUnit.metres
        ? value.toStringAsFixed(1)
        : value.toStringAsFixed(3);
    return switch (mode) {
      MisclosureToleranceMode.fixed => null,
      MisclosureToleranceMode.sqrtSetups =>
        '±${_trim(coefficientEntry)} $symbol·√${math.max(setups, 1)} = '
            '±$result $symbol',
      MisclosureToleranceMode.sqrtDistance =>
        '±${_trim(distanceKEntry)} $symbol·√'
            '${routeLength!.toStringAsFixed(2)} ${unit.routeSymbol} = '
            '±$result $symbol',
    };
  }

  /// 10.0 → '10', 2.5 → '2.5', 0.035 → '0.035'.
  static String _trim(double value) =>
      value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');

  MisclosureTolerance copyWith({
    MisclosureToleranceMode? mode,
    double? fixedMm,
    double? coefficientMm,
    LengthUnit? unit,
    double? fixedFt,
    double? coefficientFt,
    double? distanceKMm,
    double? distanceKFt,
  }) => MisclosureTolerance(
    mode: mode ?? this.mode,
    fixedMm: fixedMm ?? this.fixedMm,
    coefficientMm: coefficientMm ?? this.coefficientMm,
    unit: unit ?? this.unit,
    fixedFt: fixedFt ?? this.fixedFt,
    coefficientFt: coefficientFt ?? this.coefficientFt,
    distanceKMm: distanceKMm ?? this.distanceKMm,
    distanceKFt: distanceKFt ?? this.distanceKFt,
  );

  /// Copy with the allowance of [mode] set to [value] in the entry unit of
  /// the current [unit].
  MisclosureTolerance withEntry(MisclosureToleranceMode mode, double value) {
    final metres = unit == LengthUnit.metres;
    final fixed = mode == MisclosureToleranceMode.fixed;
    final setups = mode == MisclosureToleranceMode.sqrtSetups;
    final distance = mode == MisclosureToleranceMode.sqrtDistance;
    return copyWith(
      mode: mode,
      fixedMm: metres && fixed ? value : null,
      coefficientMm: metres && setups ? value : null,
      fixedFt: !metres && fixed ? value : null,
      coefficientFt: !metres && setups ? value : null,
      distanceKMm: metres && distance ? value : null,
      distanceKFt: !metres && distance ? value : null,
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
      other.coefficientFt == coefficientFt &&
      other.distanceKMm == distanceKMm &&
      other.distanceKFt == distanceKFt;

  @override
  int get hashCode => Object.hash(
    mode,
    fixedMm,
    coefficientMm,
    unit,
    fixedFt,
    coefficientFt,
    distanceKMm,
    distanceKFt,
  );
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

  /// Allowed |misclosure| in the reading unit (m or ft); null when the
  /// rule is K·√L and the book has no route length ([toleranceUnavailable]).
  final double? allowed;

  /// The allowance with its numbers ([MisclosureTolerance.formula]); null
  /// for a fixed allowance or when unavailable.
  final String? allowedFormula;

  const LevelClosureCheck({
    required this.sums,
    this.riseFall = const RiseFallSums(sumRise: 0, sumFall: 0),
    this.method = ReductionMethod.heightOfInstrument,
    required this.arithmeticError,
    required this.setups,
    required this.closingElevation,
    required this.allowed,
    this.allowedFormula,
  });

  factory LevelClosureCheck.compute(
    List<Measurement> measurements, {
    required double startElevation,
    double? closingElevation,
    MisclosureTolerance tolerance = MisclosureTolerance.defaults,
    ReductionMethod method = ReductionMethod.heightOfInstrument,
    double? routeLength,
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
      allowed: tolerance.allowed(setups, routeLength: routeLength),
      allowedFormula: tolerance.formula(setups, routeLength: routeLength),
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

  /// A closing RL is known but the allowance cannot be computed (K·√L
  /// without a route length): the misclosure cannot be judged.
  bool get toleranceUnavailable => hasClosing && allowed == null;

  /// Null when no closing RL is known or the allowance is unavailable
  /// (nothing to judge; see [toleranceUnavailable]).
  bool? get withinTolerance {
    final value = misclosure;
    final limit = allowed;
    if (value == null || limit == null) return null;
    return value.abs() <= limit + toleranceEpsilon;
  }

  /// Overall judgement: arithmetic check balances (and, for rise and fall,
  /// the rise/fall check) and, when known, the misclosure is within the
  /// allowed value. An unavailable allowance is never judged suitable.
  bool get isSuitable =>
      arithmeticOk &&
      (method != ReductionMethod.riseAndFall || riseFallOk) &&
      !toleranceUnavailable &&
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
