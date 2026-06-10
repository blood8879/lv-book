import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/backup/project_backup_providers.dart';
import 'package:lv_book/features/backup/project_backup_service.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_providers.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_list_screen.dart';
import 'package:lv_book/features/project/domain/project.dart';

void main() {
  testWidgets('field book action menu shares project backup JSON', (
    tester,
  ) async {
    final store = _MemoryProjectBackupStore(
      projects: [Project(id: 1, name: '현장/A')],
      fieldBooks: [
        FieldBook(
          id: 1,
          projectId: 1,
          title: '야장 A',
          date: DateTime(2026, 6, 8),
        ),
      ],
      measurements: [
        Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'BM.1'),
      ],
    );
    String? sharedFileName;
    String? sharedSource;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectBackupServiceProvider.overrideWithValue(
            ProjectBackupService(store: store),
          ),
          projectBackupShareProvider.overrideWithValue(({
            required fileName,
            required source,
          }) async {
            sharedFileName = fileName;
            sharedSource = source;
          }),
          fieldBookListProvider.overrideWith(_FieldBooksNotifier.new),
        ],
        child: const MaterialApp(home: FieldBookListScreen(projectId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('야장'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('프로젝트 백업 공유'));
    await tester.pumpAndSettle();

    expect(sharedFileName, '현장_A_lvbook_backup.json');
    expect(sharedSource, contains(ProjectBackupService.kind));
    expect(ProjectBackupService.decode(sharedSource!).project.name, '현장/A');
  });

  testWidgets('restore dialog accepts valid JSON and rejects corrupt JSON', (
    tester,
  ) async {
    final store = _MemoryProjectBackupStore(
      projects: [Project(id: 1, name: '기존 현장')],
    );
    final backup = ProjectBackupService.encode(
      ProjectBackupData(
        project: Project(id: 7, name: '복원 현장'),
        benchmarks: const [],
        fieldBooks: [
          FieldBook(
            id: 21,
            projectId: 7,
            title: '복원 야장',
            date: DateTime(2026, 6, 8),
          ),
        ],
        measurements: [
          Measurement(fieldBookId: 21, orderIndex: 0, stationName: 'No.1'),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectBackupServiceProvider.overrideWithValue(
            ProjectBackupService(store: store),
          ),
          fieldBookListProvider.overrideWith(_FieldBooksNotifier.new),
        ],
        child: const MaterialApp(home: FieldBookListScreen(projectId: 1)),
      ),
    );
    await tester.pumpAndSettle();

    await _openRestoreDialog(tester);
    await tester.enterText(find.byType(TextField).last, backup);
    await tester.tap(find.text('복원'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(store.projects.map((project) => project.name), contains('복원 현장'));
    expect(
      store.fieldBooks.map((fieldBook) => fieldBook.title),
      contains('복원 야장'),
    );
    expect(find.text('백업을 새 프로젝트로 복원했습니다.'), findsOneWidget);

    await _openRestoreDialog(tester);
    await tester.enterText(find.byType(TextField).last, '{"kind":"wrong"}');
    await tester.tap(find.text('복원'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('백업 복원 실패'), findsOneWidget);
  });
}

Future<void> _openRestoreDialog(WidgetTester tester) async {
  await tester.tap(find.text('야장'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('백업 JSON 복원'));
  await tester.pumpAndSettle();
}

class _FieldBooksNotifier extends FieldBookListNotifier {
  @override
  Future<List<FieldBook>> build(int projectId) async {
    return [
      FieldBook(
        id: 1,
        projectId: projectId,
        title: '야장 A',
        date: DateTime(2026, 6, 8),
      ),
    ];
  }
}

class _MemoryProjectBackupStore implements ProjectBackupStore {
  List<Project> projects;
  List<BenchMark> benchmarks;
  List<FieldBook> fieldBooks;
  List<Measurement> measurements;

  _MemoryProjectBackupStore({
    List<Project>? projects,
    List<BenchMark>? benchmarks,
    List<FieldBook>? fieldBooks,
    List<Measurement>? measurements,
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
    return action(_MemoryProjectBackupRestoreStore(this));
  }
}

class _MemoryProjectBackupRestoreStore implements ProjectBackupRestoreStore {
  final _MemoryProjectBackupStore _store;

  const _MemoryProjectBackupRestoreStore(this._store);

  @override
  Future<int> insertProject(Project project) async {
    final id = _nextId(_store.projects.map((project) => project.id));
    _store.projects.add(project.copyWith(id: id));
    return id;
  }

  @override
  Future<int> insertBenchmark(BenchMark benchmark) async {
    final id = _nextId(_store.benchmarks.map((benchmark) => benchmark.id));
    _store.benchmarks.add(benchmark.copyWith(id: id));
    return id;
  }

  @override
  Future<int> insertFieldBook(FieldBook fieldBook) async {
    final id = _nextId(_store.fieldBooks.map((fieldBook) => fieldBook.id));
    _store.fieldBooks.add(fieldBook.copyWith(id: id));
    return id;
  }

  @override
  Future<int> insertMeasurement(Measurement measurement) async {
    final id = _nextId(
      _store.measurements.map((measurement) => measurement.id),
    );
    _store.measurements.add(measurement.copyWith(id: id));
    return id;
  }

  int _nextId(Iterable<int?> ids) {
    return ids.whereType<int>().fold(0, (max, id) => id > max ? id : max) + 1;
  }
}
