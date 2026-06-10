import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/backup/project_backup_service.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/project/domain/project.dart';

void main() {
  test('project backup restores BM field books and measurements', () {
    final source = ProjectBackupData(
      project: Project(id: 1, name: '현장 A'),
      benchmarks: [
        BenchMark(id: 1, projectId: 1, name: 'BM.1', elevation: 100),
      ],
      fieldBooks: [
        FieldBook(
          id: 1,
          projectId: 1,
          title: '야장 A',
          date: DateTime(2026, 6, 8),
        ),
      ],
      measurements: [
        Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'BM.1', bs: 1),
      ],
    );

    final encoded = ProjectBackupService.encode(source);
    final decoded = ProjectBackupService.decode(encoded);

    expect(decoded.project.name, '현장 A');
    expect(decoded.benchmarks, hasLength(1));
    expect(decoded.fieldBooks, hasLength(1));
    expect(decoded.measurements, hasLength(1));
  });

  test('project backup includes BM photo asset and coordinate metadata', () {
    final source = ProjectBackupData(
      project: Project(id: 1, name: '현장 A'),
      benchmarks: [
        BenchMark(
          id: 11,
          projectId: 1,
          name: 'TBM.1',
          elevation: 100,
          kind: BenchMarkKind.tbm,
          photoPath: 'benchmark_photos/project_1/tbm_1.jpg',
          latitude: 37.5665,
          longitude: 126.978,
          coordinateAccuracyM: 3.2,
        ),
      ],
      fieldBooks: const [],
      measurements: const [],
      benchmarkPhotoAssets: const [
        ProjectBackupPhotoAsset(
          benchmarkId: 11,
          relativePath: 'benchmark_photos/project_1/tbm_1.jpg',
          contentBase64: 'aW1hZ2U=',
          mediaType: 'image/jpeg',
        ),
      ],
    );

    final decoded = ProjectBackupService.decode(
      ProjectBackupService.encode(source),
    );

    expect(decoded.benchmarkPhotoAssets.single.benchmarkId, 11);
    expect(decoded.benchmarkPhotoAssets.single.contentBase64, 'aW1hZ2U=');
    expect(decoded.benchmarks.single.kind, BenchMarkKind.tbm);
    expect(decoded.benchmarks.single.photoPath, contains('tbm_1.jpg'));
    expect(decoded.benchmarks.single.latitude, 37.5665);
  });

  test('malformed project backup is rejected with message', () {
    expect(
      () => ProjectBackupService.decode('{"kind":"wrong"}'),
      throwsA(isA<ProjectBackupException>()),
    );
  });

  test('collectProject reads project graph from backup store', () async {
    final store = MemoryProjectBackupStore(
      projects: [Project(id: 7, name: '현장 A')],
      benchmarks: [
        BenchMark(id: 11, projectId: 7, name: 'BM.1', elevation: 100),
      ],
      fieldBooks: [
        FieldBook(
          id: 21,
          projectId: 7,
          title: '야장 A',
          date: DateTime(2026, 6, 8),
          startBmId: 11,
        ),
      ],
      measurements: [
        Measurement(
          id: 31,
          fieldBookId: 21,
          orderIndex: 0,
          stationName: 'BM.1',
          bs: 1,
        ),
      ],
    );

    final data = await ProjectBackupService(store: store).collectProject(7);

    expect(data.project.id, 7);
    expect(data.benchmarks.single.id, 11);
    expect(data.fieldBooks.single.startBmId, 11);
    expect(data.measurements.single.fieldBookId, 21);
  });

  test('restoreAsNewProject remaps ids for project graph', () async {
    final store = MemoryProjectBackupStore(
      projects: [Project(id: 1, name: '기존 현장')],
    );
    final backup = ProjectBackupData(
      project: Project(id: 7, name: '복원 현장'),
      benchmarks: [
        BenchMark(id: 11, projectId: 7, name: 'BM.1', elevation: 100),
      ],
      fieldBooks: [
        FieldBook(
          id: 21,
          projectId: 7,
          title: '야장 A',
          date: DateTime(2026, 6, 8),
          startBmId: 11,
        ),
      ],
      measurements: [
        Measurement(
          id: 31,
          fieldBookId: 21,
          orderIndex: 0,
          stationName: 'BM.1',
          bs: 1,
        ),
      ],
    );

    final result = await ProjectBackupService(
      store: store,
    ).restoreAsNewProject(ProjectBackupService.encode(backup));

    expect(result.projectId, isNot(7));
    expect(result.benchmarkIdMap, {11: 1});
    expect(result.fieldBookIdMap, {21: 1});
    expect(store.projects.last.id, result.projectId);
    expect(store.projects.last.name, '복원 현장');
    expect(store.benchmarks.last.projectId, result.projectId);
    expect(store.fieldBooks.last.projectId, result.projectId);
    expect(store.fieldBooks.last.startBmId, result.benchmarkIdMap[11]);
    expect(store.measurements.last.fieldBookId, result.fieldBookIdMap[21]);
  });

  test(
    'restoreAsNewProject restores BM photo asset to the new project path',
    () async {
      final store = MemoryProjectBackupStore(
        projects: [Project(id: 1, name: '기존 현장')],
      );
      final photoStore = MemoryProjectBackupPhotoAssetStore();
      final backup = ProjectBackupData(
        project: Project(id: 7, name: '복원 현장'),
        benchmarks: [
          BenchMark(
            id: 11,
            projectId: 7,
            name: 'TBM.1',
            elevation: 100,
            kind: BenchMarkKind.tbm,
            photoPath: 'benchmark_photos/project_7/tbm_1.jpg',
            latitude: 37.5665,
            longitude: 126.978,
          ),
        ],
        fieldBooks: const [],
        measurements: const [],
        benchmarkPhotoAssets: const [
          ProjectBackupPhotoAsset(
            benchmarkId: 11,
            relativePath: 'benchmark_photos/project_7/tbm_1.jpg',
            contentBase64: 'aW1hZ2U=',
            mediaType: 'image/jpeg',
          ),
        ],
      );

      final result = await ProjectBackupService(
        store: store,
        photoAssetStore: photoStore,
      ).restoreAsNewProject(ProjectBackupService.encode(backup));

      expect(result.benchmarkIdMap[11], 1);
      expect(
        store.benchmarks.single.photoPath,
        'benchmark_photos/project_${result.projectId}/restored_11.jpg',
      );
      expect(store.benchmarks.single.latitude, 37.5665);
      expect(photoStore.restoredAssets.single.contentBase64, 'aW1hZ2U=');
    },
  );

  test('restoreAsNewProject clears photo path when asset is missing', () async {
    final store = MemoryProjectBackupStore(
      projects: [Project(id: 1, name: '기존 현장')],
    );
    final backup = ProjectBackupData(
      project: Project(id: 7, name: '복원 현장'),
      benchmarks: [
        BenchMark(
          id: 11,
          projectId: 7,
          name: 'TBM.1',
          elevation: 100,
          photoPath: 'benchmark_photos/project_7/tbm_1.jpg',
        ),
      ],
      fieldBooks: const [],
      measurements: const [],
    );

    await ProjectBackupService(
      store: store,
      photoAssetStore: MemoryProjectBackupPhotoAssetStore(),
    ).restoreAsNewProject(ProjectBackupService.encode(backup));

    expect(store.benchmarks.single.photoPath, isNull);
  });

  test('project backup rejects unsafe photo paths', () async {
    final absolutePhoto = ProjectBackupData(
      project: Project(id: 7, name: '복원 현장'),
      benchmarks: [
        BenchMark(
          id: 11,
          projectId: 7,
          name: 'TBM.1',
          elevation: 100,
          photoPath: '/tmp/outside.jpg',
        ),
      ],
      fieldBooks: const [],
      measurements: const [],
    );
    final traversalAsset = ProjectBackupData(
      project: Project(id: 7, name: '복원 현장'),
      benchmarks: [
        BenchMark(
          id: 11,
          projectId: 7,
          name: 'TBM.1',
          elevation: 100,
          photoPath: 'benchmark_photos/project_7/tbm_1.jpg',
        ),
      ],
      fieldBooks: const [],
      measurements: const [],
      benchmarkPhotoAssets: const [
        ProjectBackupPhotoAsset(
          benchmarkId: 11,
          relativePath: '../outside.jpg',
          contentBase64: 'aW1hZ2U=',
          mediaType: 'image/jpeg',
        ),
      ],
    );

    await expectLater(
      ProjectBackupService(
        store: MemoryProjectBackupStore(),
      ).restoreAsNewProject(ProjectBackupService.encode(absolutePhoto)),
      throwsA(isA<ProjectBackupException>()),
    );
    await expectLater(
      ProjectBackupService(
        store: MemoryProjectBackupStore(),
      ).restoreAsNewProject(ProjectBackupService.encode(traversalAsset)),
      throwsA(isA<ProjectBackupException>()),
    );
  });

  test(
    'restoreAsNewProject rejects corrupt graph without partial writes',
    () async {
      final store = MemoryProjectBackupStore(
        projects: [Project(id: 1, name: '기존 현장')],
      );
      final corruptBackup = ProjectBackupData(
        project: Project(id: 7, name: '복원 현장'),
        benchmarks: const [],
        fieldBooks: const [],
        measurements: [
          Measurement(
            id: 31,
            fieldBookId: 999,
            orderIndex: 0,
            stationName: 'No.1',
            fs: 1,
          ),
        ],
      );

      await expectLater(
        ProjectBackupService(
          store: store,
        ).restoreAsNewProject(ProjectBackupService.encode(corruptBackup)),
        throwsA(isA<ProjectBackupException>()),
      );
      expect(store.projects.map((project) => project.name), ['기존 현장']);
      expect(store.benchmarks, isEmpty);
      expect(store.fieldBooks, isEmpty);
      expect(store.measurements, isEmpty);
    },
  );

  test('restoreAsNewProject rolls back when an insert fails', () async {
    final store = MemoryProjectBackupStore(
      projects: [Project(id: 1, name: '기존 현장')],
      failBenchmarkName: 'BM.fail',
    );
    final backup = ProjectBackupData(
      project: Project(id: 7, name: '복원 현장'),
      benchmarks: [
        BenchMark(id: 11, projectId: 7, name: 'BM.fail', elevation: 100),
      ],
      fieldBooks: const [],
      measurements: const [],
    );

    await expectLater(
      ProjectBackupService(
        store: store,
      ).restoreAsNewProject(ProjectBackupService.encode(backup)),
      throwsA(isA<ProjectBackupException>()),
    );
    expect(store.projects.map((project) => project.name), ['기존 현장']);
    expect(store.benchmarks, isEmpty);
  });

  test('restoreAsNewProject cleans restored photo when insert fails', () async {
    final store = MemoryProjectBackupStore(
      projects: [Project(id: 1, name: '기존 현장')],
      failBenchmarkName: 'BM.fail',
    );
    final photoStore = MemoryProjectBackupPhotoAssetStore();
    final backup = ProjectBackupData(
      project: Project(id: 7, name: '복원 현장'),
      benchmarks: [
        BenchMark(
          id: 11,
          projectId: 7,
          name: 'BM.fail',
          elevation: 100,
          photoPath: 'benchmark_photos/project_7/bm_fail.jpg',
        ),
      ],
      fieldBooks: const [],
      measurements: const [],
      benchmarkPhotoAssets: const [
        ProjectBackupPhotoAsset(
          benchmarkId: 11,
          relativePath: 'benchmark_photos/project_7/bm_fail.jpg',
          contentBase64: 'aW1hZ2U=',
          mediaType: 'image/jpeg',
        ),
      ],
    );

    await expectLater(
      ProjectBackupService(
        store: store,
        photoAssetStore: photoStore,
      ).restoreAsNewProject(ProjectBackupService.encode(backup)),
      throwsA(isA<ProjectBackupException>()),
    );

    expect(store.projects.map((project) => project.name), ['기존 현장']);
    expect(store.benchmarks, isEmpty);
    expect(photoStore.restoredPaths, [
      'benchmark_photos/project_2/restored_11.jpg',
    ]);
    expect(photoStore.deletedPaths, photoStore.restoredPaths);
  });
}

