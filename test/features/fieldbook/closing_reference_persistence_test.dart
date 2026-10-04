import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/constants/app_constants.dart';
import 'package:lv_book/core/database/database_helper.dart';
import 'package:lv_book/features/backup/project_backup_service.dart';
import 'package:lv_book/features/benchmark/data/benchmark_repository.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_validation.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/project/data/sample_project_service.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:lv_book/features/settings/misclosure_tolerance_repository.dart';
import 'package:lv_book/l10n/l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  final helper = DatabaseHelper.instance;
  late Database db;

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

  Future<int> insertProject() => db.insert('projects', {
    'name': 'P',
    'created_at': '2026-01-01T00:00:00.000',
    'updated_at': '2026-01-01T00:00:00.000',
  });

  test('v8 → v9 migration adds the closing columns and keeps data', () async {
    expect(AppConstants.dbVersion, greaterThanOrEqualTo(9));
    final dir = await Directory.systemTemp.createTemp('lvbook_v8');
    final path = '${dir.path}/v8.db';
    try {
      // Exactly the v8 field_books schema (no closing columns).
      var legacy = await databaseFactoryFfi.openDatabase(path);
      await legacy.execute('''
        CREATE TABLE projects (id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL, description TEXT, created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL)''');
      await legacy.execute(
        '''
        CREATE TABLE benchmarks (id INTEGER PRIMARY KEY AUTOINCREMENT,
          project_id INTEGER NOT NULL, name TEXT NOT NULL,
          elevation REAL NOT NULL, description TEXT, location_hint TEXT,
          protection_note TEXT, last_verified_at TEXT,
          status TEXT NOT NULL DEFAULT 'available',
          kind TEXT NOT NULL DEFAULT 'bm', photo_path TEXT, latitude REAL,
          longitude REAL, coordinate_accuracy_m REAL,
          coordinate_captured_at TEXT,
          FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE)''',
      );
      await legacy.execute(
        '''
        CREATE TABLE field_books (id INTEGER PRIMARY KEY AUTOINCREMENT,
          project_id INTEGER NOT NULL, title TEXT NOT NULL, date TEXT NOT NULL,
          start_bm_id INTEGER, start_elevation REAL, memo TEXT, surveyor TEXT,
          checker TEXT, instrument TEXT, weather TEXT, work_section TEXT,
          job_number TEXT, review_status TEXT NOT NULL DEFAULT 'draft',
          review_memo TEXT, reviewed_at TEXT, created_at TEXT NOT NULL,
          FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE,
          FOREIGN KEY (start_bm_id) REFERENCES benchmarks (id) ON DELETE SET NULL)''',
      );
      await legacy.execute(
        '''
        CREATE TABLE measurements (id INTEGER PRIMARY KEY AUTOINCREMENT,
          field_book_id INTEGER NOT NULL, order_index INTEGER NOT NULL,
          station_name TEXT NOT NULL, type TEXT NOT NULL DEFAULT 'normal',
          bs REAL, fs REAL, ih REAL, gh REAL,
          manual_tp INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (field_book_id) REFERENCES field_books (id) ON DELETE CASCADE)''',
      );
      await legacy.execute(
        'CREATE TABLE app_settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      await legacy.execute('''
        CREATE TABLE quick_memos (id INTEGER PRIMARY KEY AUTOINCREMENT,
          text TEXT, audio_path TEXT, created_at TEXT NOT NULL)''');
      final projectId = await legacy.insert('projects', {
        'name': 'Old',
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });
      final bmId = await legacy.insert('benchmarks', {
        'project_id': projectId,
        'name': 'BM-1',
        'elevation': 100.0,
      });
      final bookId = await legacy.insert('field_books', {
        'project_id': projectId,
        'title': 'Old book',
        'date': '2026-01-01T00:00:00.000',
        'start_bm_id': bmId,
        'start_elevation': 100.0,
        'surveyor': 'Kim',
        'created_at': '2026-01-01T00:00:00.000',
      });
      await legacy.insert('measurements', {
        'field_book_id': bookId,
        'order_index': 0,
        'station_name': 'BM-1',
        'bs': 1.5,
      });
      await legacy.execute('PRAGMA user_version = 8');
      await legacy.close();

      legacy = await databaseFactoryFfi.openDatabase(
        path,
        options: helper.openDatabaseOptions(),
      );
      helper.setDatabaseForTesting(legacy);
      expect(await legacy.getVersion(), AppConstants.dbVersion);

      final book = (await FieldBookRepository().getById(bookId))!;
      expect(book.title, 'Old book');
      expect(book.startBmId, bmId);
      expect(book.startElevation, 100.0);
      expect(book.surveyor, 'Kim');
      expect(book.closingMode, ClosingReferenceMode.none);
      expect(book.closingBmId, isNull);
      expect(book.closingElevation, isNull);
      expect(await legacy.query('measurements'), hasLength(1));

      // The migrated closing_bm_id is a real FK with ON DELETE SET NULL.
      await FieldBookRepository().updateClosingReference(
        book.copyWith(
          closingMode: ClosingReferenceMode.benchmark,
          closingBmId: bmId,
          closingElevation: 100.0,
        ),
      );
      await legacy.delete('benchmarks', where: 'id = ?', whereArgs: [bmId]);
      final after = (await FieldBookRepository().getById(bookId))!;
      expect(after.closingBmId, isNull);
      expect(after.closingElevation, 100.0);
      await legacy.close();
    } finally {
      helper.setDatabaseForTesting(db);
      await dir.delete(recursive: true);
    }
  });

  test(
    'closing reference persists; deleting the BM keeps the snapshot',
    () async {
      final projectId = await insertProject();
      final bmId = await BenchMarkRepository().create(
        BenchMark(projectId: projectId, name: 'BM-2', elevation: 101.25),
      );
      final repo = FieldBookRepository();
      final id = await repo.create(
        FieldBook(
          projectId: projectId,
          title: 'F',
          date: DateTime(2026, 1, 1),
          startElevation: 100,
          closingMode: ClosingReferenceMode.benchmark,
          closingBmId: bmId,
          closingElevation: 101.25,
        ),
      );
      var book = (await repo.getById(id))!;
      expect(book.closingMode, ClosingReferenceMode.benchmark);
      expect(book.closingBmId, bmId);
      expect(book.closingElevation, 101.25);

      // A later BM edit does not change the book's closing RL.
      await BenchMarkRepository().update(
        BenchMark(id: bmId, projectId: projectId, name: 'BM-2', elevation: 99),
      );
      expect((await repo.getById(id))!.closingElevationFor(100), 101.25);

      await BenchMarkRepository().delete(bmId);
      book = (await repo.getById(id))!;
      expect(book.closingBmId, isNull);
      expect(book.closingElevationFor(100), 101.25);

      await repo.updateClosingReference(
        book.copyWith(
          closingMode: ClosingReferenceMode.loop,
          closingBmId: null,
          closingElevation: null,
        ),
      );
      book = (await repo.getById(id))!;
      expect(book.closingMode, ClosingReferenceMode.loop);
      expect(book.closingElevation, isNull);
      expect(book.closingElevationFor(100), 100);
    },
  );

  group('tolerance setting', () {
    test('defaults to fixed 1 mm and round trips both modes', () async {
      final repo = MisclosureToleranceRepository();
      expect(await repo.load(), MisclosureTolerance.defaults);

      await repo.save(const MisclosureTolerance.sqrtSetups(5));
      final loaded = await repo.load();
      expect(loaded.mode, MisclosureToleranceMode.sqrtSetups);
      expect(loaded.coefficientMm, 5);
      expect(loaded.allowed(4), closeTo(0.010, 1e-12));

      await repo.save(
        const MisclosureTolerance(
          mode: MisclosureToleranceMode.fixed,
          fixedMm: 2.5,
          coefficientMm: 5,
        ),
      );
      expect((await repo.load()).allowed(9), closeTo(0.0025, 1e-12));
    });

    test('rejects invalid values and ignores corrupt stored ones', () async {
      final repo = MisclosureToleranceRepository();
      expect(
        () => repo.save(const MisclosureTolerance.fixed(0)),
        throwsArgumentError,
      );
      expect(
        () => repo.save(const MisclosureTolerance.sqrtSetups(1000)),
        throwsArgumentError,
      );
      await db.insert('app_settings', {
        'key': MisclosureToleranceRepository.modeKey,
        'value': 'bogus',
      });
      await db.insert('app_settings', {
        'key': MisclosureToleranceRepository.fixedMmKey,
        'value': '-3',
      });
      expect(await repo.load(), MisclosureTolerance.defaults);
    });
  });

  group('backup', () {
    ProjectBackupData data() => ProjectBackupData(
      project: Project(id: 1, name: 'Backup'),
      benchmarks: [
        BenchMark(id: 10, projectId: 1, name: 'BM-1', elevation: 100),
        BenchMark(id: 11, projectId: 1, name: 'BM-2', elevation: 101.5),
      ],
      fieldBooks: [
        FieldBook(
          id: 20,
          projectId: 1,
          title: 'To BM-2',
          date: DateTime(2026, 1, 1),
          startBmId: 10,
          startElevation: 100,
          closingMode: ClosingReferenceMode.benchmark,
          closingBmId: 11,
          closingElevation: 101.5,
        ),
        FieldBook(
          id: 21,
          projectId: 1,
          title: 'Loop',
          date: DateTime(2026, 1, 2),
          startBmId: 10,
          startElevation: 100,
          closingMode: ClosingReferenceMode.loop,
        ),
        FieldBook(
          id: 22,
          projectId: 1,
          title: 'Manual, BM gone',
          date: DateTime(2026, 1, 3),
          startElevation: 100,
          closingMode: ClosingReferenceMode.benchmark,
          closingBmId: 99,
          closingElevation: 98.765,
        ),
      ],
      measurements: [
        Measurement(fieldBookId: 21, orderIndex: 0, stationName: 'BM-1', bs: 1),
      ],
    );

    test('round trip keeps and remaps the closing reference', () async {
      final source = ProjectBackupService.encode(data());
      final json = jsonDecode(source) as Map<String, dynamic>;
      final first = (json['field_books'] as List).first as Map;
      expect(first['closing_mode'], 'benchmark');
      expect(first['closing_bm_id'], 11);
      expect(first['closing_elevation'], 101.5);

      final result = await ProjectBackupService().restoreAsNewProject(source);
      final books = await FieldBookRepository().getByProjectId(
        result.projectId,
      );
      final byTitle = {for (final book in books) book.title: book};

      final toBm2 = byTitle['To BM-2']!;
      expect(toBm2.closingMode, ClosingReferenceMode.benchmark);
      expect(toBm2.closingBmId, result.benchmarkIdMap[11]);
      expect(toBm2.closingElevation, 101.5);

      expect(byTitle['Loop']!.closingMode, ClosingReferenceMode.loop);

      final gone = byTitle['Manual, BM gone']!;
      expect(gone.closingBmId, isNull);
      expect(gone.closingElevationFor(100), 98.765);
    });

    test('an old backup without closing fields still restores', () async {
      final json =
          jsonDecode(ProjectBackupService.encode(data()))
              as Map<String, dynamic>;
      for (final book in json['field_books'] as List) {
        (book as Map)
          ..remove('closing_mode')
          ..remove('closing_bm_id')
          ..remove('closing_elevation');
      }
      final decoded = ProjectBackupService.decode(jsonEncode(json));
      expect(decoded.fieldBooks.map((book) => book.closingMode).toSet(), {
        ClosingReferenceMode.none,
      });

      final result = await ProjectBackupService().restoreAsNewProject(
        jsonEncode(json),
      );
      final books = await FieldBookRepository().getByProjectId(
        result.projectId,
      );
      expect(books, hasLength(3));
      for (final book in books) {
        expect(book.closingMode, ClosingReferenceMode.none);
        expect(book.closingBmId, isNull);
        expect(book.closingElevation, isNull);
      }
    });
  });

  test(
    'sample project closes on its start BM: +0.0010, within tolerance',
    () async {
      final project = await SampleProjectService().createSampleProject(
        l10n: l10nFor(const Locale('en')),
      );
      final book = (await FieldBookRepository().getByProjectId(
        project.id!,
      )).single;
      expect(book.closingMode, ClosingReferenceMode.loop);

      final rows = await db.query(
        'measurements',
        where: 'field_book_id = ?',
        whereArgs: [book.id],
        orderBy: 'order_index',
      );
      final measurements = rows.map(Measurement.fromMap).toList();
      final result = MeasurementValidation.validate(
        measurements: measurements,
        startElevation: book.startElevation!,
        closingElevation: book.closingElevationFor(book.startElevation!),
      );
      expect(formatMisclosure(result.misclosure!), '+0.0010');
      expect(result.closure!.allowed, 0.001);
      expect(result.canExport, isTrue);
      expect(result.arithmeticError, closeTo(0, 1e-9));
    },
  );
}
