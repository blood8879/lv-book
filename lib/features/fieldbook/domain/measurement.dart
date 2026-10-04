enum MeasurementType { normal, tp }

/// Closure (misclosure) helpers for a leveling run.
class LevelClosure {
  /// Misclosure: ΣBS − ΣFS(carry) − (lastGH − firstGH).
  ///
  /// Only foresights that advance the running elevation are summed. An
  /// intermediate point (중간점) has an FS but no BS and is not the final
  /// observed station, so its foresight does not move the instrument; counting
  /// it would inflate the misclosure artificially. Rows with no observed value
  /// are ignored so trailing empty rows do not affect the final station.
  static double error(
    List<Measurement> measurements, {
    required double startElevation,
  }) {
    final rows = measurements
        .where((m) => m.bs != null || m.fs != null || m.gh != null)
        .toList();
    if (rows.isEmpty) return 0;

    double sumBs = 0;
    double carryFs = 0;
    double? firstGh;
    double? lastGh;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.bs != null) sumBs += row.bs!;
      final carriesForward = row.bs != null || i == rows.length - 1;
      if (row.fs != null && carriesForward) carryFs += row.fs!;
      if (row.gh != null) {
        firstGh ??= row.gh;
        lastGh = row.gh;
      }
    }

    final start = firstGh ?? startElevation;
    final end = lastGh ?? start;
    return sumBs - carryFs - (end - start);
  }
}

class Measurement {
  final int? id;
  final int fieldBookId;
  final int orderIndex;
  final String stationName;
  final MeasurementType type;
  final double? bs;
  final double? fs;
  final double? ih;
  final double? gh;
  final bool manualTp;

  Measurement({
    this.id,
    required this.fieldBookId,
    required this.orderIndex,
    required this.stationName,
    this.type = MeasurementType.normal,
    this.bs,
    this.fs,
    this.ih,
    this.gh,
    this.manualTp = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'field_book_id': fieldBookId,
      'order_index': orderIndex,
      'station_name': stationName,
      'type': type.name,
      'bs': bs,
      'fs': fs,
      'ih': ih,
      'gh': gh,
      'manual_tp': manualTp ? 1 : 0,
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'] as int?,
      fieldBookId: map['field_book_id'] as int,
      orderIndex: map['order_index'] as int,
      stationName: map['station_name'] as String,
      type: MeasurementType.values.byName(map['type'] as String),
      bs: (map['bs'] as num?)?.toDouble(),
      fs: (map['fs'] as num?)?.toDouble(),
      ih: (map['ih'] as num?)?.toDouble(),
      gh: (map['gh'] as num?)?.toDouble(),
      manualTp: (map['manual_tp'] as int? ?? 0) == 1,
    );
  }

  Measurement copyWith({
    int? id,
    int? fieldBookId,
    int? orderIndex,
    String? stationName,
    MeasurementType? type,
    double? bs,
    double? fs,
    double? ih,
    double? gh,
    bool? manualTp,
  }) {
    return Measurement(
      id: id ?? this.id,
      fieldBookId: fieldBookId ?? this.fieldBookId,
      orderIndex: orderIndex ?? this.orderIndex,
      stationName: stationName ?? this.stationName,
      type: type ?? this.type,
      bs: bs ?? this.bs,
      fs: fs ?? this.fs,
      ih: ih ?? this.ih,
      gh: gh ?? this.gh,
      manualTp: manualTp ?? this.manualTp,
    );
  }
}

/// Sums used for the 검산 (ΣBS − ΣFS) block of CSV/PDF exports.
///
/// Mirrors [LevelClosure.error]: rows without any observed value are ignored,
/// and an FS is counted only when it carries the elevation forward, i.e. on a
/// turning point (row with BS) or on the final observed row. Intermediate
/// sights (중간점) are excluded, so [difference] equals
/// [lastGh] − [firstGh] for an error-free run and
/// `difference − (lastGh − firstGh)` equals [LevelClosure.error].
class LevelCheckSums {
  final double sumBs;
  final double sumFs;
  final double firstGh;
  final double lastGh;

  const LevelCheckSums({
    required this.sumBs,
    required this.sumFs,
    required this.firstGh,
    required this.lastGh,
  });

  factory LevelCheckSums.from(
    List<Measurement> measurements, {
    required double startElevation,
  }) {
    final rows = measurements
        .where((m) => m.bs != null || m.fs != null || m.gh != null)
        .toList();
    double sumBs = 0;
    double sumFs = 0;
    double? firstGh;
    double? lastGh;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.bs != null) sumBs += row.bs!;
      final carriesForward = row.bs != null || i == rows.length - 1;
      if (row.fs != null && carriesForward) sumFs += row.fs!;
      if (row.gh != null) {
        firstGh ??= row.gh;
        lastGh = row.gh;
      }
    }
    final start = firstGh ?? startElevation;
    return LevelCheckSums(
      sumBs: sumBs,
      sumFs: sumFs,
      firstGh: start,
      lastGh: lastGh ?? start,
    );
  }

  double get difference => sumBs - sumFs;

  double get error => difference - (lastGh - firstGh);
}
