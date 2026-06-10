enum MeasurementType { normal, tp }

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
