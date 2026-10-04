import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/database/database_helper.dart';
import 'package:lv_book/features/benchmark/data/benchmark_repository.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/export/export_judgement.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_repository.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/project/data/project_repository.dart';
import 'package:lv_book/features/project/data/sample_project_service.dart';
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

  Future<int> count(String table) async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM $table');
    return rows.first['c'] as int;
  }

  test('sample run closes within 0.001m and is judged 적합', () {
    final rows = SampleProjectService.buildMeasurements(fieldBookId: 1);
    final error = LevelClosure.error(
      rows,
      startElevation: SampleProjectService.benchmarkElevation,
    );

    expect(error.abs(), lessThanOrEqualTo(0.001));
    expect(ExportJudgement.label(error), '적합');
    // Loop returns to BM-1 with a 1mm difference.
    expect(rows.first.gh, SampleProjectService.benchmarkElevation);
    expect(rows.last.gh, closeTo(100.001, 1e-9));
    expect(
      (rows.last.gh! - SampleProjectService.benchmarkElevation).abs(),
      lessThanOrEqualTo(0.001 + 1e-9),
    );
  });

  test('sample run contains BM, TPs and an intermediate sight', () {
    final rows = SampleProjectService.buildMeasurements(fieldBookId: 1);
    expect(rows, hasLength(6));
    expect(rows.where((m) => m.type == MeasurementType.tp), hasLength(2));
    final intermediate = rows[2];
    expect(intermediate.bs, isNull);
    expect(intermediate.fs, isNotNull);
    expect(intermediate.ih, isNull);
    expect(intermediate.gh, isNotNull);
  });

  test(
    'creates project, BM, field book and measurements consistently',
    () async {
      final project = await SampleProjectService().createSampleProject(
        l10n: l10nKo,
      );

      expect(project.id, isNotNull);
      expect(await count('projects'), 1);
      expect(await count('benchmarks'), 1);
      expect(await count('field_books'), 1);
      expect(await count('measurements'), 6);

      final savedProject = await ProjectRepository().getById(project.id!);
      expect(savedProject?.name, '예제 현장 (삭제 가능)');

      final bms = await BenchMarkRepository().getByProjectId(project.id!);
      expect(bms, hasLength(1));
      expect(bms.single.name, 'BM-1');
      expect(bms.single.elevation, 100.0);
      expect(bms.single.status, BenchMarkStatus.available);

      final books = await FieldBookRepository().getByProjectId(project.id!);
      expect(books, hasLength(1));
      final book = books.single;
      expect(book.startBmId, bms.single.id);
      expect(book.startElevation, 100.0);
      expect(book.title, '예제 야장 (BM-1 왕복)');
      expect(book.surveyor, '홍길동');
      expect(book.instrument, isNotEmpty);
      expect(book.weather, isNotEmpty);

      final saved = await MeasurementRepository().getByFieldBookId(book.id!);
      final expected = SampleProjectService.buildMeasurements(
        fieldBookId: book.id!,
      );
      expect(
        saved.map((m) => m.stationName),
        expected.map((m) => m.stationName),
      );
      for (var i = 0; i < saved.length; i++) {
        expect(saved[i].orderIndex, i);
        expect(saved[i].type, expected[i].type);
        expect(saved[i].ih, expected[i].ih);
        expect(saved[i].gh, expected[i].gh);
      }
      expect(
        ExportJudgement.label(
          LevelClosure.error(saved, startElevation: book.startElevation!),
        ),
        '적합',
      );
    },
  );

  test('concurrent taps create only one sample project', () async {
    final service = SampleProjectService();
    final results = await Future.wait([
      service.createSampleProject(l10n: l10nKo),
      service.createSampleProject(l10n: l10nKo),
    ]);

    expect(results[0].id, results[1].id);
    expect(await count('projects'), 1);
    expect(await count('measurements'), 6);
  });

  test('sample project is created in English for the English app', () async {
    final en = l10nFor(const Locale('en'));
    final project = await SampleProjectService().createSampleProject(l10n: en);

    final savedProject = await ProjectRepository().getById(project.id!);
    expect(savedProject?.name, 'Sample site (deletable)');

    final bm = (await BenchMarkRepository().getByProjectId(project.id!)).single;
    expect(bm.name, 'BM-1');

    final book = (await FieldBookRepository().getByProjectId(
      project.id!,
    )).single;
    expect(book.title, 'Sample level book (BM-1 loop)');
    expect(book.surveyor, 'J. Smith');

    final saved = await MeasurementRepository().getByFieldBookId(book.id!);
    expect(saved.last.stationName, 'BM-1 (close)');
    expect(
      LevelClosure.error(saved, startElevation: book.startElevation!).abs(),
      lessThanOrEqualTo(0.001),
    );
  });
}
