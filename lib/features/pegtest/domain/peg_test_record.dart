import '../../fieldbook/domain/misclosure.dart';
import 'two_peg_test.dart';

/// A saved two-peg test (documented instrument check), row of `peg_tests`.
///
/// Standalone: not linked to a project. Readings, [pegDistance] and the
/// [toleranceEntry] keep the unit they were recorded in ([unit]), so a later
/// unit switch never changes an old record.
class PegTestRecord {
  final int? id;
  final DateTime createdAt;
  final String? instrument;
  final String? observer;
  final LengthUnit unit;
  final double a1;
  final double b1;
  final double a2;
  final double b2;
  final double pegDistance;
  final double toleranceEntry;
  final String? note;

  PegTestRecord({
    this.id,
    DateTime? createdAt,
    String? instrument,
    String? observer,
    required this.unit,
    required this.a1,
    required this.b1,
    required this.a2,
    required this.b2,
    required this.pegDistance,
    required this.toleranceEntry,
    String? note,
  }) : createdAt = createdAt ?? DateTime.now(),
       instrument = blankToNull(instrument),
       observer = blankToNull(observer),
       note = blankToNull(note);

  factory PegTestRecord.fromTest(
    TwoPegTest test, {
    int? id,
    DateTime? createdAt,
    String? instrument,
    String? observer,
    String? note,
  }) {
    return PegTestRecord(
      id: id,
      createdAt: createdAt,
      instrument: instrument,
      observer: observer,
      unit: test.unit,
      a1: test.a1,
      b1: test.b1,
      a2: test.a2,
      b2: test.b2,
      pegDistance: test.pegDistance,
      toleranceEntry: test.toleranceEntry,
      note: note,
    );
  }

  /// The computation for this record (results and verdict).
  TwoPegTest get test => TwoPegTest(
    a1: a1,
    b1: b1,
    a2: a2,
    b2: b2,
    pegDistance: pegDistance,
    unit: unit,
    toleranceEntry: toleranceEntry,
  );

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'created_at': createdAt.toIso8601String(),
      'instrument': instrument,
      'observer': observer,
      'unit': unit.name,
      'a1': a1,
      'b1': b1,
      'a2': a2,
      'b2': b2,
      'peg_distance': pegDistance,
      'tolerance_entry': toleranceEntry,
      'note': note,
    };
  }

  /// Throws [FormatException] for a missing or invalid value (a corrupt
  /// backup); the peg distance must be > 0 like [TwoPegTest.tryParse].
  factory PegTestRecord.fromMap(Map<String, dynamic> map) {
    double number(String key) {
      final value = map[key];
      if (value is num && value.isFinite) return value.toDouble();
      throw FormatException('peg test: invalid $key', value);
    }

    String? text(String key) {
      final value = map[key];
      if (value == null || value is String) return value as String?;
      throw FormatException('peg test: invalid $key', value);
    }

    final createdAt = DateTime.tryParse(map['created_at'] as String? ?? '');
    if (createdAt == null) {
      throw FormatException('peg test: invalid created_at', map['created_at']);
    }
    final unit = LengthUnit.values
        .where((unit) => unit.name == map['unit'])
        .firstOrNull;
    if (unit == null) {
      throw FormatException('peg test: invalid unit', map['unit']);
    }
    final pegDistance = number('peg_distance');
    if (pegDistance <= 0) {
      throw FormatException('peg test: invalid peg_distance', pegDistance);
    }
    final id = map['id'];
    return PegTestRecord(
      id: id is int ? id : null,
      createdAt: createdAt,
      instrument: text('instrument'),
      observer: text('observer'),
      unit: unit,
      a1: number('a1'),
      b1: number('b1'),
      a2: number('a2'),
      b2: number('b2'),
      pegDistance: pegDistance,
      toleranceEntry: number('tolerance_entry'),
      note: text('note'),
    );
  }

  /// Same test (time, unit, readings, distance, tolerance and texts),
  /// ignoring [id]. Restoring a backup skips records that are already there.
  bool sameContentAs(PegTestRecord other) =>
      createdAt == other.createdAt &&
      unit == other.unit &&
      a1 == other.a1 &&
      b1 == other.b1 &&
      a2 == other.a2 &&
      b2 == other.b2 &&
      pegDistance == other.pegDistance &&
      toleranceEntry == other.toleranceEntry &&
      instrument == other.instrument &&
      observer == other.observer &&
      note == other.note;

  static String? blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
