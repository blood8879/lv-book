import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../project/data/project_providers.dart';
import 'auto_backup_service.dart';
import 'project_backup_service.dart';

typedef ProjectBackupShare =
    Future<void> Function({required String fileName, required String source});

final projectBackupServiceProvider = Provider<ProjectBackupService>(
  (ref) => ProjectBackupService(),
);

final backupSettingsRepositoryProvider = Provider<BackupSettingsRepository>(
  (ref) => BackupSettingsRepository(),
);

final projectBackupShareProvider = Provider<ProjectBackupShare>((ref) {
  return ({required String fileName, required String source}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(source);
    await Share.shareXFiles([XFile(file.path)]);
    await ref
        .read(backupSettingsRepositoryProvider)
        .setLastBackupShareAt(DateTime.now());
    ref.invalidate(backupReminderProvider);
  };
});

/// Shares every project as its own backup JSON in one share sheet.
/// Returns the number of projects shared (0 when there is nothing to share).
final allProjectsBackupShareProvider = Provider<Future<int> Function()>((ref) {
  return () async {
    final projects = await ref.read(projectRepositoryProvider).getAll();
    if (projects.isEmpty) return 0;

    final service = ref.read(projectBackupServiceProvider);
    final dir = await getTemporaryDirectory();
    final files = <XFile>[];
    for (final project in projects) {
      final id = project.id;
      if (id == null) continue;
      final data = await service.collectProject(id);
      final source = ProjectBackupService.encode(data);
      final safeName = project.name.trim().replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final file = File('${dir.path}/${safeName}_lvbook_backup.json');
      await file.writeAsString(source);
      files.add(XFile(file.path));
    }
    if (files.isEmpty) return 0;

    await Share.shareXFiles(files);
    await ref
        .read(backupSettingsRepositoryProvider)
        .setLastBackupShareAt(DateTime.now());
    ref.invalidate(backupReminderProvider);
    return files.length;
  };
});

/// Reminder state for the home banner. Null means "do not show".
class BackupReminder {
  /// Days since the last backup share; null when never shared.
  final int? daysSinceLastShare;

  const BackupReminder({this.daysSinceLastShare});
}

final backupReminderProvider = FutureProvider<BackupReminder?>((ref) async {
  const remindAfter = Duration(days: 7);
  final repo = ref.watch(backupSettingsRepositoryProvider);
  final now = DateTime.now();

  final snoozedAt = await repo.reminderSnoozedAt();
  if (snoozedAt != null && now.difference(snoozedAt) < remindAfter) {
    return null;
  }

  final lastShareAt = await repo.lastBackupShareAt();
  if (lastShareAt == null) return const BackupReminder();

  final elapsed = now.difference(lastShareAt);
  if (elapsed < remindAfter) return null;
  return BackupReminder(daysSinceLastShare: elapsed.inDays);
});
