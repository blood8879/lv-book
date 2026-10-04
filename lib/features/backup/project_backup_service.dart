import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../../l10n/l10n.dart';
import '../benchmark/data/benchmark_repository.dart';
import '../benchmark/domain/benchmark.dart';
import '../fieldbook/data/fieldbook_repository.dart';
import '../fieldbook/data/measurement_repository.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import '../project/data/project_repository.dart';
import '../project/domain/project.dart';

/// Why a backup could not be read or written. Rendered in the app language
/// via [ProjectBackupException.localizedMessage].
enum ProjectBackupError {
  invalidFormat,
  unsupported,
  corrupted,
  benchmarkCorrupted,
  fieldBookCorrupted,
  measurementCorrupted,
  photoCorrupted,
  projectNotFound,
}

class ProjectBackupException implements Exception {
  final ProjectBackupError? error;
  final String? _rawMessage;

  /// Exception with a fixed (untranslated) message, e.g. from tests.
  const ProjectBackupException(String message)
    : _rawMessage = message,
      error = null;

  const ProjectBackupException.of(ProjectBackupError this.error)
    : _rawMessage = null;

  String localizedMessage(AppLocalizations l10n) {
    return switch (error) {
      null => _rawMessage ?? '',
      ProjectBackupError.invalidFormat => l10n.backupErrorInvalidFormat,
      ProjectBackupError.unsupported => l10n.backupErrorUnsupported,
      ProjectBackupError.corrupted => l10n.backupErrorCorrupted,
      ProjectBackupError.benchmarkCorrupted =>
        l10n.backupErrorBenchmarkCorrupted,
      ProjectBackupError.fieldBookCorrupted =>
        l10n.backupErrorFieldBookCorrupted,
      ProjectBackupError.measurementCorrupted =>
        l10n.backupErrorMeasurementCorrupted,
      ProjectBackupError.photoCorrupted => l10n.backupErrorPhotoCorrupted,
      ProjectBackupError.projectNotFound => l10n.backupErrorProjectNotFound,
    };
  }

  /// Legacy Korean message; prefer [localizedMessage].
  String get message => localizedMessage(l10nKo);

  @override
  String toString() => message;
}

class ProjectBackupData {
  final Project project;
  final List<BenchMark> benchmarks;
  final List<FieldBook> fieldBooks;
  final List<Measurement> measurements;
  final List<ProjectBackupPhotoAsset> benchmarkPhotoAssets;

  const ProjectBackupData({
    required this.project,
    required this.benchmarks,
    required this.fieldBooks,
    required this.measurements,
    this.benchmarkPhotoAssets = const [],
  });
}

class ProjectBackupPhotoAsset {
  final int benchmarkId;
  final String relativePath;
  final String contentBase64;
  final String mediaType;

  const ProjectBackupPhotoAsset({
    required this.benchmarkId,
    required this.relativePath,
    required this.contentBase64,
    required this.mediaType,
  });

  Map<String, dynamic> toMap() {
    return {
      'benchmark_id': benchmarkId,
      'relative_path': relativePath,
      'content_base64': contentBase64,
      'media_type': mediaType,
    };
  }

  factory ProjectBackupPhotoAsset.fromMap(Map<String, dynamic> map) {
    return ProjectBackupPhotoAsset(
      benchmarkId: map['benchmark_id'] as int,
      relativePath: map['relative_path'] as String,
      contentBase64: map['content_base64'] as String,
      mediaType: map['media_type'] as String? ?? 'image/jpeg',
    );
  }
}

class ProjectBackupRestoreResult {
  final int projectId;
  final Map<int, int> benchmarkIdMap;
  final Map<int, int> fieldBookIdMap;

  const ProjectBackupRestoreResult({
    required this.projectId,
    required this.benchmarkIdMap,
    required this.fieldBookIdMap,
  });
}

abstract class ProjectBackupStore {
  Future<Project?> getProject(int id);
  Future<List<BenchMark>> getBenchmarksByProjectId(int projectId);
  Future<List<FieldBook>> getFieldBooksByProjectId(int projectId);
  Future<List<Measurement>> getMeasurementsByFieldBookId(int fieldBookId);
  Future<T> restoreTransaction<T>(
    Future<T> Function(ProjectBackupRestoreStore store) action,
  );
}

