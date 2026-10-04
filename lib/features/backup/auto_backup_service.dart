import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import '../project/data/project_repository.dart';
import 'project_backup_service.dart';

/// Stores backup-related timestamps in the app_settings table.
class BackupSettingsRepository {
  static const _lastAutoBackupAtKey = 'last_auto_backup_at';
  static const _lastBackupShareAtKey = 'last_backup_share_at';
  static const _reminderSnoozedAtKey = 'backup_reminder_snoozed_at';

  Future<DateTime?> lastAutoBackupAt() => _getDate(_lastAutoBackupAtKey);

  Future<void> setLastAutoBackupAt(DateTime value) =>
      _setValue(_lastAutoBackupAtKey, value.toIso8601String());

  Future<DateTime?> lastBackupShareAt() => _getDate(_lastBackupShareAtKey);

  Future<void> setLastBackupShareAt(DateTime value) =>
      _setValue(_lastBackupShareAtKey, value.toIso8601String());

  Future<DateTime?> reminderSnoozedAt() => _getDate(_reminderSnoozedAtKey);

  Future<void> setReminderSnoozedAt(DateTime value) =>
      _setValue(_reminderSnoozedAtKey, value.toIso8601String());

  Future<DateTime?> _getDate(String key) async {
    final value = await _getValue(key);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<String?> _getValue(String key) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> _setValue(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

/// Periodically snapshots every project to local JSON files so a broken DB or
/// a bad edit is recoverable. Snapshots live under
/// `<documents>/auto_backups/<timestamp>/<project>.json` — the same format as
/// the shared backup, so any snapshot file restores through the existing
/// '백업 JSON 복원' flow.
class AutoBackupService {
  static const backupDirName = 'auto_backups';
  static const defaultInterval = Duration(hours: 24);
  static const defaultMaxSnapshots = 5;

  final BackupSettingsRepository _settings;
  final ProjectBackupService _backupService;
  final ProjectRepository _projectRepository;
  final Future<Directory> Function() _rootDirectory;
  final DateTime Function() _now;

  AutoBackupService({
    BackupSettingsRepository? settings,
    ProjectBackupService? backupService,
    ProjectRepository? projectRepository,
    Future<Directory> Function()? rootDirectory,
    DateTime Function()? now,
  }) : _settings = settings ?? BackupSettingsRepository(),
       _backupService = backupService ?? ProjectBackupService(),
       _projectRepository = projectRepository ?? ProjectRepository(),
       _rootDirectory = rootDirectory ?? getApplicationDocumentsDirectory,
       _now = now ?? DateTime.now;

  /// Runs a snapshot when the last one is older than [interval].
  /// Returns true when a new snapshot was written.
  Future<bool> runIfDue({
    Duration interval = defaultInterval,
    int maxSnapshots = defaultMaxSnapshots,
  }) async {
    final now = _now();
    final last = await _settings.lastAutoBackupAt();
    if (last != null && now.difference(last) < interval) return false;

    final projects = await _projectRepository.getAll();
    if (projects.isEmpty) return false;

    final root = await _rootDirectory();
    final backupRoot = Directory(p.join(root.path, backupDirName));
    final snapshotDir = Directory(
      p.join(backupRoot.path, _timestampToken(now)),
    );
    await snapshotDir.create(recursive: true);

    for (final project in projects) {
      final id = project.id;
      if (id == null) continue;
      final data = await _backupService.collectProject(id);
      final source = ProjectBackupService.encode(data);
      final fileName = '${_safeFileName(project.name)}_$id.json';
      await File(p.join(snapshotDir.path, fileName)).writeAsString(source);
    }

    await _pruneOldSnapshots(backupRoot, maxSnapshots: maxSnapshots);
    await _settings.setLastAutoBackupAt(now);
    return true;
  }

  Future<void> _pruneOldSnapshots(
    Directory backupRoot, {
    required int maxSnapshots,
  }) async {
    if (!await backupRoot.exists()) return;
    final snapshots =
        (await backupRoot.list().toList()).whereType<Directory>().toList()
          ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    while (snapshots.length > maxSnapshots) {
      final oldest = snapshots.removeAt(0);
      await oldest.delete(recursive: true);
    }
  }

  static String _timestampToken(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}'
        '_${two(value.hour)}${two(value.minute)}${two(value.second)}';
  }

  static String _safeFileName(String value) {
    final sanitized = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return sanitized.isEmpty ? 'project' : sanitized;
  }
}