class MemoryProjectBackupPhotoAssetStore
    implements ProjectBackupPhotoAssetStore {
  final restoredAssets = <ProjectBackupPhotoAsset>[];
  final restoredPaths = <String>[];
  final deletedPaths = <String>[];

  @override
  Future<ProjectBackupPhotoAsset?> readAsset(BenchMark benchmark) async {
    return null;
  }

  @override
  Future<String> restoreAsset({
    required int projectId,
    required BenchMark benchmark,
    required ProjectBackupPhotoAsset asset,
  }) async {
    restoredAssets.add(asset);
    final path =
        'benchmark_photos/project_$projectId/restored_${benchmark.id}.jpg';
    restoredPaths.add(path);
    return path;
  }

  @override
  Future<void> deleteRestoredAsset(String relativePath) async {
    deletedPaths.add(relativePath);
  }
}

class MemoryProjectBackupStore implements ProjectBackupStore {
  List<Project> projects;
  List<BenchMark> benchmarks;
  List<FieldBook> fieldBooks;
  List<Measurement> measurements;
  final String? failBenchmarkName;

  MemoryProjectBackupStore({
    List<Project>? projects,
    List<BenchMark>? benchmarks,
    List<FieldBook>? fieldBooks,
    List<Measurement>? measurements,
    this.failBenchmarkName,
  }) : projects = List.of(projects ?? const []),
       benchmarks = List.of(benchmarks ?? const []),
       fieldBooks = List.of(fieldBooks ?? const []),
       measurements = List.of(measurements ?? const []);