abstract class ProjectBackupRestoreStore {
  Future<int> insertProject(Project project);
  Future<int> insertBenchmark(BenchMark benchmark);
  Future<int> insertFieldBook(FieldBook fieldBook);
  Future<int> insertMeasurement(Measurement measurement);
}

abstract class ProjectBackupPhotoAssetStore {
  Future<ProjectBackupPhotoAsset?> readAsset(BenchMark benchmark);

  Future<String> restoreAsset({
    required int projectId,
    required BenchMark benchmark,
    required ProjectBackupPhotoAsset asset,
  });

  Future<void> deleteRestoredAsset(String relativePath);
}

class ProjectBackupFilePhotoAssetStore implements ProjectBackupPhotoAssetStore {
  @override
  Future<ProjectBackupPhotoAsset?> readAsset(BenchMark benchmark) async {
    final id = benchmark.id;
    final relativePath = benchmark.photoPath;
    if (id == null || relativePath == null || relativePath.trim().isEmpty) {
      return null;
    }
    if (!_isSafeAssetPath(relativePath)) return null;

    final root = await getApplicationDocumentsDirectory();
    final file = File(p.join(root.path, relativePath));
    if (!await file.exists()) return null;

    return ProjectBackupPhotoAsset(
      benchmarkId: id,
      relativePath: relativePath,
      contentBase64: base64Encode(await file.readAsBytes()),
      mediaType: _mediaTypeFor(relativePath),
    );
  }

  @override
  Future<String> restoreAsset({
    required int projectId,
    required BenchMark benchmark,
    required ProjectBackupPhotoAsset asset,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    if (!_isSafeAssetPath(asset.relativePath)) {
      throw const ProjectBackupException.of(ProjectBackupError.photoCorrupted);
    }
    final relativeDir = p.join('benchmark_photos', 'project_$projectId');
    final targetDir = Directory(p.join(root.path, relativeDir));
    await targetDir.create(recursive: true);

    final extension = _safeExtension(asset.relativePath);
    final fileName =
        'restored_${benchmark.id}_${DateTime.now().microsecondsSinceEpoch}$extension';
    final relativePath = p.join(relativeDir, fileName);
    final targetFile = File(p.join(root.path, relativePath));
    await targetFile.writeAsBytes(base64Decode(asset.contentBase64));
    return relativePath;
  }

  @override
  Future<void> deleteRestoredAsset(String relativePath) async {
    if (!_isSafeAssetPath(relativePath)) return;
    final root = await getApplicationDocumentsDirectory();
    final file = File(p.join(root.path, relativePath));
    if (await file.exists()) {
      await file.delete();
    }
  }

  static String _mediaTypeFor(String relativePath) {
    final extension = p.extension(relativePath).toLowerCase();
    if (extension == '.png') return 'image/png';
    return 'image/jpeg';
  }

  static String _safeExtension(String relativePath) {
    final extension = p.extension(relativePath).toLowerCase();
    if (extension == '.png' || extension == '.jpg' || extension == '.jpeg') {
      return extension;
    }
    return '.jpg';
  }

  static bool _isSafeAssetPath(String path) {
    if (p.posix.isAbsolute(path) || p.windows.isAbsolute(path)) return false;
    final normalized = path.replaceAll('\\', p.separator);
    final segments = p.split(normalized).where((segment) => segment.isNotEmpty);
    return !segments.contains('..');
  }
}

class DatabaseProjectBackupStore implements ProjectBackupStore {
  final DatabaseHelper _dbHelper;
  final ProjectRepository _projectRepository;
  final BenchMarkRepository _benchMarkRepository;
  final FieldBookRepository _fieldBookRepository;
  final MeasurementRepository _measurementRepository;

