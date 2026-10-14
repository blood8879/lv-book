import 'dart:math' as math;

import '../../fieldbook/domain/misclosure.dart';

/// Arc-seconds per radian (180 / π × 3600).
const double arcSecondsPerRadian = 180 / math.pi * 3600;

/// Two-peg test (collimation check) of a level.
///
/// Setup 1: instrument midway between pegs A and B, so equal sight lengths
/// cancel the collimation error and `a1 − b1` is the true height difference.
/// Setup 2: instrument close to peg A; the near A reading is taken as
/// error-free, so the B reading should be `a2 − Δ`. Whatever B reads beyond
/// that is the collimation error over the peg distance [pegDistance].
///
/// Readings and [pegDistance] are in the app unit (m or ft, never
/// converted); [toleranceEntry] is in the tolerance entry unit (mm for
/// metres, ft for feet), like [MisclosureTolerance].
class TwoPegTest {
  /// Default allowance over the peg distance: 3 mm / 0.01 ft.
  static const double defaultToleranceMm = 3.0;
  static const double defaultToleranceFt = 0.01;

  final double a1;
  final double b1;
  final double a2;
  final double b2;
  final double pegDistance;
  final LengthUnit unit;
  final double toleranceEntry;

  const TwoPegTest({
    required this.a1,
    required this.b1,
    required this.a2,
    required this.b2,
    required this.pegDistance,
    required this.unit,
    required this.toleranceEntry,
  });

  /// Parses the raw field texts; null until every reading is a number and
  /// the peg distance is > 0.
  static TwoPegTest? tryParse({
    required String a1,
    required String b1,
    required String a2,
    required String b2,
    required String pegDistance,
    required LengthUnit unit,
    required double toleranceEntry,
  }) {
    final values = [a1, b1, a2, b2, pegDistance].map(parseNumber).toList();
    if (values.any((value) => value == null)) return null;
    if (values[4]! <= 0) return null;
    return TwoPegTest(
      a1: values[0]!,
      b1: values[1]!,
      a2: values[2]!,
      b2: values[3]!,
      pegDistance: values[4]!,
      unit: unit,
      toleranceEntry: toleranceEntry,
    );
  }

  /// Finite number from user input ("1.525"; a decimal comma is accepted).
  static double? parseNumber(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    return value != null && value.isFinite ? value : null;
  }

  static double defaultTolerance(LengthUnit unit) =>
      unit == LengthUnit.metres ? defaultToleranceMm : defaultToleranceFt;

  /// True height difference Δ = a1 − b1 (positive: B is lower than A).
  double get trueDifference => a1 - b1;

  /// Reading B should show from setup 2 with a level line of sight; the
  /// reticle is set to this value when adjusting the instrument.
  double get expectedB2 => a2 - trueDifference;

  /// Collimation error over [pegDistance] in the reading unit (m or ft).
  /// Positive: line of sight inclined upward.
  double get error => b2 - expectedB2;

  /// Error per 100 m (or per 100 ft), in the reading unit.
  double get errorPer100 => error / pegDistance * 100;

  /// Inclination of the line of sight in arc-seconds (signed like [error]).
  double get arcSeconds => math.atan(error / pegDistance) * arcSecondsPerRadian;

  /// Allowed |error| in the reading unit (m or ft).
  double get allowed =>
      unit == LengthUnit.metres ? toleranceEntry / 1000 : toleranceEntry;

  bool get withinTolerance => error.abs() <= allowed + toleranceEpsilon;
}
