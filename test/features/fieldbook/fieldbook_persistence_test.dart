import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/database/database_helper.dart';
import 'package:lv_book/features/backup/project_backup_service.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_repository.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/project/data/project_repository.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  final helper = DatabaseHelper.instance;
  late Database db;

  Future<int> insertProject(Database db) {
    return db.insert('projects', {
      'name': 'P',
      'created_at': '2026-01-01T00:00:00.000',
      'updated_at': '2026-01-01T00:00:00.000',
    });
  }

  Future<int> insertFieldBook(Database db, int projectId, {int? startBmId}) {
    return db.insert('field_books', {
      'project_id': projectId,
      'title': 'F',
      'date': '2026-01-01T00:00:00.000',
      'start_bm_id': startBmId,
      'created_at': '2026-01-01T00:00:00.000',
    });
  }

  Future<int> insertBenchmark(Database db, int projectId) {
    return db.insert('benchmarks', {
      'project_id': projectId,
      'name': 'BM1',
      'elevation': 10.0,
    });
  }

  Future<int> insertMeasurement(Database db, int fieldBookId) {
    return db.insert('measurements', {
      'field_book_id': fieldBookId,
      'order_index': 0,
      'station_name': 'No.1',
    });
  }

  Future<int> count(Database db, String table) async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return rows.first['c'] as int;
  }

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: helper.openDatabaseOptions(),
    );
    helper.setDatabaseForTesting(db);
  });

  tearDown(() async {
    helper.setDatabaseForTesting(null);
    await db.close();
  });

  group('MeasurementRepository.replaceForFieldBook', () {
    test('two concurrent saves never leave duplicate rows', () async {
      final projectId = await insertProject(db);
      final fieldBookId = await insertFieldBook(db, projectId);
      final repo = MeasurementRepository();

      List<Measurement> rows(String prefix, int n) => [
        for (var i = 0; i < n; i++)
          Measurement(
            fieldBookId: fieldBookId,
            orderIndex: i,
            stationName: '$prefix$i',
            bs: 1,
          ),
      ];

      await Future.wait([
        repo.replaceForFieldBook(fieldBookId, rows('A', 5)),
        repo.replaceForFieldBook(fieldBookId, rows('B', 3)),
        repo.replaceForFieldBook(fieldBookId, rows('C', 4)),
      ]);

      final saved = await repo.getByFieldBookId(fieldBookId);
      expect(saved.map((m) => m.stationName).toList(), [
        'C0',
        'C1',
        'C2',
        'C3',
      ]);
    });

    test('persists station-only rows and start elevation', () async {
      final projectId = await insertProject(db);
      final fieldBookId = await insertFieldBook(db, projectId);
      final repo = MeasurementRepository();

      await repo.replaceForFieldBook(fieldBookId, [
        Measurement(
          fieldBookId: fieldBookId,
          orderIndex: 0,
          stationName: 'BM.1',
          bs: 1.2,
        ),
        Measurement(fieldBookId: fieldBookId, orderIndex: 1, stationName: 'No.1'),
        Measurement(fieldBookId: fieldBookId, orderIndex: 2, stationName: 'No.2'),
      ], startElevation: 12.345);

      final saved = await repo.getByFieldBookId(fieldBookId);
      expect(saved.map((m) => m.stationName).toList(), [
        'BM.1',
        'No.1',
        'No.2',
      ]);
      expect(saved[1].bs, isNull);
      expect(saved[1].fs, isNull);

      final fieldBook = await FieldBookRepository().getById(fieldBookId);
      expect(fieldBook!.startElevation, 12.345);
    });
  });

  group('foreign keys', () {
    test('deleting a project row cascades to field books and measurements',
        () async {
      final projectId = await insertProject(db);
      final bmId = await insertBenchmark(db, projectId);
      final fieldBookId = await insertFieldBook(
        db,
        projectId,
        startBmId: bmId,
      );
      await insertMeasurement(db, fieldBookId);

      // Raw delete: relies on PRAGMA foreign_keys = ON.
      await db.delete('projects', where: 'id = ?', whereArgs: [projectId]);

      expect(await count(db, 'benchmarks'), 0);
      expect(await count(db, 'field_books'), 0);
      expect(await count(db, 'measurements'), 0);
    });

    test('ProjectRepository.delete removes all project data', () async {
      final projectId = await insertProject(db);
      final otherProjectId = await insertProject(db);
      final fieldBookId = await insertFieldBook(db, projectId);
      final otherFieldBookId = await insertFieldBook(db, otherProjectId);
      await insertMeasurement(db, fieldBookId);
      await insertMeasurement(db, otherFieldBookId);

      await ProjectRepository().delete(projectId);

      expect(await count(db, 'field_books'), 1);
      expect(await count(db, 'measurements'), 1);
      expect(await FieldBookRepository().getMostRecent(), isNotNull);
    });

    test('deleting a benchmark nulls start_bm_id', () async {
      final projectId = await insertProject(db);
      final bmId = await insertBenchmark(db, projectId);
      final fieldBookId = await insertFieldBook(
        db,
        projectId,
        startBmId: bmId,
      );

      await db.delete('benchmarks', where: 'id = ?', whereArgs: [bmId]);

      final fieldBook = await FieldBookRepository().getById(fieldBookId);
      expect(fieldBook!.startBmId, isNull);
    });
  });

  test('v8 migration removes orphan rows left by older versions', () async {
    final dir = await Directory.systemTemp.createTemp('lvbook_migration');
    final path = '${dir.path}/legacy.db';
    try {
      var legacy = await databaseFactoryFfi.openDatabase(
        path,
        options: helper.openDatabaseOptions(),
      );
      await legacy.execute('PRAGMA foreign_keys = OFF');
      final projectId = await insertProject(legacy);
      final liveBmId = await insertBenchmark(legacy, projectId);
      final liveFieldBookId = await insertFieldBook(
        legacy,
        projectId,
        startBmId: 999, // dangling BM reference
      );
      await insertMeasurement(legacy, liveFieldBookId);
      final orphanFieldBookId = await insertFieldBook(legacy, 777);
      await insertMeasurement(legacy, orphanFieldBookId);
      await insertMeasurement(legacy, 555);
      await insertBenchmark(legacy, 777);
      await legacy.execute('PRAGMA user_version = 7');
      await legacy.close();

      legacy = await databaseFactoryFfi.openDatabase(
        path,
        options: helper.openDatabaseOptions(),
      );
      helper.setDatabaseForTesting(legacy);

      final books = await legacy.query('field_books');
      expect(books.map((row) => row['id']), [liveFieldBookId]);
      expect(books.single['start_bm_id'], isNull);
      final measurements = await legacy.query('measurements');
      expect(measurements.map((row) => row['field_book_id']), [
        liveFieldBookId,
      ]);
      final benchmarks = await legacy.query('benchmarks');
      expect(benchmarks.map((row) => row['id']), [liveBmId]);
      final mostRecent = await FieldBookRepository().getMostRecent();
      expect(mostRecent!.id, liveFieldBookId);
      await legacy.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('backup restore remaps a missing start BM to null', () async {
    final source = ProjectBackupService.encode(
      ProjectBackupData(
        project: Project(id: 1, name: '복원 프로젝트'),
        benchmarks: [
          BenchMark(id: 10, projectId: 1, name: 'BM.1', elevation: 50),
        ],
        fieldBooks: [
          FieldBook(
            id: 20,
            projectId: 1,
            title: '정상 야장',
            date: DateTime(2026, 1, 1),
            startBmId: 10,
          ),
          FieldBook(
            id: 21,
            projectId: 1,
            title: '시작 BM 삭제된 야장',
            date: DateTime(2026, 1, 2),
            startBmId: 99,
          ),
        ],
        measurements: [
          Measurement(fieldBookId: 21, orderIndex: 0, stationName: 'No.1', bs: 1),
        ],
      ),
    );

    final result = await ProjectBackupService().restoreAsNewProject(source);

    final books = await FieldBookRepository().getByProjectId(result.projectId);
    final byTitle = {for (final book in books) book.title: book};
    expect(byTitle['정상 야장']!.startBmId, result.benchmarkIdMap[10]);
    expect(byTitle['시작 BM 삭제된 야장']!.startBmId, isNull);
    final restored = await MeasurementRepository().getByFieldBookId(
      result.fieldBookIdMap[21]!,
    );
    expect(restored.single.stationName, 'No.1');
  });
}