  DatabaseProjectBackupStore({
    DatabaseHelper? dbHelper,
    ProjectRepository? projectRepository,
    BenchMarkRepository? benchMarkRepository,
    FieldBookRepository? fieldBookRepository,
    MeasurementRepository? measurementRepository,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance,
       _projectRepository = projectRepository ?? ProjectRepository(),
       _benchMarkRepository = benchMarkRepository ?? BenchMarkRepository(),
       _fieldBookRepository = fieldBookRepository ?? FieldBookRepository(),
       _measurementRepository =
           measurementRepository ?? MeasurementRepository();

  @override
  Future<Project?> getProject(int id) => _projectRepository.getById(id);

  @override
  Future<List<BenchMark>> getBenchmarksByProjectId(int projectId) {
    return _benchMarkRepository.getByProjectId(projectId);
  }

  @override
  Future<List<FieldBook>> getFieldBooksByProjectId(int projectId) {
    return _fieldBookRepository.getByProjectId(projectId);
  }

  @override
  Future<List<Measurement>> getMeasurementsByFieldBookId(int fieldBookId) {
    return _measurementRepository.getByFieldBookId(fieldBookId);
  }

  @override
  Future<T> restoreTransaction<T>(
    Future<T> Function(ProjectBackupRestoreStore store) action,
  ) async {
    final db = await _dbHelper.database;
    return db.transaction((transaction) {
      return action(_DatabaseProjectBackupRestoreStore(transaction));
    });
  }
}

class _DatabaseProjectBackupRestoreStore implements ProjectBackupRestoreStore {
  final Transaction _transaction;

  const _DatabaseProjectBackupRestoreStore(this._transaction);

  @override
  Future<int> insertProject(Project project) {
    final map = Map<String, dynamic>.from(project.toMap())..remove('id');
    return _transaction.insert('projects', map);
  }

  @override
  Future<int> insertBenchmark(BenchMark benchmark) {
    final map = Map<String, dynamic>.from(benchmark.toMap())..remove('id');
    return _transaction.insert('benchmarks', map);
  }

  @override
  Future<int> insertFieldBook(FieldBook fieldBook) {
    final map = Map<String, dynamic>.from(fieldBook.toMap())..remove('id');
    return _transaction.insert('field_books', map);
  }

  @override
  Future<int> insertMeasurement(Measurement measurement) {
    final map = Map<String, dynamic>.from(measurement.toMap())..remove('id');
    return _transaction.insert('measurements', map);
  }
}

class ProjectBackupService {
  static const kind = 'lv_book_project_backup';
  static const version = 1;
  final ProjectBackupStore _store;
  final ProjectBackupPhotoAssetStore? _photoAssetStore;

  ProjectBackupService({
    ProjectBackupStore? store,
    ProjectBackupPhotoAssetStore? photoAssetStore,
  }) : _store = store ?? DatabaseProjectBackupStore(),
       _photoAssetStore = photoAssetStore ?? ProjectBackupFilePhotoAssetStore();

  static String encode(ProjectBackupData data) {
    return const JsonEncoder.withIndent('  ').convert({
      'kind': kind,
      'version': version,
      'project': data.project.toMap(),
      'benchmarks': data.benchmarks.map((item) => item.toMap()).toList(),
      'field_books': data.fieldBooks.map((item) => item.toMap()).toList(),
      'measurements': data.measurements.map((item) => item.toMap()).toList(),
      if (data.benchmarkPhotoAssets.isNotEmpty)
        'benchmark_photo_assets': data.benchmarkPhotoAssets
            .map((item) => item.toMap())
            .toList(),
    });
  }

  static ProjectBackupData decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const ProjectBackupException.of(ProjectBackupError.invalidFormat);
    }
    if (decoded['kind'] != kind || decoded['version'] != version) {
      throw const ProjectBackupException.of(ProjectBackupError.unsupported);
    }

    final project = decoded['project'];
    final benchmarks = decoded['benchmarks'];
    final fieldBooks = decoded['field_books'];
    final measurements = decoded['measurements'];
    final benchmarkPhotoAssets = decoded['benchmark_photo_assets'];
    if (project is! Map<String, dynamic> ||
        benchmarks is! List ||
        fieldBooks is! List ||
        measurements is! List) {
      throw const ProjectBackupException.of(ProjectBackupError.corrupted);
    }

    return ProjectBackupData(
      project: Project.fromMap(project),
      benchmarks: [
        for (final item in benchmarks)
          BenchMark.fromMap(
            _asStringKeyMap(item, ProjectBackupError.benchmarkCorrupted),
          ),
      ],
      fieldBooks: [
        for (final item in fieldBooks)
          FieldBook.fromMap(
            _asStringKeyMap(item, ProjectBackupError.fieldBookCorrupted),
          ),
      ],
      measurements: [
        for (final item in measurements)
          Measurement.fromMap(
            _asStringKeyMap(item, ProjectBackupError.measurementCorrupted),
          ),
      ],
      benchmarkPhotoAssets: [
        if (benchmarkPhotoAssets != null) ...[
          if (benchmarkPhotoAssets is! List)
            throw const ProjectBackupException.of(
              ProjectBackupError.photoCorrupted,
            ),
          for (final item in benchmarkPhotoAssets)
            ProjectBackupPhotoAsset.fromMap(
              _asStringKeyMap(item, ProjectBackupError.photoCorrupted),
            ),
        ],
      ],
    );
  }