  @override
  Future<Project?> getProject(int id) async {
    return projects.where((project) => project.id == id).firstOrNull;
  }

  @override
  Future<List<BenchMark>> getBenchmarksByProjectId(int projectId) async {
    return benchmarks
        .where((benchmark) => benchmark.projectId == projectId)
        .toList();
  }

  @override
  Future<List<FieldBook>> getFieldBooksByProjectId(int projectId) async {
    return fieldBooks
        .where((fieldBook) => fieldBook.projectId == projectId)
        .toList();
  }

  @override
  Future<List<Measurement>> getMeasurementsByFieldBookId(
    int fieldBookId,
  ) async {
    return measurements
        .where((measurement) => measurement.fieldBookId == fieldBookId)
        .toList();
  }

  @override
  Future<T> restoreTransaction<T>(
    Future<T> Function(ProjectBackupRestoreStore store) action,
  ) async {
    final projectSnapshot = List<Project>.of(projects);
    final benchmarkSnapshot = List<BenchMark>.of(benchmarks);
    final fieldBookSnapshot = List<FieldBook>.of(fieldBooks);
    final measurementSnapshot = List<Measurement>.of(measurements);

    try {
      return await action(_MemoryProjectBackupRestoreStore(this));
    } catch (_) {
      projects = projectSnapshot;
      benchmarks = benchmarkSnapshot;
      fieldBooks = fieldBookSnapshot;
      measurements = measurementSnapshot;
      rethrow;
    }
  }
}

