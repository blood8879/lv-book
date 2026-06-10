import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';

void main() {
  test('BM context fields save and render status chip', () {
    final bm = BenchMark(
      projectId: 1,
      name: 'BM.1',
      elevation: 100.123,
      locationHint: '현장사무실 앞',
      protectionNote: '말뚝 보호캡 확인',
      lastVerifiedAt: DateTime(2026, 6, 3),
      status: BenchMarkStatus.damagedSuspected,
    );

    final reloaded = BenchMark.fromMap(bm.toMap());

    expect(reloaded.locationHint, '현장사무실 앞');
    expect(reloaded.protectionNote, '말뚝 보호캡 확인');
    expect(reloaded.lastVerifiedAt, DateTime(2026, 6, 3));
    expect(reloaded.status.label, '훼손 의심');
  });

  test('stopped BM is excluded from new field book selector', () {
    final stopped = BenchMark(
      projectId: 1,
      name: 'BM.2',
      elevation: 99,
      status: BenchMarkStatus.stopped,
    );

    expect(stopped.isSelectableForFieldBook, isFalse);
  });

  test('old v5 BM maps default to BM kind without Pro fields', () {
    final reloaded = BenchMark.fromMap({
      'id': 7,
      'project_id': 1,
      'name': 'BM.OLD',
      'elevation': 100.25,
      'description': null,
      'location_hint': '정문',
      'protection_note': null,
      'last_verified_at': null,
      'status': 'available',
    });

    expect(reloaded.kind, BenchMarkKind.bm);
    expect(reloaded.kind.label, 'BM');
    expect(reloaded.photoPath, isNull);
    expect(reloaded.latitude, isNull);
    expect(reloaded.longitude, isNull);
    expect(reloaded.coordinateAccuracyM, isNull);
    expect(reloaded.coordinateCapturedAt, isNull);
    expect(reloaded.hasPhoto, isFalse);
    expect(reloaded.hasCoordinate, isFalse);
  });

  test('TBM photo and coordinates round-trip through map serialization', () {
    final capturedAt = DateTime(2026, 6, 9, 11, 30);
    final tbm = BenchMark(
      projectId: 1,
      name: 'TBM.1',
      elevation: 25.12,
      kind: BenchMarkKind.tbm,
      photoPath: '/tmp/tbm.jpg',
      latitude: 37.5665,
      longitude: 126.978,
      coordinateAccuracyM: 3.5,
      coordinateCapturedAt: capturedAt,
    );

    final reloaded = BenchMark.fromMap(tbm.toMap());

    expect(reloaded.kind, BenchMarkKind.tbm);
    expect(reloaded.kind.label, 'TBM');
    expect(reloaded.photoPath, '/tmp/tbm.jpg');
    expect(reloaded.latitude, 37.5665);
    expect(reloaded.longitude, 126.978);
    expect(reloaded.coordinateAccuracyM, 3.5);
    expect(reloaded.coordinateCapturedAt, capturedAt);
    expect(reloaded.hasPhoto, isTrue);
    expect(reloaded.hasCoordinate, isTrue);
    expect(reloaded.formattedCoordinate, '37.566500, 126.978000');
    expect(reloaded.copyCoordinateText, '위도 37.566500, 경도 126.978000');
    expect(reloaded.mapQueryLabel, 'TBM.1');
  });

  test('clear helpers remove nullable Pro fields without changing BM data', () {
    final capturedAt = DateTime(2026, 6, 9, 11, 30);
    final tbm = BenchMark(
      id: 3,
      projectId: 1,
      name: 'TBM.2',
      elevation: 31.1,
      kind: BenchMarkKind.tbm,
      photoPath: '/tmp/old.jpg',
      latitude: 35.1,
      longitude: 129.2,
      coordinateAccuracyM: 4,
      coordinateCapturedAt: capturedAt,
    );

    final cleared = tbm.copyWith(clearPhoto: true, clearCoordinate: true);

    expect(cleared.id, 3);
    expect(cleared.projectId, 1);
    expect(cleared.name, 'TBM.2');
    expect(cleared.elevation, 31.1);
    expect(cleared.kind, BenchMarkKind.tbm);
    expect(cleared.photoPath, isNull);
    expect(cleared.latitude, isNull);
    expect(cleared.longitude, isNull);
    expect(cleared.coordinateAccuracyM, isNull);
    expect(cleared.coordinateCapturedAt, isNull);
  });

  test('invalid BM kind falls back to bm', () {
    final reloaded = BenchMark.fromMap({
      'project_id': 1,
      'name': 'BM.BAD_KIND',
      'elevation': 100.25,
      'kind': 'control-point',
      'status': 'available',
    });

    expect(reloaded.kind, BenchMarkKind.bm);
  });
}