  Future<ProjectBackupData> collectProject(int projectId) async {
    final project = await _store.getProject(projectId);
    if (project == null) {
      throw const ProjectBackupException.of(ProjectBackupError.projectNotFound);
    }

    final benchmarks = await _store.getBenchmarksByProjectId(projectId);
    final fieldBooks = await _store.getFieldBooksByProjectId(projectId);
    final measurements = <Measurement>[];
    final benchmarkPhotoAssets = <ProjectBackupPhotoAsset>[];
    for (final fieldBook in fieldBooks) {
      final fieldBookId = fieldBook.id;
      if (fieldBookId == null) {
        throw const ProjectBackupException.of(
          ProjectBackupError.fieldBookCorrupted,
        );
      }
      measurements.addAll(
        await _store.getMeasurementsByFieldBookId(fieldBookId),
      );
    }
    final photoStore = _photoAssetStore;
    if (photoStore != null) {
      for (final benchmark in benchmarks) {
        final asset = await photoStore.readAsset(benchmark);
        if (asset != null) benchmarkPhotoAssets.add(asset);
      }
    }

    return ProjectBackupData(
      project: project,
      benchmarks: benchmarks,
      fieldBooks: fieldBooks,
      measurements: measurements,
      benchmarkPhotoAssets: benchmarkPhotoAssets,
    );
  }

