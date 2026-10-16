import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/constants/app_constants.dart';
import 'package:lv_book/core/database/database_helper.dart';
import 'package:lv_book/features/backup/project_backup_service.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/export/pdf_template.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_repository.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/design_level.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook_templates.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/fieldbook/domain/reduction.dart';
import 'package:lv_book/features/import/csv_importer.dart';
import 'package:lv_book/features/project/data/sample_project_service.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:lv_book/l10n/l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  final en = l10nFor(const Locale('en'));
  final ko = l10nKo;

  /// Sample run (RLs 100.000 / 100.552 / 100.224 / 100.059 / 100.147 /
  /// 100.001) with design levels on No.1 (cut 0.125) and No.2 (fill 0.040).
  List<Measurement> withDesign() {
    final rows = SampleProjectService.buildMeasurements(fieldBookId: 1);
    return [
      for (final m in rows)
        m.stationName == 'No.1'
            ? m.copyWith(designLevel: 100.099)
            : m.stationName == 'No.2'
            ? m.copyWith(designLevel: 100.187)
            : m,
    ];
  }

  FieldBook book({bool show = true}) => FieldBook(
    id: 1,
    projectId: 1,
    title: 'Formation',
    date: DateTime(2026, 10, 15),
    startElevation: 100,
    showDesignLevel: show,
  );

  group('stakeout target reading', () {
    test('HI in effect − design; rows after a TP use the new HI', () {
      // Sample: HI 101.425 (BM-1), 102.164 after TP-1, 101.397 after TP-2.
      final targets = stakeoutTargetsOf(withDesign());
      expect(targets[2], closeTo(102.164 - 100.099, 1e-9)); // No.1: 2.065
      expect(targets[4], closeTo(101.397 - 100.187, 1e-9)); // No.2: 1.210
      // Same as the reading that would show cut/fill 0: FS + cut/fill.
      expect(targets[2], closeTo(1.94 + 0.125, 1e-9));
      // Rows without a design level get none.
      expect(
        [targets[0], targets[1], targets[3], targets[5]],
        [null, null, null, null],
      );
    });

    test('setup HI comes from RL + BS; TP rows start the new setup', () {
      final heights = setupHeightsOf([
        (bs: null, rl: null), // before the first BS
        (bs: 1.5, rl: 100.0), // BM: HI 101.5
        (bs: null, rl: 100.3), // IS
        (bs: 1.2, rl: 100.5), // TP: HI 101.7
        (bs: null, rl: null), // no reading yet
        (bs: 0.9, rl: null), // BS the reduction ignores
      ]);
      expect(heights[0], isNull);
      expect(heights[1], closeTo(101.5, 1e-9));
      expect(heights[2], closeTo(101.5, 1e-9));
      expect(heights[3], closeTo(101.7, 1e-9));
      expect(heights[4], closeTo(101.7, 1e-9));
      expect(heights[5], closeTo(101.7, 1e-9));
    });

    test('an IS row with no FS still gets a target (stakeout)', () {
      final rows = [
        Measurement(
          fieldBookId: 1,
          orderIndex: 0,
          stationName: 'BM',
          bs: 1.5,
          ih: 101.5,
          gh: 100,
        ),
        // Design entered ahead of the reading: no FS, no RL.
        Measurement(
          fieldBookId: 1,
          orderIndex: 1,
          stationName: 'P1',
          designLevel: 100.25,
        ),
      ];
      final targets = stakeoutTargetsOf(rows);
      expect(targets.first, isNull);
      expect(targets.last, closeTo(1.25, 1e-9));
    });

    test('a design level before any HI gets none', () {
      final rows = [
        Measurement(
          fieldBookId: 1,
          orderIndex: 0,
          stationName: 'P0',
          designLevel: 100,
        ),
        Measurement(
          fieldBookId: 1,
          orderIndex: 1,
          stationName: 'BM',
          bs: 1.5,
          gh: 100,
        ),
      ];
      expect(stakeoutTargetsOf(rows), [null, null]);
      expect(stakeoutTargetOf(hi: null, design: 100), isNull);
      expect(stakeoutTargetOf(hi: 101.5, design: null), isNull);
    });

    test('rise-and-fall books use the same setup HI', () {
      final rows = SampleProjectService.buildMeasurements(fieldBookId: 1);
      // Rise and fall only changes the presentation; RL + BS is the same.
      final heights = setupHeightsOf([
        for (final m in rows) (bs: m.bs, rl: m.gh),
      ]);
      expect(heights[2], closeTo(102.164, 1e-9));
      final (headers, table) = PdfExporter.tableForTest(
        withDesign(),
        ReductionMethod.riseAndFall,
        en,
        design: true,
      );
      expect(table[2][headers.indexOf('Target reading')], '2.065');
    });
  });

  group('cut/fill math', () {
    test('cut is RL above design (+), fill below (−)', () {
      expect(cutFillOf(rl: 100.224, design: 100.099), closeTo(0.125, 1e-9));
      expect(cutFillOf(rl: 100.147, design: 100.187), closeTo(-0.040, 1e-9));
      expect(cutFillKindOf(0.125), CutFillKind.cut);
      expect(cutFillKindOf(-0.04), CutFillKind.fill);
      expect(cutFillKindOf(0.0004), CutFillKind.onGrade);
      expect(cutFillKindOf(-0.0004), CutFillKind.onGrade);
    });

    test('only rows with both an RL and a design level', () {
      expect(cutFillOf(rl: null, design: 100), isNull);
      expect(cutFillOf(rl: 100, design: null), isNull);
      expect(
        measurementCutFill(
          Measurement(
            fieldBookId: 1,
            orderIndex: 0,
            stationName: 'A',
            designLevel: 99,
          ),
        ),
        isNull,
      );
    });

    test('formats like RL (3 decimals) with localized letters', () {
      String en(double v) => formatCutFill(v, cutLetter: 'C', fillLetter: 'F');
      expect(en(100.224 - 100.099), 'C 0.125');
      expect(en(100.147 - 100.187), 'F 0.040');
      expect(en(-0.0001), '0.000');
      expect(formatCutFill(0.5, cutLetter: '절', fillLetter: '성'), '절 0.500');
      expect(formatCutFill(-0.5, cutLetter: '절', fillLetter: '성'), '성 0.500');
      expect(formatCutFillSigned(-0.04), '-0.040');
      expect(formatCutFillSigned(0.125), '0.125');
      expect(formatCutFillSigned(-0.0001), '0.000');
    });

    test('feet: same sign rule, values stay in ft', () {
      // RL 328.084 ft, design 328.500 ft → fill 0.416 ft.
      final value = cutFillOf(rl: 328.084, design: 328.5)!;
      expect(value, closeTo(-0.416, 1e-9));
      expect(formatCutFill(value, cutLetter: 'C', fillLetter: 'F'), 'F 0.416');
      expect(
        formatCutFill(
          cutFillOf(rl: 1012.75, design: 1010)!,
          cutLetter: 'C',
          fillLetter: 'F',
        ),
        'C 2.750',
      );
    });

    test('exports only when shown and a design level exists', () {
      final plain = SampleProjectService.buildMeasurements(fieldBookId: 1);
      expect(exportsDesignColumns(book(), withDesign()), isTrue);
      expect(exportsDesignColumns(book(show: false), withDesign()), isFalse);
      expect(exportsDesignColumns(book(), plain), isFalse);
    });

    test('duplicating the structure keeps design levels and the flag', () {
      final copy = FieldBookTemplates.duplicateStructure(
        source: book(),
        measurements: withDesign(),
        newDate: DateTime(2026, 10, 16),
      );
      expect(copy.fieldBook.showDesignLevel, isTrue);
      expect(copy.measurements.map((m) => m.designLevel).whereType<double>(), [
        100.099,
        100.187,
      ]);
      expect(
        copy.measurements.every((m) => m.bs == null && m.fs == null),
        true,
      );
    });
  });

  group('database', () {
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

    test(
      'v11 → v12 adds design_level / show_design_level, keeps data',
      () async {
        expect(AppConstants.dbVersion, greaterThanOrEqualTo(12));
        final dir = await Directory.systemTemp.createTemp('lvbook_v11');
        final path = '${dir.path}/v11.db';
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
          // Exactly the v11 field_books / measurements schema.
          await legacy.execute('''
          CREATE TABLE field_books (id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id INTEGER NOT NULL, title TEXT NOT NULL,
            date TEXT NOT NULL, start_bm_id INTEGER, start_elevation REAL,
            closing_mode TEXT NOT NULL DEFAULT 'none', closing_bm_id INTEGER,
            closing_elevation REAL,
            reduction_method TEXT NOT NULL DEFAULT 'heightOfInstrument',
            memo TEXT, surveyor TEXT, checker TEXT, instrument TEXT,
            weather TEXT, work_section TEXT, job_number TEXT,
            review_status TEXT NOT NULL DEFAULT 'draft', review_memo TEXT,
            reviewed_at TEXT, created_at TEXT NOT NULL)''');
          await legacy.execute('''
          CREATE TABLE measurements (id INTEGER PRIMARY KEY AUTOINCREMENT,
            field_book_id INTEGER NOT NULL, order_index INTEGER NOT NULL,
            station_name TEXT NOT NULL, type TEXT NOT NULL DEFAULT 'normal',
            bs REAL, fs REAL, ih REAL, gh REAL,
            manual_tp INTEGER NOT NULL DEFAULT 0)''');
          await legacy.execute(
            'CREATE TABLE app_settings (key TEXT PRIMARY KEY, '
            'value TEXT NOT NULL)',
          );
          await legacy.execute('''
          CREATE TABLE quick_memos (id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT, audio_path TEXT, created_at TEXT NOT NULL)''');
          await legacy.execute('''
          CREATE TABLE peg_tests (id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TEXT NOT NULL, instrument TEXT, observer TEXT,
            unit TEXT NOT NULL DEFAULT 'metres', a1 REAL NOT NULL,
            b1 REAL NOT NULL, a2 REAL NOT NULL, b2 REAL NOT NULL,
            peg_distance REAL NOT NULL, tolerance_entry REAL NOT NULL,
            note TEXT)''');
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
            'reduction_method': 'riseAndFall',
            'created_at': '2026-01-01T00:00:00.000',
          });
          await legacy.insert('measurements', {
            'field_book_id': bookId,
            'order_index': 0,
            'station_name': 'BM-1',
            'bs': 1.425,
            'ih': 101.425,
            'gh': 100.0,
          });
          await legacy.execute('PRAGMA user_version = 11');
          await legacy.close();

          legacy = await databaseFactoryFfi.openDatabase(
            path,
            options: helper.openDatabaseOptions(),
          );
          helper.setDatabaseForTesting(legacy);
          expect(await legacy.getVersion(), AppConstants.dbVersion);

          final repo = FieldBookRepository();
          final old = (await repo.getById(bookId))!;
          expect(old.title, 'Old book');
          expect(old.reductionMethod, ReductionMethod.riseAndFall);
          expect(old.showDesignLevel, isFalse);
          final rows = await MeasurementRepository().getByFieldBookId(bookId);
          expect(rows.single.bs, 1.425);
          expect(rows.single.gh, 100.0);
          expect(rows.single.designLevel, isNull);

          await repo.updateShowDesignLevel(
            old.copyWith(showDesignLevel: true, title: 'not saved'),
          );
          final updated = (await repo.getById(bookId))!;
          expect(updated.showDesignLevel, isTrue);
          expect(updated.title, 'Old book'); // only the flag is written
          await legacy.close();
        } finally {
          helper.setDatabaseForTesting(db);
          await dir.delete(recursive: true);
        }
      },
    );

    test('repository saves and loads design levels and the flag', () async {
      final projectId = await db.insert('projects', {
        'name': 'P',
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });
      final repo = FieldBookRepository();
      final id = await repo.create(
        book().copyWith(id: null, projectId: projectId),
      );
      final created = (await repo.getById(id))!;
      expect(created.showDesignLevel, isTrue);

      final measRepo = MeasurementRepository();
      await measRepo.replaceForFieldBook(id, withDesign(), startElevation: 100);
      final loaded = await measRepo.getByFieldBookId(id);
      expect(loaded.map((m) => m.designLevel).whereType<double>(), [
        100.099,
        100.187,
      ]);
      expect(
        measurementCutFill(loaded.firstWhere((m) => m.stationName == 'No.1')),
        closeTo(0.125, 1e-9),
      );

      // Clearing a design level persists as NULL.
      await measRepo.replaceForFieldBook(id, [
        for (final m in loaded) m.copyWith(designLevel: null),
      ]);
      expect(
        (await measRepo.getByFieldBookId(
          id,
        )).every((m) => m.designLevel == null),
        isTrue,
      );
    });

    group('backup', () {
      ProjectBackupData data() => ProjectBackupData(
        project: Project(id: 1, name: 'Backup'),
        benchmarks: const [],
        fieldBooks: [
          book(),
          book(show: false).copyWith(id: 2, title: 'Plain'),
        ],
        measurements: [
          ...withDesign(),
          Measurement(fieldBookId: 2, orderIndex: 0, stationName: 'A', bs: 1),
        ],
      );

      Future<Map<String, FieldBook>> restore(String source) async {
        final result = await ProjectBackupService().restoreAsNewProject(source);
        final books = await FieldBookRepository().getByProjectId(
          result.projectId,
        );
        return {for (final b in books) b.title: b};
      }

      test('round trip keeps design levels and the flag', () async {
        final source = ProjectBackupService.encode(data());
        final json = jsonDecode(source) as Map<String, dynamic>;
        expect(
          ((json['field_books'] as List).first as Map)['show_design_level'],
          1,
        );
        final books = await restore(source);
        expect(books['Formation']!.showDesignLevel, isTrue);
        expect(books['Plain']!.showDesignLevel, isFalse);
        final rows = await MeasurementRepository().getByFieldBookId(
          books['Formation']!.id!,
        );
        expect(rows.map((m) => m.designLevel).whereType<double>(), [
          100.099,
          100.187,
        ]);
      });

      test('an old backup without design fields restores fine', () async {
        final json =
            jsonDecode(ProjectBackupService.encode(data()))
                as Map<String, dynamic>;
        for (final b in json['field_books'] as List) {
          (b as Map).remove('show_design_level');
        }
        for (final m in json['measurements'] as List) {
          (m as Map).remove('design_level');
        }
        final books = await restore(jsonEncode(json));
        expect(books.values.every((b) => !b.showDesignLevel), isTrue);
        final rows = await MeasurementRepository().getByFieldBookId(
          books['Formation']!.id!,
        );
        expect(rows, hasLength(6));
        expect(rows.every((m) => m.designLevel == null), isTrue);
      });
    });
  });

  group('CSV', () {
    String csv(
      FieldBook fieldBook,
      List<Measurement> rows,
      AppLocalizations l10n,
    ) => CsvExporter.generateFieldBookCsv(
      fieldBook: fieldBook,
      measurements: rows,
      bmName: 'BM-1',
      startElevation: 100,
      l10n: l10n,
    );

    CsvImportResult import(String source) => CsvImporter.parse(
      source,
      projectId: 1,
      fallbackDate: DateTime(2026, 1, 1),
      l10n: en,
    );

    String tableHeader(String source) =>
        source.split('\r\n').firstWhere((line) => line.startsWith('No.'));

    test('without the design column the file is unchanged', () {
      final plain = SampleProjectService.buildMeasurements(fieldBookId: 1);
      for (final l10n in [en, ko]) {
        // Hidden flag (even with stored design levels) or no design levels:
        // byte-identical to a book without the feature.
        final reference = csv(book(show: false), plain, l10n);
        expect(csv(book(show: false), withDesign(), l10n), reference);
        expect(csv(book(), plain, l10n), reference);
        expect(tableHeader(reference), isNot(contains('Design')));
        expect(tableHeader(reference), isNot(contains('계획고')));
      }
    });

    test('adds design level, signed cut/fill and target at the end', () {
      final source = csv(book(), withDesign(), en);
      expect(
        tableHeader(source),
        'No.,Station,BS,IS,FS,HI,RL,Remarks,Design level,Cut(+)/Fill(−),'
        'Target reading',
      );
      final lines = source.split('\r\n');
      expect(
        lines.firstWhere((l) => l.startsWith('3,No.1')),
        endsWith(',100.099,0.125,2.065'),
      );
      expect(
        lines.firstWhere((l) => l.startsWith('5,No.2')),
        endsWith(',100.187,-0.040,1.210'),
      );
      // Rows without a design level leave the three cells empty.
      expect(lines.firstWhere((l) => l.startsWith('1,BM-1')), endsWith(',,,'));
      expect(
        tableHeader(csv(book(), withDesign(), ko)),
        endsWith('비고,계획고,절토(+)/성토(−),목표 시준값'),
      );
    });

    test('imports files with design columns (both languages)', () {
      for (final l10n in [en, ko]) {
        final result = import(csv(book(), withDesign(), l10n));
        expect(result.errors, isEmpty);
        expect(result.fieldBook!.showDesignLevel, isTrue);
        expect(
          result.measurements.map((m) => m.designLevel).toList(),
          withDesign().map((m) => m.designLevel).toList(),
        );
      }
    });

    test('imports files without design columns as before', () {
      final result = import(
        csv(
          book(show: false),
          SampleProjectService.buildMeasurements(fieldBookId: 1),
          en,
        ),
      );
      expect(result.errors, isEmpty);
      expect(result.fieldBook!.showDesignLevel, isFalse);
      expect(result.measurements, hasLength(6));
      expect(result.measurements.every((m) => m.designLevel == null), isTrue);
    });

    test('accepts raw design_level / cut_fill headers', () {
      const source =
          'Date,2026-10-15\n'
          'BM elevation,100\n'
          '\n'
          'No.,Station,BS,FS,RL,design_level,cut_fill\n'
          '1,BM-1,1.000,,100.000,,\n'
          '2,P1,,0.500,100.500,100.400,0.100\n';
      final result = import(source);
      expect(result.errors, isEmpty);
      expect(result.fieldBook!.showDesignLevel, isTrue);
      expect(result.measurements.last.designLevel, 100.4);
      expect(result.measurements.first.designLevel, isNull);
    });
  });

  group('PDF', () {
    test('table adds Design / Cut-Fill next to RL with letters', () {
      final (headers, rows) = PdfExporter.tableForTest(
        withDesign(),
        ReductionMethod.heightOfInstrument,
        en,
        design: true,
      );
      expect(headers, [
        'No.',
        'Station',
        'BS',
        'IS',
        'FS',
        'HI',
        'RL',
        'Design level',
        'Cut(+)/Fill(−)',
        'Target reading',
        'Remarks',
      ]);
      expect(rows[2].sublist(7, 10), ['100.099', 'C 0.125', '2.065']);
      expect(rows[4].sublist(7, 10), ['100.187', 'F 0.040', '1.210']);
      expect(rows[0].sublist(7, 10), ['-', '-', '-']);

      final (koHeaders, koRows) = PdfExporter.tableForTest(
        withDesign(),
        ReductionMethod.heightOfInstrument,
        ko,
        design: true,
      );
      expect(koHeaders, containsAllInOrder(['절토(+)/성토(−)', '목표 시준값']));
      expect(koRows[2], contains('절 0.125'));
      expect(koRows[4], contains('성 0.040'));
    });

    test('table without design is the existing layout', () {
      final (headers, rows) = PdfExporter.tableForTest(
        withDesign(),
        ReductionMethod.heightOfInstrument,
        en,
      );
      expect(headers, [
        'No.',
        'Station',
        'BS',
        'IS',
        'FS',
        'HI',
        'RL',
        'Remarks',
      ]);
      expect(rows.every((row) => row.length == 8), isTrue);
    });

    test('generates with and without design columns', () async {
      for (final l10n in [en, ko]) {
        for (final show in [true, false]) {
          final bytes = await PdfExporter.generateFieldBookPdf(
            fieldBook: book(
              show: show,
            ).copyWith(reductionMethod: ReductionMethod.riseAndFall),
            measurements: withDesign(),
            bmName: 'BM-1',
            startElevation: 100,
            tolerance: const MisclosureTolerance(unit: LengthUnit.feet),
            l10n: l10n,
          );
          expect(bytes.length, greaterThan(1000));
        }
      }
    });
  });
}