class _MemoryProjectBackupRestoreStore implements ProjectBackupRestoreStore {
  final MemoryProjectBackupStore _store;

  const _MemoryProjectBackupRestoreStore(this._store);

  @override
  Future<int> insertProject(Project project) async {
    final id = _nextId(_store.projects.map((item) => item.id));
    _store.projects.add(
      Project(
        id: id,
        name: project.name,
        description: project.description,
        createdAt: project.createdAt,
        updatedAt: project.updatedAt,
      ),
    );
    return id;
  }

  @override
  Future<int> insertBenchmark(BenchMark benchmark) async {
    if (benchmark.name == _store.failBenchmarkName) {
      throw const ProjectBackupException('BM 데이터가 손상되었습니다.');
    }
    final id = _nextId(_store.benchmarks.map((item) => item.id));
    _store.benchmarks.add(
      BenchMark(
        id: id,
        projectId: benchmark.projectId,
        name: benchmark.name,
        elevation: benchmark.elevation,
        description: benchmark.description,
        locationHint: benchmark.locationHint,
        protectionNote: benchmark.protectionNote,
        lastVerifiedAt: benchmark.lastVerifiedAt,
        status: benchmark.status,
        kind: benchmark.kind,
        photoPath: benchmark.photoPath,
        latitude: benchmark.latitude,
        longitude: benchmark.longitude,
        coordinateAccuracyM: benchmark.coordinateAccuracyM,
        coordinateCapturedAt: benchmark.coordinateCapturedAt,
      ),
    );
    return id;
  }

  @override
  Future<int> insertFieldBook(FieldBook fieldBook) async {
    final id = _nextId(_store.fieldBooks.map((item) => item.id));
    _store.fieldBooks.add(
      FieldBook(
        id: id,
        projectId: fieldBook.projectId,
        title: fieldBook.title,
        date: fieldBook.date,
        startBmId: fieldBook.startBmId,
        startElevation: fieldBook.startElevation,
        memo: fieldBook.memo,
        surveyor: fieldBook.surveyor,
        checker: fieldBook.checker,
        instrument: fieldBook.instrument,
        weather: fieldBook.weather,
        workSection: fieldBook.workSection,
        jobNumber: fieldBook.jobNumber,
        reviewStatus: fieldBook.reviewStatus,
        reviewMemo: fieldBook.reviewMemo,
        reviewedAt: fieldBook.reviewedAt,
        createdAt: fieldBook.createdAt,
      ),
    );
    return id;
  }

  @override
  Future<int> insertMeasurement(Measurement measurement) async {
    final id = _nextId(_store.measurements.map((item) => item.id));
    _store.measurements.add(
      Measurement(
        id: id,
        fieldBookId: measurement.fieldBookId,
        orderIndex: measurement.orderIndex,
        stationName: measurement.stationName,
        type: measurement.type,
        bs: measurement.bs,
        fs: measurement.fs,
        ih: measurement.ih,
        gh: measurement.gh,
        manualTp: measurement.manualTp,
      ),
    );
    return id;
  }

  int _nextId(Iterable<int?> ids) {
    return ids.whereType<int>().fold(0, (max, id) => id > max ? id : max) + 1;
  }
}
