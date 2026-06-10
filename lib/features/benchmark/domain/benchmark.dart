enum BenchMarkStatus { available, damagedSuspected, stopped }

enum BenchMarkKind { bm, tbm }

extension BenchMarkKindLabel on BenchMarkKind {
  String get label {
    switch (this) {
      case BenchMarkKind.bm:
        return 'BM';
      case BenchMarkKind.tbm:
        return 'TBM';
    }
  }
}

extension BenchMarkStatusLabel on BenchMarkStatus {
  String get label {
    switch (this) {
      case BenchMarkStatus.available:
        return '사용 가능';
      case BenchMarkStatus.damagedSuspected:
        return '훼손 의심';
      case BenchMarkStatus.stopped:
        return '사용 중지';
    }
  }
}

class BenchMark {
  final int? id;
  final int projectId;
  final String name;
  final double elevation;
  final String? description;
  final String? locationHint;
  final String? protectionNote;
  final DateTime? lastVerifiedAt;
  final BenchMarkStatus status;
  final BenchMarkKind kind;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final double? coordinateAccuracyM;
  final DateTime? coordinateCapturedAt;

  BenchMark({
    this.id,
    required this.projectId,
    required this.name,
    required this.elevation,
    this.description,
    this.locationHint,
    this.protectionNote,
    this.lastVerifiedAt,
    this.status = BenchMarkStatus.available,
    this.kind = BenchMarkKind.bm,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.coordinateAccuracyM,
    this.coordinateCapturedAt,
  });

  bool get isSelectableForFieldBook => status != BenchMarkStatus.stopped;
  bool get hasPhoto => photoPath != null && photoPath!.trim().isNotEmpty;
  bool get hasCoordinate => latitude != null && longitude != null;

  String? get formattedCoordinate {
    final lat = latitude;
    final lon = longitude;
    if (lat == null || lon == null) return null;
    return '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
  }

  String? get copyCoordinateText {
    final lat = latitude;
    final lon = longitude;
    if (lat == null || lon == null) return null;
    return '위도 ${lat.toStringAsFixed(6)}, 경도 ${lon.toStringAsFixed(6)}';
  }

  String get mapQueryLabel => name;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'project_id': projectId,
      'name': name,
      'elevation': elevation,
      'description': description,
      'location_hint': locationHint,
      'protection_note': protectionNote,
      'last_verified_at': lastVerifiedAt?.toIso8601String(),
      'status': status.name,
      'kind': kind.name,
      'photo_path': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'coordinate_accuracy_m': coordinateAccuracyM,
      'coordinate_captured_at': coordinateCapturedAt?.toIso8601String(),
    };
  }

  factory BenchMark.fromMap(Map<String, dynamic> map) {
    final statusName =
        map['status'] as String? ?? BenchMarkStatus.available.name;
    final kindName = map['kind'] as String? ?? BenchMarkKind.bm.name;
    return BenchMark(
      id: map['id'] as int?,
      projectId: map['project_id'] as int,
      name: map['name'] as String,
      elevation: (map['elevation'] as num).toDouble(),
      description: map['description'] as String?,
      locationHint: map['location_hint'] as String?,
      protectionNote: map['protection_note'] as String?,
      lastVerifiedAt: map['last_verified_at'] == null
          ? null
          : DateTime.parse(map['last_verified_at'] as String),
      status: _statusFromName(statusName),
      kind: _kindFromName(kindName),
      photoPath: map['photo_path'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      coordinateAccuracyM: (map['coordinate_accuracy_m'] as num?)?.toDouble(),
      coordinateCapturedAt: map['coordinate_captured_at'] == null
          ? null
          : DateTime.parse(map['coordinate_captured_at'] as String),
    );
  }

  BenchMark copyWith({
    int? id,
    int? projectId,
    String? name,
    double? elevation,
    String? description,
    String? locationHint,
    String? protectionNote,
    DateTime? lastVerifiedAt,
    BenchMarkStatus? status,
    BenchMarkKind? kind,
    String? photoPath,
    double? latitude,
    double? longitude,
    double? coordinateAccuracyM,
    DateTime? coordinateCapturedAt,
    bool clearDescription = false,
    bool clearLocationHint = false,
    bool clearProtectionNote = false,
    bool clearPhoto = false,
    bool clearCoordinate = false,
  }) {
    return BenchMark(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      elevation: elevation ?? this.elevation,
      description: clearDescription ? null : description ?? this.description,
      locationHint: clearLocationHint
          ? null
          : locationHint ?? this.locationHint,
      protectionNote: clearProtectionNote
          ? null
          : protectionNote ?? this.protectionNote,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      status: status ?? this.status,
      kind: kind ?? this.kind,
      photoPath: clearPhoto ? null : photoPath ?? this.photoPath,
      latitude: clearCoordinate ? null : latitude ?? this.latitude,
      longitude: clearCoordinate ? null : longitude ?? this.longitude,
      coordinateAccuracyM: clearCoordinate
          ? null
          : coordinateAccuracyM ?? this.coordinateAccuracyM,
      coordinateCapturedAt: clearCoordinate
          ? null
          : coordinateCapturedAt ?? this.coordinateCapturedAt,
    );
  }

  static BenchMarkStatus _statusFromName(String name) {
    for (final value in BenchMarkStatus.values) {
      if (value.name == name) return value;
    }
    return BenchMarkStatus.available;
  }

  static BenchMarkKind _kindFromName(String name) {
    for (final value in BenchMarkKind.values) {
      if (value.name == name) return value;
    }
    return BenchMarkKind.bm;
  }
}
