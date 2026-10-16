import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/database/database_helper.dart';
import 'package:lv_book/features/benchmark/data/benchmark_providers.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_providers.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_repository.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_row_actions.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_edit_screen.dart';
import 'package:lv_book/features/project/data/sample_project_service.dart';
import 'package:lv_book/features/settings/misclosure_tolerance_repository.dart';
import 'package:lv_book/l10n/l10n.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Sample run with a design level on No.1 and a manual TP flag on No.2.
List<Measurement> _original() => [
  for (final m in SampleProjectService.buildMeasurements(fieldBookId: 1))
    switch (m.stationName) {
      'No.1' => m.copyWith(designLevel: 100.099),
      'No.2' => m.copyWith(manualTp: true, type: MeasurementType.tp),
      _ => m,
    },
];

/// Persisted fields (ids are re-assigned on every save).
List<Map<String, dynamic>> _rows(List<Measurement> rows) => [
  for (final m in rows) Map.of(m.toMap())..remove('id'),
];

void main() {
  group('editor', () {
    late _MemoryMeasurementRepository repo;

    setUp(() => repo = _MemoryMeasurementRepository(_original()));

    Widget editor(Locale locale) => ProviderScope(
      overrides: [
        measurementRepositoryProvider.overrideWithValue(repo),
        fieldBookRepositoryProvider.overrideWithValue(FieldBookRepository()),
        fieldBookListProvider.overrideWith(_StubFieldBookNotifier.new),
        benchmarkListProvider.overrideWith(_StubBenchmarkNotifier.new),
        misclosureToleranceProvider.overrideWith(
          (ref) async => MisclosureTolerance.defaults,
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FieldBookEditScreen(
          fieldBook: FieldBook(
            id: 1,
            projectId: 1,
            title: 'Undo',
            date: DateTime(2026, 10, 16),
            startElevation: 100,
            showDesignLevel: true,
          ),
          projectId: 1,
        ),
      ),
    );

    Finder undoAction(String label) => find.descendant(
      of: find.byType(SnackBarAction),
      matching: find.text(label),
    );

    Future<void> deleteRow(WidgetTester tester, int row, String delete) async {
      await tester.tap(find.byType(PopupMenuButton<String>).at(row));
      await tester.pumpAndSettle();
      await tester.tap(find.text(delete).last); // menu item
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, delete)); // confirm
      await tester.pumpAndSettle();
    }

    testWidgets('delete → Undo restores the same rows, order and flags', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(editor(const Locale('en')));
      await tester.pumpAndSettle();
      final before = _rows(_original());

      // Delete No.1 (row 2, with a design level); autosave persists it.
      await deleteRow(tester, 2, 'Delete');
      expect(find.text('Row deleted'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(repo.stored.map((m) => m.stationName), [
        'BM-1',
        'TP-1',
        'TP-2',
        'No.2',
        'BM-1 (폐합)',
      ]);

      await tester.tap(undoAction('Undo'));
      await tester.pumpAndSettle();

      // Re-saved through the repository: same values, order_index, manual
      // TP and design level as before the delete.
      expect(_rows(repo.stored), before);
      expect(find.text('Row deleted'), findsNothing);
      final designCell = tester.widget<TextField>(
        find.byKey(const ValueKey('cell-2-dl')),
      );
      expect(designCell.controller!.text, '100.099');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Korean and Spanish snack bar text', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final (locale, delete, message, undo) in [
        (const Locale('ko'), '삭제', '행을 삭제했습니다', '실행 취소'),
        (const Locale('es'), 'Eliminar', 'Fila eliminada', 'Deshacer'),
      ]) {
        repo = _MemoryMeasurementRepository(_original());
        await tester.pumpWidget(editor(locale));
        await tester.pumpAndSettle();
        await deleteRow(tester, 0, delete);
        expect(find.text(message), findsOneWidget);
        await tester.tap(undoAction(undo));
        await tester.pumpAndSettle();
        expect(_rows(repo.stored), _rows(_original()));
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    });

    testWidgets('deleting an empty row offers no undo', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(editor(const Locale('en')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>).at(6));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('Row deleted'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(_rows(repo.stored), _rows(_original()));
    });
  });

  group('repository', () {
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

    test('delete → restore round-trips through the database', () async {
      final projectId = await db.insert('projects', {
        'name': 'P',
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
      });
      final id = await FieldBookRepository().create(
        FieldBook(
          projectId: projectId,
          title: 'Undo',
          date: DateTime(2026, 10, 16),
          startElevation: 100,
          showDesignLevel: true,
        ),
      );
      final measRepo = MeasurementRepository();
      final original = [
        for (final m in _original()) m.copyWith(fieldBookId: id),
      ];
      await measRepo.replaceForFieldBook(id, original, startElevation: 100);
      final saved = await measRepo.getByFieldBookId(id);

      for (final index in [0, 2, 4, saved.length - 1]) {
        final (remaining, removed) = MeasurementRowActions.delete(
          saved,
          index: index,
        );
        await measRepo.replaceForFieldBook(id, remaining);
        final afterDelete = await measRepo.getByFieldBookId(id);
        expect(afterDelete, hasLength(saved.length - 1));
        expect(afterDelete.map((m) => m.orderIndex), [
          for (var i = 0; i < saved.length - 1; i++) i,
        ]);

        await measRepo.replaceForFieldBook(
          id,
          MeasurementRowActions.restore(
            afterDelete,
            index: index,
            row: removed,
          ),
        );
        expect(_rows(await measRepo.getByFieldBookId(id)), _rows(original));
      }
    });
  });
}

class _MemoryMeasurementRepository extends MeasurementRepository {
  List<Measurement> stored;

  _MemoryMeasurementRepository(this.stored);

  @override
  Future<List<Measurement>> getByFieldBookId(int fieldBookId) async => stored;

  @override
  Future<void> replaceForFieldBook(
    int fieldBookId,
    List<Measurement> measurements, {
    double? startElevation,
  }) async {
    stored = measurements;
  }
}

class _StubFieldBookNotifier extends FieldBookListNotifier {
  @override
  Future<List<FieldBook>> build(int projectId) async => const [];
}

class _StubBenchmarkNotifier extends BenchmarkListNotifier {
  @override
  Future<List<BenchMark>> build(int projectId) async => const [];
}
