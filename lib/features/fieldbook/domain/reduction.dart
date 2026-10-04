import '../../../core/utils/calculation.dart';
import 'measurement.dart';

/// How a level book is presented and checked. Reduced levels are identical
/// for both; only the table columns and one extra check differ. The
/// persisted value is [name]; rows/backups/CSV files written before this
/// existed parse as [heightOfInstrument].
enum ReductionMethod {
  /// Height of instrument (기고식): HI column (default, original behaviour).
  heightOfInstrument,

  /// Rise and fall (승강식): Rise/Fall per reading and the extra check
  /// ΣRise − ΣFall = ΣBS − ΣFS = Final RL − Start RL.
  riseAndFall;

  static ReductionMethod parse(Object? value) =>
      ReductionMethod.values
          .where((method) => method.name == value)
          .firstOrNull ??
      ReductionMethod.heightOfInstrument;
}

/// Rise (+) / fall (−) per measurement (see [LevelRun.riseFall]).
List<double?> riseFallOf(List<Measurement> measurements) => LevelRun.riseFall([
  for (final m in measurements) LevelRunInput(bs: m.bs, fs: m.fs),
]);

/// ΣRise and ΣFall (both ≥ 0) of a run.
class RiseFallSums {
  final double sumRise;
  final double sumFall;

  const RiseFallSums({required this.sumRise, required this.sumFall});

  factory RiseFallSums.from(List<Measurement> measurements) {
    double rise = 0;
    double fall = 0;
    for (final value in riseFallOf(measurements)) {
      if (value == null) continue;
      if (value >= 0) {
        rise += value;
      } else {
        fall -= value;
      }
    }
    return RiseFallSums(sumRise: rise, sumFall: fall);
  }

  /// ΣRise − ΣFall.
  double get difference => sumRise - sumFall;
}

/// Rows printed under IS (intermediate sight) in the standard
/// BS | IS | FS layout: an FS-only row that is not a turning point and not
/// the last observed row. Matches the rows [LevelCheckSums] leaves out of
/// ΣFS, so the FS column sums to ΣFS.
List<bool> intermediateSightFlags(List<Measurement> measurements) {
  var lastObserved = -1;
  for (var i = 0; i < measurements.length; i++) {
    final m = measurements[i];
    if (m.bs != null || m.fs != null || m.gh != null) lastObserved = i;
  }
  return [
    for (var i = 0; i < measurements.length; i++)
      measurements[i].bs == null &&
          measurements[i].fs != null &&
          i != lastObserved &&
          measurements[i].type != MeasurementType.tp &&
          !measurements[i].manualTp,
  ];
}

/// Signed rise/fall text: '+0.552', '−0.328' (U+2212), '0.000'.
String formatRiseFall(double value) {
  final fixed = value.abs().toStringAsFixed(3);
  if (double.parse(fixed) == 0) return 0.toStringAsFixed(3);
  return value > 0 ? '+$fixed' : '−$fixed';
}
