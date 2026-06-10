import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';

class ExportHistoryRecord {
  final String fileName;
  final String fieldBookTitle;
  final String format;
  final DateTime exportedAt;

  const ExportHistoryRecord({
    required this.fileName,
    required this.fieldBookTitle,
    required this.format,
    required this.exportedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fieldBookTitle': fieldBookTitle,
      'format': format,
      'exportedAt': exportedAt.toIso8601String(),
    };
  }

  factory ExportHistoryRecord.fromJson(Map<String, dynamic> json) {
    return ExportHistoryRecord(
      fileName: json['fileName'] as String,
      fieldBookTitle: json['fieldBookTitle'] as String,
      format: json['format'] as String,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
    );
  }
}

class ExportHistoryRepository {
  static const _settingsKey = 'export_history_records';
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> record(ExportHistoryRecord record) async {
    final records = await all();
    final next = [record, ...records].take(30).toList();
    await _save(next);
  }

  Future<List<ExportHistoryRecord>> all() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_settingsKey],
      limit: 1,
    );
    if (rows.isEmpty) return const [];
    final decoded = jsonDecode(rows.first['value'] as String) as List<dynamic>;
    return decoded
        .map(
          (item) => ExportHistoryRecord.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> clear() async {
    await _save(const []);
  }

  Future<void> _save(List<ExportHistoryRecord> records) async {
    final db = await _dbHelper.database;
    await db.insert('app_settings', {
      'key': _settingsKey,
      'value': jsonEncode(records.map((record) => record.toJson()).toList()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

class MemoryExportHistoryRepository {
  final List<ExportHistoryRecord> _records = [];

  void record(ExportHistoryRecord record) {
    _records.insert(0, record);
  }

  List<ExportHistoryRecord> all() {
    return List<ExportHistoryRecord>.unmodifiable(_records);
  }

  void clear() {
    _records.clear();
  }
}
