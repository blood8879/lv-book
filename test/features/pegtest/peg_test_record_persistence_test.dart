import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/constants/app_constants.dart';
import 'package:lv_book/core/database/database_helper.dart';
import 'package:lv_book/features/backup/project_backup_service.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/pegtest/data/peg_test_record_repository.dart';
import 'package:lv_book/features/pegtest/domain/peg_test_record.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  final helper = DatabaseHelper.instance;
  late Database db;
  late PegTestRecordRepository repo;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: helper.openDatabaseOptions(),
    );
    helper.setDatabaseForTesting(db);
    repo = PegTestRecordRepository(databaseProvider: () async => db);
  });

  tearDown(() async {
    helper.setDatabaseForTesting(null);
    await db.close();
  });

  PegTestRecord record({
    DateTime? createdAt,
    String? instrument = 'DL-500',
    String? observer = 'Kim',
    double b2 = 1.120,
    LengthUnit unit = LengthUnit.metres,
    String? note,
  }) => PegTestRecord(
    createdAt: createdAt ?? DateTime(2026, 10, 15, 9, 30),
    instrument: instrument,
    observer: observer,
    unit: unit,
    a1: 1.525,
    b1: 1.230,
    a2: 1.410,
    b2: b2,
    pegDistance: 40,
    toleranceEntry: 3,
    note: note,
  );

  group('repository', () {
    test('create, list newest first, get and delete', () async {
      final older = await repo.create(
        record(createdAt: DateTime(2026, 10, 1), note: '  '),
      );
      final newer = await repo.create(
        record(
          createdAt: DateTime(2026, 10, 14, 8),
          instrument: ' ',
          observer: null,
          b2: 1.117,
          note: 'After adjustment',
        ),
      );

      final list = await repo.list();
      expect(list.map((r) => r.id), [newer, older]);
      final latest = list.first;
      expect(latest.instrument, isNull); // blank → null
      expect(latest.observer, isNull);
      expect(latest.note, 'After adjustment');
      expect(latest.test.withinTolerance, isTrue);
      expect(list.last.note, isNull);
      expect(list.last.test.error, closeTo(0.005, 1e-9));
      expect(list.last.test.withinTolerance, isFalse);

      final loaded = (await repo.getById(older))!;
      expect(loaded.createdAt, DateTime(2026, 10, 1));
      expect(loaded.unit, LengthUnit.metres);
      expect(loaded.instrument, 'DL-500');
      expect(loaded.pegDistance, 40);
      expect(loaded.toleranceEntry, 3);

      expect(await repo.delete(older), 1);
      expect((await repo.list()).map((r) => r.id), [newer]);
      expect(await repo.getById(older), isNull);
    });

    test('feet records keep their unit', () async {
      final id = await repo.create(record(unit: LengthUnit.feet));
      expect((await repo.getById(id))!.unit, LengthUnit.feet);
    });

    test('lastMetadata: latest record, else latest field book', () async {
      expect(await repo.lastMetadata(), (instrument: null, observer: null));

      final projectId = await db.insert('projects', {
        'name': 'P',
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });
      Future<void> book(String createdAt, String? instrument, String? who) =>
          db.insert('field_books', {
            'project_id': projectId,
            'title': 'B',
            'date': createdAt,
            'instrument': instrument,
            'surveyor': who,
            'created_at': createdAt,
          });
      await book('2026-02-01T00:00:00.000', 'Old level', 'Lee');
      await book('2026-03-01T00:00:00.000', 'AT-B4', 'Park');
      await book('2026-04-01T00:00:00.000', '', null);
      expect(await repo.lastMetadata(), (
        instrument: 'AT-B4',
        observer: 'Park',
      ));

      await repo.create(record(instrument: 'DL-500 #77', observer: null));
      expect(await repo.lastMetadata(), (
        instrument: 'DL-500 #77',
        observer: 'Park',
      ));
    });

    test('fromMap rejects corrupt rows', () {
      final good = record().toMap();
      expect(PegTestRecord.fromMap(good).a1, 1.525);
      for (final broken in [
        {...good, 'a1': 'x'},
        {...good, 'peg_distance': 0},
        {...good, 'unit': 'yards'},
        {...good, 'created_at': 'yesterday'},
        {...good, 'instrument': 5},
      ]) {
        expect(() => PegTestRecord.fromMap(broken), throwsFormatException);
      }
    });
  });

  test('v10 → v11 migration adds peg_tests and keeps data', () async {
    expect(AppConstants.dbVersion, 11);
    final dir = await Directory.systemTemp.createTemp('lvbook_v10');
    final path = '${dir.path}/v10.db';
    try {
      var legacy = await databaseFactoryFfi.openDatabase(path);
      await legacy.execute('''
        CREATE TABLE projects (id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL, description TEXT, created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL)''');
      await legacy.execute('''
        CREATE TABLE benchmarks (id INTEGER PRIMARY KEY AUTOINCREMENT,
          project_id INTEGER NOT NULL, name TEXT NOT NULL,
          elevation REAL NOT NULL, description TEXT, location_hint TEXT,
          protection_note TEXT, last_verified_at TEXT,
          status TEXT NOT NULL DEFAULT 'available',
          kind TEXT NOT NULL DEFAULT 'bm', photo_path TEXT, latitude REAL,
          longitude REAL, coordinate_accuracy_m REAL,
          coordinate_captured_at TEXT)''');
      await legacy.execute('''
        CREATE TABLE field_books (id INTEGER PRIMARY KEY AUTOINCREMENT,
          project_id INTEGER NOT NULL, title TEXT NOT NULL, date TEXT NOT NULL,
          start_bm_id INTEGER, start_elevation REAL,
          closing_mode TEXT NOT NULL DEFAULT 'none', closing_bm_id INTEGER,
          closing_elevation REAL,
          reduction_method TEXT NOT NULL DEFAULT 'heightOfInstrument',
          memo TEXT, surveyor TEXT, checker TEXT, instrument TEXT,
          weather TEXT, work_section TEXT, job_number TEXT,
          review_status TEXT NOT NULL DEFAULT 'draft',
          review_memo TEXT, reviewed_at TEXT, created_at TEXT NOT NULL)''');
      await legacy.execute('''
        CREATE TABLE measurements (id INTEGER PRIMARY KEY AUTOINCREMENT,
          field_book_id INTEGER NOT NULL, order_index INTEGER NOT NULL,
          station_name TEXT NOT NULL, type TEXT NOT NULL DEFAULT 'normal',
          bs REAL, fs REAL, ih REAL, gh REAL,
          manual_tp INTEGER NOT NULL DEFAULT 0)''');
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
      await legacy.insert('field_books', {
        'project_id': projectId,
        'title': 'Old book',
        'date': '2026-01-01T00:00:00.000',
        'instrument': 'Legacy level',
        'surveyor': 'Choi',
        'created_at': '2026-01-01T00:00:00.000',
      });
      await legacy.insert('app_settings', {'key': 'k', 'value': 'v'});
      await legacy.execute('PRAGMA user_version = 10');
      await legacy.close();

      legacy = await databaseFactoryFfi.openDatabase(
        path,
        options: helper.openDatabaseOptions(),
      );
      expect(await legacy.getVersion(), 11);
      final columns = {
        for (final row in await legacy.rawQuery('PRAGMA table_info(peg_tests)'))
          row['name'] as String,
      };
      expect(columns, {
        'id',
        'created_at',
        'instrument',
        'observer',
        'unit',
        'a1',
        'b1',
        'a2',
        'b2',
        'peg_distance',
        'tolerance_entry',
        'note',
      });
      expect(await legacy.query('field_books'), hasLength(1));
      expect(await legacy.query('app_settings'), hasLength(1));

      final legacyRepo = PegTestRecordRepository(
        databaseProvider: () async => legacy,
      );
      expect(await legacyRepo.list(), isEmpty);
      // Quick reuse falls back to the old field book.
      expect(await legacyRepo.lastMetadata(), (
        instrument: 'Legacy level',
        observer: 'Choi',
      ));
      await legacyRepo.create(record());
      expect(await legacyRepo.list(), hasLength(1));
      await legacy.close();
    } finally {
      await dir.delete(recursive: true);
    }
  });

  group('backup', () {
    Future<int> seedProject() => db.insert('projects', {
      'name': 'Site',
      'created_at': '2026-01-01T00:00:00.000',
      'updated_at': '2026-01-01T00:00:00.000',
    });

    test('round trip carries peg tests; restoring twice adds none', () async {
      final projectId = await seedProject();
      await repo.create(record(note: 'Morning check'));
      await repo.create(
        record(
          createdAt: DateTime(2026, 10, 15, 16),
          b2: 1.117,
          unit: LengthUnit.feet,
          observer: null,
        ),
      );

      final service = ProjectBackupService();
      final source = ProjectBackupService.encode(
        await service.collectProject(projectId),
      );
      final json = jsonDecode(source) as Map<String, dynamic>;
      expect(json['version'], ProjectBackupService.version);
      expect(json['peg_tests'], hasLength(2));

      // Same device: identical records are not duplicated.
      final sameDevice = await service.restoreAsNewProject(source);
      expect(sameDevice.restoredPegTestCount, 0);
      expect(await repo.list(), hasLength(2));

      // New device: records come back with their values.
      await db.delete('peg_tests');
      final restored = await service.restoreAsNewProject(source);
      expect(restored.restoredPegTestCount, 2);
      final list = await repo.list();
      expect(list, hasLength(2));
      expect(list.first.createdAt, DateTime(2026, 10, 15, 16));
      expect(list.first.unit, LengthUnit.feet);
      expect(list.first.observer, isNull);
      expect(list.first.b2, 1.117);
      expect(list.last.note, 'Morning check');
      expect(list.last.instrument, 'DL-500');

      final again = await service.restoreAsNewProject(source);
      expect(again.restoredPegTestCount, 0);
      expect(await repo.list(), hasLength(2));
    });

    test('a backup without peg tests omits the key', () async {
      final projectId = await seedProject();
      final json =
          jsonDecode(
                ProjectBackupService.encode(
                  await ProjectBackupService().collectProject(projectId),
                ),
              )
              as Map<String, dynamic>;
      expect(json.containsKey('peg_tests'), isFalse);
    });

    test('an older backup without peg_tests still restores', () async {
      final source = ProjectBackupService.encode(
        ProjectBackupData(
          project: Project(id: 1, name: 'Old backup'),
          benchmarks: const [],
          fieldBooks: const [],
          measurements: const [],
        ),
      );
      expect(source, isNot(contains('peg_tests')));
      final result = await ProjectBackupService().restoreAsNewProject(source);
      expect(result.restoredPegTestCount, 0);
      expect(await repo.list(), isEmpty);
      expect(
        await db.query(
          'projects',
          where: 'id = ?',
          whereArgs: [result.projectId],
        ),
        hasLength(1),
      );
    });

    test('corrupt peg tests make the backup corrupted', () {
      final json =
          jsonDecode(
                ProjectBackupService.encode(
                  ProjectBackupData(
                    project: Project(id: 1, name: 'P'),
                    benchmarks: const [],
                    fieldBooks: const [],
                    measurements: const [],
                    pegTests: [record()],
                  ),
                ),
              )
              as Map<String, dynamic>;
      Matcher corrupted() => throwsA(
        isA<ProjectBackupException>().having(
          (e) => e.error,
          'error',
          ProjectBackupError.corrupted,
        ),
      );

      final notList = {...json, 'peg_tests': 'x'};
      expect(
        () => ProjectBackupService.decode(jsonEncode(notList)),
        corrupted(),
      );
      final badRow = {
        ...json,
        'peg_tests': [
          {...(json['peg_tests'] as List).first as Map, 'a1': null},
        ],
      };
      expect(
        () => ProjectBackupService.decode(jsonEncode(badRow)),
        corrupted(),
      );
    });
  });
}
