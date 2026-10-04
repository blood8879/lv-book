import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/constants/app_constants.dart';
import 'package:lv_book/core/database/database_helper.dart';
import 'package:lv_book/features/backup/project_backup_service.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook_templates.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/fieldbook/domain/reduction.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:lv_book/features/settings/misclosure_tolerance_repository.dart';
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

  test('v9 → v10 migration adds reduction_method (HI) and keeps data', () async {
    expect(AppConstants.dbVersion, 10);
    final dir = await Directory.systemTemp.createTemp('lvbook_v9');
    final path = '${dir.path}/v9.db';
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
      // Exactly the v9 field_books schema (closing columns, no method).
      await legacy.execute('''
        CREATE TABLE field_books (id INTEGER PRIMARY KEY AUTOINCREMENT,
          project_id INTEGER NOT NULL, title TEXT NOT NULL, date TEXT NOT NULL,
          start_bm_id INTEGER, start_elevation REAL,
          closing_mode TEXT NOT NULL DEFAULT 'none', closing_bm_id INTEGER,
          closing_elevation REAL, memo TEXT, surveyor TEXT,
          checker TEXT, instrument TEXT, weather TEXT, work_section TEXT,
          job_number TEXT, review_status TEXT NOT NULL DEFAULT 'draft',
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
      final bookId = await legacy.insert('field_books', {
        'project_id': projectId,
        'title': 'Old book',
        'date': '2026-01-01T00:00:00.000',
        'start_elevation': 100.0,
        'closing_mode': 'loop',
        'created_at': '2026-01-01T00:00:00.000',
      });
      await legacy.execute('PRAGMA user_version = 9');
      await legacy.close();

      legacy = await databaseFactoryFfi.openDatabase(
        path,
        options: helper.openDatabaseOptions(),
      );
      helper.setDatabaseForTesting(legacy);
      expect(await legacy.getVersion(), 10);

      final repo = FieldBookRepository();
      final book = (await repo.getById(bookId))!;
      expect(book.title, 'Old book');
      expect(book.closingMode, ClosingReferenceMode.loop);
      expect(book.reductionMethod, ReductionMethod.heightOfInstrument);

      await repo.updateReductionMethod(
        book.copyWith(
          reductionMethod: ReductionMethod.riseAndFall,
          title: 'not saved',
        ),
      );
      final updated = (await repo.getById(bookId))!;
      expect(updated.reductionMethod, ReductionMethod.riseAndFall);
      expect(updated.title, 'Old book'); // only the method column is written
      await legacy.close();
    } finally {
      helper.setDatabaseForTesting(db);
      await dir.delete(recursive: true);
    }
  });

  test('fresh database stores the method', () async {
    final projectId = await db.insert('projects', {
      'name': 'P',
      'created_at': '2026-01-01T00:00:00.000',
      'updated_at': '2026-01-01T00:00:00.000',
    });
    final repo = FieldBookRepository();
    final id = await repo.create(
      FieldBook(
        projectId: projectId,
        title: 'R&F',
        date: DateTime(2026, 10, 5),
        reductionMethod: ReductionMethod.riseAndFall,
      ),
    );
    final book = (await repo.getById(id))!;
    expect(book.reductionMethod, ReductionMethod.riseAndFall);
    final copy = FieldBookTemplates.duplicateStructure(
      source: book,
      measurements: const [],
      newDate: DateTime(2026, 10, 6),
    );
    expect(copy.fieldBook.reductionMethod, ReductionMethod.riseAndFall);
  });

  group('backup', () {
    ProjectBackupData data() => ProjectBackupData(
      project: Project(id: 1, name: 'Backup'),
      benchmarks: const [],
      fieldBooks: [
        FieldBook(
          id: 20,
          projectId: 1,
          title: 'R&F',
          date: DateTime(2026, 1, 1),
          startElevation: 100,
          reductionMethod: ReductionMethod.riseAndFall,
        ),
        FieldBook(
          id: 21,
          projectId: 1,
          title: 'HI',
          date: DateTime(2026, 1, 2),
          startElevation: 100,
        ),
      ],
      measurements: [
        Measurement(fieldBookId: 20, orderIndex: 0, stationName: 'BM', bs: 1),
      ],
    );

    Future<Map<String, FieldBook>> restore(String source) async {
      final result = await ProjectBackupService().restoreAsNewProject(source);
      final books = await FieldBookRepository().getByProjectId(
        result.projectId,
      );
      return {for (final book in books) book.title: book};
    }

    test('round trip keeps the reduction method', () async {
      final source = ProjectBackupService.encode(data());
      final json = jsonDecode(source) as Map<String, dynamic>;
      expect(
        ((json['field_books'] as List).first as Map)['reduction_method'],
        'riseAndFall',
      );
      final books = await restore(source);
      expect(books['R&F']!.reductionMethod, ReductionMethod.riseAndFall);
      expect(books['HI']!.reductionMethod, ReductionMethod.heightOfInstrument);
    });

    test('an old backup without the method restores as HI', () async {
      final json =
          jsonDecode(ProjectBackupService.encode(data()))
              as Map<String, dynamic>;
      for (final book in json['field_books'] as List) {
        (book as Map).remove('reduction_method');
      }
      final books = await restore(jsonEncode(json));
      expect(books.values.map((book) => book.reductionMethod).toSet(), {
        ReductionMethod.heightOfInstrument,
      });
    });
  });

  group('unit setting', () {
    test(
      'defaults to metres; saves and loads feet with ft allowances',
      () async {
        final repo = MisclosureToleranceRepository();
        expect((await repo.load()).unit, LengthUnit.metres);

        const feet = MisclosureTolerance(
          unit: LengthUnit.feet,
          mode: MisclosureToleranceMode.sqrtSetups,
          coefficientFt: 0.03,
        );
        await repo.save(feet);
        final loaded = await repo.load();
        expect(loaded, feet);
        expect(loaded.allowed(4), closeTo(0.06, 1e-12));
        // Switching back to metres keeps the mm values.
        expect(loaded.copyWith(unit: LengthUnit.metres).allowed(4), 0.010);
      },
    );

    test('invalid stored ft values fall back to the defaults', () async {
      await db.insert('app_settings', {
        'key': MisclosureToleranceRepository.unitKey,
        'value': 'feet',
      });
      await db.insert('app_settings', {
        'key': MisclosureToleranceRepository.fixedFtKey,
        'value': '7',
      });
      final loaded = await MisclosureToleranceRepository().load();
      expect(loaded.unit, LengthUnit.feet);
      expect(loaded.fixedFt, MisclosureTolerance.defaultFixedFt);
      expect(
        () => MisclosureToleranceRepository().save(
          const MisclosureTolerance(fixedFt: 9),
        ),
        throwsArgumentError,
      );
    });
  });
}
