import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/backup/auto_backup_service.dart';
import 'package:lv_book/features/backup/project_backup_service.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/project/data/project_repository.dart';
import 'package:lv_book/features/project/domain/project.dart';

class _MemorySettings extends BackupSettingsRepository {
  DateTime? autoBackupAt;

  @override
  Future<DateTime?> lastAutoBackupAt() async => autoBackupAt;

  @override
  Future<void> setLastAutoBackupAt(DateTime value) async {
    autoBackupAt = value;
  }
}

class _FakeProjectRepository extends ProjectRepository {
  final List<Project> projects;

  _FakeProjectRepository(this.projects);

  @override
  Future<List<Project>> getAll() async => projects;
}

class _FakeBackupService extends ProjectBackupService {
  @override
  Future<ProjectBackupData> collectProject(int projectId) async {
    return ProjectBackupData(
      project: Project(
        id: projectId,
        name: '현장 $projectId',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      benchmarks: const [],
      fieldBooks: [
        FieldBook(
          id: 1,
          projectId: projectId,
          title: '야장1',
          date: DateTime(2026, 1, 2),
          createdAt: DateTime(2026, 1, 2),
        ),
      ],
      measurements: const [],
    );
  }
}

void main() {
  late Directory tempDir;
  late _MemorySettings settings;

  Project project(int id) => Project(
    id: id,
    name: '현장 $id',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  AutoBackupService buildService({
    required DateTime now,
    List<Project>? projects,
  }) {
    return AutoBackupService(
      settings: settings,
      backupService: _FakeBackupService(),
      projectRepository: _FakeProjectRepository(projects ?? [project(1)]),
      rootDirectory: () async => tempDir,
      now: () => now,
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('auto_backup_test');
    settings = _MemorySettings();
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('writes a snapshot and records the timestamp on first run', () async {
    final now = DateTime(2026, 7, 6, 9, 30);
    final ran = await buildService(now: now).runIfDue();

    expect(ran, isTrue);
    expect(settings.autoBackupAt, now);

    final backupRoot = Directory(
      '${tempDir.path}/${AutoBackupService.backupDirName}',
    );
    final snapshots = backupRoot.listSync().whereType<Directory>().toList();
    expect(snapshots, hasLength(1));
    final files = snapshots.first.listSync().whereType<File>().toList();
    expect(files, hasLength(1));
    // Snapshot files must round-trip through the standard backup decoder.
    final data = ProjectBackupService.decode(files.first.readAsStringSync());
    expect(data.project.name, '현장 1');
    expect(data.fieldBooks, hasLength(1));
  });

  test('skips when the last snapshot is within the interval', () async {
    settings.autoBackupAt = DateTime(2026, 7, 6, 8, 0);
    final ran = await buildService(
      now: DateTime(2026, 7, 6, 20, 0),
    ).runIfDue();
    expect(ran, isFalse);
  });

  test('runs again after the interval elapses', () async {
    settings.autoBackupAt = DateTime(2026, 7, 4, 8, 0);
    final ran = await buildService(now: DateTime(2026, 7, 6, 9, 0)).runIfDue();
    expect(ran, isTrue);
  });

  test('prunes old snapshots beyond maxSnapshots', () async {
    for (var day = 1; day <= 4; day++) {
      settings.autoBackupAt = null;
      await buildService(
        now: DateTime(2026, 7, day, 9, 0),
      ).runIfDue(maxSnapshots: 2);
    }

    final backupRoot = Directory(
      '${tempDir.path}/${AutoBackupService.backupDirName}',
    );
    final names =
        backupRoot
            .listSync()
            .whereType<Directory>()
            .map((d) => d.path.split(Platform.pathSeparator).last)
            .toList()
          ..sort();
    expect(names, hasLength(2));
    // Oldest snapshots were removed; the newest two days remain.
    expect(names.first.startsWith('2026-07-03'), isTrue);
    expect(names.last.startsWith('2026-07-04'), isTrue);
  });

  test('does nothing when there are no projects', () async {
    final ran = await buildService(
      now: DateTime(2026, 7, 6),
      projects: const [],
    ).runIfDue();
    expect(ran, isFalse);
    expect(settings.autoBackupAt, isNull);
  });
}
