import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/constants/app_constants.dart';
import 'package:lv_book/core/database/database_helper.dart';
import 'package:lv_book/features/backup/project_backup_service.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/export/export_judgement.dart';
import 'package:lv_book/features/export/pdf_template.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_validation.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_l10n.dart';
import 'package:lv_book/features/import/csv_importer.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';
import 'package:lv_book/features/project/data/sample_project_service.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:lv_book/features/settings/misclosure_tolerance_repository.dart';
import 'package:lv_book/features/settings/settings_screen.dart';
import 'package:lv_book/l10n/l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  final en = l10nFor(const Locale('en'));
  final ko = l10nKo;
  final es = l10nFor(const Locale('es'));
  const kRule = MisclosureTolerance.sqrtDistance(10);
  final feetRule = const MisclosureTolerance(
    unit: LengthUnit.feet,
  ).withEntry(MisclosureToleranceMode.sqrtDistance, 0.035);

  group('K·√L', () {
    test('metres: K mm, L km → allowed in m and the formula', () {
      expect(kRule.allowed(3, routeLength: 2.4), closeTo(0.0154919, 1e-6));
      expect(kRule.formula(3, routeLength: 2.4), '±10 mm·√2.40 km = ±15.5 mm');
      // Setups do not matter for K·√L.
      expect(kRule.allowed(30, routeLength: 1), closeTo(0.010, 1e-12));
    });

    test('feet: K ft, L miles, not divided by 1000', () {
      expect(feetRule.distanceKFt, 0.035);
      expect(feetRule.allowed(2, routeLength: 1.5), closeTo(0.042866, 1e-6));
      expect(
        feetRule.formula(2, routeLength: 1.5),
        '±0.035 ft·√1.50 mi = ±0.043 ft',
      );
    });

    test('without a route length the allowance is unavailable', () {
      for (final length in [null, 0.0, -1.0, double.nan]) {
        expect(kRule.allowed(4, routeLength: length), isNull);
        expect(kRule.formula(4, routeLength: length), isNull);
        expect(kRule.isWithin(0, setups: 4, routeLength: length), isFalse);
      }
    });

    test('existing modes are unchanged; c·√n shows its formula', () {
      const fixed = MisclosureTolerance.fixed(2);
      expect(fixed.allowed(9, routeLength: 5), 0.002);
      expect(fixed.formula(9), isNull);
      const setups = MisclosureTolerance.sqrtSetups(5);
      expect(setups.allowed(4), closeTo(0.010, 1e-12));
      expect(setups.formula(4), '±5 mm·√4 = ±10.0 mm');
    });

    test('presets: survey orders (mm) and typical US values (ft)', () {
      expect(MisclosureTolerance.distancePresets(LengthUnit.metres), [
        2.5,
        5.0,
        10.0,
        15.0,
        20.0,
      ]);
      expect(MisclosureTolerance.distancePresets(LengthUnit.feet), [
        0.017,
        0.035,
        0.05,
      ]);
      for (final unit in LengthUnit.values) {
        for (final k in MisclosureTolerance.distancePresets(unit)) {
          expect(MisclosureTolerance.isValidEntry(k, unit), isTrue);
        }
      }
    });

    test('switching modes keeps c and K apart', () {
      final rule = const MisclosureTolerance.sqrtSetups(
        7,
      ).withEntry(MisclosureToleranceMode.sqrtDistance, 2.5);
      expect(rule.coefficientMm, 7);
      expect(rule.distanceKMm, 2.5);
      expect(rule.entryFor(MisclosureToleranceMode.sqrtSetups), 7);
    });
  });

  for (final (unit, chip, expected) in [
    (LengthUnit.metres, '2.5 mm', 2.5),
    (LengthUnit.feet, '0.017 ft', 0.017),
  ]) {
    testWidgets('dialog: K·√L segment and preset chips (${unit.name})', (
      tester,
    ) async {
      MisclosureTolerance? result;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<MisclosureTolerance>(
                  context: context,
                  builder: (_) => MisclosureToleranceDialog(
                    initial: MisclosureTolerance(unit: unit),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('K·√L'));
      await tester.pumpAndSettle();
      final symbol = unit.toleranceSymbol;
      expect(find.text('K ($symbol·√${unit.routeSymbol})'), findsOneWidget);
      expect(
        find.byType(ChoiceChip),
        findsNWidgets(MisclosureTolerance.distancePresets(unit).length),
      );
      await tester.tap(find.text(chip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result!.mode, MisclosureToleranceMode.sqrtDistance);
      expect(result!.distanceKEntry, expected);
      expect(
        misclosureToleranceSummary(l10nFor(const Locale('en')), result!),
        '${expected.toString()} $symbol × √L (L = route length, '
        '${unit.routeSymbol})',
      );
      // Custom K stays allowed.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('K·√L'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        unit == LengthUnit.metres ? '7.5' : '0.04',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result!.distanceKEntry, unit == LengthUnit.metres ? 7.5 : 0.04);
    });
  }

  group('closure, validation and judgement text', () {
    final rows = SampleProjectService.buildMeasurements(fieldBookId: 1);

    LevelClosureCheck closure({double? routeLength}) =>
        LevelClosureCheck.compute(
          rows,
          startElevation: 100,
          closingElevation: 100,
          tolerance: kRule,
          routeLength: routeLength,
        );

    test('missing route length: unavailable, never suitable', () {
      final check = closure();
      expect(check.toleranceUnavailable, isTrue);
      expect(check.allowed, isNull);
      expect(check.withinTolerance, isNull);
      expect(check.isSuitable, isFalse);
      for (final l10n in [en, ko, es]) {
        expect(
          ExportJudgement.labelForClosure(check, l10n: l10n),
          l10n.exportJudgementToleranceUnavailable,
        );
      }
      expect(
        ExportJudgement.labelForClosure(check, l10n: en),
        'Tolerance unavailable — enter the route length',
      );
    });

    test('with a route length it is judged normally', () {
      final check = closure(routeLength: 2.4);
      expect(check.toleranceUnavailable, isFalse);
      expect(check.withinTolerance, isTrue); // 1 mm misclosure ≤ 15.5 mm
      expect(check.allowedFormula, '±10 mm·√2.40 km = ±15.5 mm');
      expect(
        ExportJudgement.labelForClosure(check, l10n: en),
        en.coreJudgementWithinTolerance,
      );
    });

    test('pre-export validation prompts for the route length', () {
      final validation = MeasurementValidation.validate(
        measurements: rows,
        startElevation: 100,
        closingElevation: 100,
        tolerance: kRule,
      );
      expect(validation.issues, [MeasurementIssue.routeLengthMissing]);
      expect(validation.canExport, isFalse);
      expect(validation.hasBlockingFailures, isFalse); // a warning
      final item = validation.checklist.firstWhere(
        (item) => item.check == MeasurementCheck.tolerance,
      );
      expect(item.passed, isFalse);
      expect(
        validation.localizedMessages(en).single,
        en.fieldbookIssueRouteLengthMissing,
      );
      expect(
        validation.localizedJudgement(ko),
        ko.exportJudgementToleranceUnavailable,
      );

      final ok = MeasurementValidation.validate(
        measurements: rows,
        startElevation: 100,
        closingElevation: 100,
        tolerance: kRule,
        routeLength: 2.4,
      );
      expect(ok.issues, isEmpty);
      expect(ok.canExport, isTrue);
    });

    test('PDF and CSV print the formula or the unavailable text', () {
      final book = FieldBook(
        id: 1,
        projectId: 1,
        title: 'K',
        date: DateTime(2026, 10, 16),
        closingMode: ClosingReferenceMode.loop,
      );
      String csv(FieldBook fieldBook) => CsvExporter.generateFieldBookCsv(
        fieldBook: fieldBook,
        measurements: rows,
        bmName: 'BM-1',
        startElevation: 100,
        tolerance: kRule,
        proSettings: const ProPdfSettings(),
        l10n: en,
      );
      final missing = csv(book);
      expect(missing, contains('Allowed,n/a (enter the route length)'));
      expect(
        missing,
        contains('Result,Tolerance unavailable — enter the route length'),
      );
      expect(missing, isNot(contains('Route length')));

      final withLength = csv(book.copyWith(routeLength: 2.4));
      expect(withLength, contains('Route length,2.400'));
      expect(withLength, contains('Tolerance rule,±10 mm·√2.40 km = ±15.5 mm'));

      final pdfRows = PdfExporter.checkRowsForTest(
        closure(routeLength: 2.4),
        l10n: en,
      );
      expect(pdfRows.last, [('Tolerance rule', '±10 mm·√2.40 km = ±15.5 mm')]);
      final pdfMissing = PdfExporter.checkRowsForTest(closure(), l10n: ko);
      expect(pdfMissing.last.last, (
        ko.exportCheckAllowed,
        ko.exportCheckAllowedUnavailable,
      ));
    });

    test('CSV import reads the route length back (every language)', () {
      for (final l10n in [en, ko, es]) {
        final source = CsvExporter.generateFieldBookCsv(
          fieldBook: FieldBook(
            projectId: 1,
            title: 'K',
            date: DateTime(2026, 10, 16),
            routeLength: 1.25,
          ),
          measurements: rows,
          bmName: 'BM-1',
          startElevation: 100,
          l10n: l10n,
        );
        final result = CsvImporter.parse(
          source,
          projectId: 1,
          fallbackDate: DateTime(2026, 1, 1),
          l10n: en,
        );
        expect(result.errors, isEmpty);
        expect(result.fieldBook!.routeLength, 1.25);
      }
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

    Future<int> insertProject(Database database) =>
        database.insert('projects', {
          'name': 'P',
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
        });

    test('tolerance setting: old settings default, K round trips', () async {
      final repo = MisclosureToleranceRepository();
      // Installs from before K·√L have no K keys: defaults, mode unchanged.
      await repo.save(const MisclosureTolerance.sqrtSetups(5));
      await db.delete(
        'app_settings',
        where: 'key IN (?, ?)',
        whereArgs: [
          MisclosureToleranceRepository.distanceKMmKey,
          MisclosureToleranceRepository.distanceKFtKey,
        ],
      );
      final old = await repo.load();
      expect(old.mode, MisclosureToleranceMode.sqrtSetups);
      expect(old.coefficientMm, 5);
      expect(old.distanceKMm, MisclosureTolerance.defaultDistanceKMm);
      expect(old.distanceKFt, MisclosureTolerance.defaultDistanceKFt);

      await repo.save(kRule.copyWith(distanceKMm: 2.5));
      final loaded = await repo.load();
      expect(loaded.mode, MisclosureToleranceMode.sqrtDistance);
      expect(loaded.distanceKMm, 2.5);
      expect(loaded.allowed(1, routeLength: 4), closeTo(0.005, 1e-12));

      await repo.save(feetRule);
      expect(await repo.load(), feetRule);
      expect(
        () => repo.save(kRule.copyWith(distanceKMm: 500)),
        throwsArgumentError,
      );
    });

    test('v12 → v13 adds route_length, keeps data', () async {
      expect(AppConstants.dbVersion, 13);
      final dir = await Directory.systemTemp.createTemp('lvbook_v12');
      final path = '${dir.path}/v12.db';
      try {
        // Current schema minus the v13 column = the v12 schema.
        var legacy = await databaseFactoryFfi.openDatabase(
          path,
          options: helper.openDatabaseOptions(),
        );
        await legacy.execute(
          'ALTER TABLE field_books DROP COLUMN route_length',
        );
        final projectId = await insertProject(legacy);
        final bookId = await legacy.insert('field_books', {
          'project_id': projectId,
          'title': 'Old book',
          'date': '2026-01-01T00:00:00.000',
          'start_elevation': 100.0,
          'show_design_level': 1,
          'created_at': '2026-01-01T00:00:00.000',
        });
        await legacy.execute('PRAGMA user_version = 12');
        await legacy.close();

        legacy = await databaseFactoryFfi.openDatabase(
          path,
          options: helper.openDatabaseOptions(),
        );
        helper.setDatabaseForTesting(legacy);
        expect(await legacy.getVersion(), 13);
        final repo = FieldBookRepository();
        final old = (await repo.getById(bookId))!;
        expect(old.title, 'Old book');
        expect(old.showDesignLevel, isTrue);
        expect(old.routeLength, isNull);

        await repo.updateRouteLength(
          old.copyWith(routeLength: 2.4, title: 'not saved'),
        );
        final updated = (await repo.getById(bookId))!;
        expect(updated.routeLength, 2.4);
        expect(updated.title, 'Old book'); // only the length is written
        await legacy.close();
      } finally {
        helper.setDatabaseForTesting(db);
        await dir.delete(recursive: true);
      }
    });

    test('backup round trip; old backups without it restore', () async {
      final data = ProjectBackupData(
        project: Project(id: 1, name: 'Backup'),
        benchmarks: const [],
        fieldBooks: [
          FieldBook(
            id: 1,
            projectId: 1,
            title: 'Long run',
            date: DateTime(2026, 10, 16),
            routeLength: 3.75,
          ),
        ],
        measurements: [
          Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'A', bs: 1),
        ],
      );
      Future<FieldBook> restore(String source) async {
        final result = await ProjectBackupService().restoreAsNewProject(source);
        return (await FieldBookRepository().getByProjectId(
          result.projectId,
        )).single;
      }

      final source = ProjectBackupService.encode(data);
      final json = jsonDecode(source) as Map<String, dynamic>;
      expect(
        ((json['field_books'] as List).single as Map)['route_length'],
        3.75,
      );
      expect((await restore(source)).routeLength, 3.75);

      ((json['field_books'] as List).single as Map).remove('route_length');
      expect((await restore(jsonEncode(json))).routeLength, isNull);
    });
  });
}