  Future<ProjectBackupRestoreResult> restoreAsNewProject(String source) async {
    final data = decode(source);
    _validateGraph(data);
    final restoredPhotoPaths = <String>[];

    try {
      return await _store.restoreTransaction((store) async {
        final newProjectId = await store.insertProject(data.project);
        final benchmarkIdMap = <int, int>{};
        final fieldBookIdMap = <int, int>{};
        final photoAssetsByBenchmarkId = {
          for (final asset in data.benchmarkPhotoAssets)
            asset.benchmarkId: asset,
        };

        for (final benchmark in data.benchmarks) {
          final oldId = benchmark.id!;
          final asset = photoAssetsByBenchmarkId[oldId];
          final restoredPhotoPath = asset == null || _photoAssetStore == null
              ? null
              : await _photoAssetStore.restoreAsset(
                  projectId: newProjectId,
                  benchmark: benchmark,
                  asset: asset,
                );
          if (restoredPhotoPath != null) {
            restoredPhotoPaths.add(restoredPhotoPath);
          }
          final newId = await store.insertBenchmark(
            benchmark.copyWith(
              projectId: newProjectId,
              photoPath: restoredPhotoPath,
              clearPhoto: restoredPhotoPath == null,
            ),
          );
          benchmarkIdMap[oldId] = newId;
        }

        for (final fieldBook in data.fieldBooks) {
          final oldId = fieldBook.id!;
          final startBmId = fieldBook.startBmId;
          final closingBmId = fieldBook.closingBmId;
          final newId = await store.insertFieldBook(
            _copyFieldBookForRestore(
              fieldBook,
              projectId: newProjectId,
              startBmId: startBmId == null ? null : benchmarkIdMap[startBmId],
              closingBmId: closingBmId == null
                  ? null
                  : benchmarkIdMap[closingBmId],
            ),
          );
          fieldBookIdMap[oldId] = newId;
        }

        for (final measurement in data.measurements) {
          await store.insertMeasurement(
            measurement.copyWith(
              fieldBookId: fieldBookIdMap[measurement.fieldBookId],
            ),
          );
        }

        return ProjectBackupRestoreResult(
          projectId: newProjectId,
          benchmarkIdMap: Map.unmodifiable(benchmarkIdMap),
          fieldBookIdMap: Map.unmodifiable(fieldBookIdMap),
        );
      });
    } catch (_) {
      final photoStore = _photoAssetStore;
      if (photoStore != null) {
        for (final path in restoredPhotoPaths) {
          try {
            await photoStore.deleteRestoredAsset(path);
          } catch (_) {
            // Restore failed already; best-effort cleanup avoids orphaned files.
          }
        }
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _asStringKeyMap(
    Object? value,
    ProjectBackupError error,
  ) {
    if (value is! Map) throw ProjectBackupException.of(error);
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  static void _validateGraph(ProjectBackupData data) {
    final projectId = data.project.id;
    final benchmarkIds = <int>{};
    final fieldBookIds = <int>{};

    for (final benchmark in data.benchmarks) {
      final id = benchmark.id;
      if (id == null ||
          (projectId != null && benchmark.projectId != projectId)) {
        throw const ProjectBackupException.of(
          ProjectBackupError.benchmarkCorrupted,
        );
      }
      if (benchmark.photoPath != null &&
          !_isSafeBackupRelativePath(benchmark.photoPath!)) {
        throw const ProjectBackupException.of(
          ProjectBackupError.photoCorrupted,
        );
      }
      benchmarkIds.add(id);
    }

    // A start/closing BM missing from the backup (e.g. deleted before FKs
    // were enforced) is not fatal: restore remaps it to null.
    for (final fieldBook in data.fieldBooks) {
      final id = fieldBook.id;
      if (id == null ||
          (projectId != null && fieldBook.projectId != projectId)) {
        throw const ProjectBackupException.of(
          ProjectBackupError.fieldBookCorrupted,
        );
      }
      fieldBookIds.add(id);
    }

    for (final measurement in data.measurements) {
      if (!fieldBookIds.contains(measurement.fieldBookId)) {
        throw const ProjectBackupException.of(
          ProjectBackupError.measurementCorrupted,
        );
      }
    }

    for (final asset in data.benchmarkPhotoAssets) {
      if (!benchmarkIds.contains(asset.benchmarkId) ||
          asset.relativePath.trim().isEmpty ||
          !_isSafeBackupRelativePath(asset.relativePath) ||
          asset.contentBase64.trim().isEmpty) {
        throw const ProjectBackupException.of(
          ProjectBackupError.photoCorrupted,
        );
      }
      try {
        base64Decode(asset.contentBase64);
      } on FormatException {
        throw const ProjectBackupException.of(
          ProjectBackupError.photoCorrupted,
        );
      }
    }
  }

  static bool _isSafeBackupRelativePath(String path) {
    if (path.trim().isEmpty) return false;
    if (p.posix.isAbsolute(path) || p.windows.isAbsolute(path)) return false;
    final normalized = path.replaceAll('\\', p.separator);
    final segments = p.split(normalized).where((segment) => segment.isNotEmpty);
    return !segments.contains('..');
  }

  static FieldBook _copyFieldBookForRestore(
    FieldBook fieldBook, {
    required int projectId,
    required int? startBmId,
    required int? closingBmId,
  }) {
    return FieldBook(
      projectId: projectId,
      title: fieldBook.title,
      date: fieldBook.date,
      startBmId: startBmId,
      startElevation: fieldBook.startElevation,
      // Older backups have no closing fields: restored as none.
      // The closing RL snapshot survives a closing BM missing from the backup.
      closingMode: fieldBook.closingMode,
      closingBmId: closingBmId,
      closingElevation: fieldBook.closingElevation,
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
    );
  }
}
