import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../domain/peg_test_record.dart';

/// Instrument / observer to prefill on the peg test screen.
typedef PegTestMetadata = ({String? instrument, String? observer});

/// CRUD for saved two-peg tests (`peg_tests`), newest first.
///
/// The database accessor is injectable so tests can supply an in-memory
/// (ffi) database, like `QuickMemoRepository`.
class PegTestRecordRepository {
  static const table = 'peg_tests';

  final Future<Database> Function() _databaseProvider;

  PegTestRecordRepository({Future<Database> Function()? databaseProvider})
    : _databaseProvider =
          databaseProvider ?? (() => DatabaseHelper.instance.database);

  Future<int> create(PegTestRecord record) async {
    final db = await _databaseProvider();
    final map = record.toMap()..remove('id');
    return db.insert(table, map);
  }

  Future<List<PegTestRecord>> list() async {
    final db = await _databaseProvider();
    return listWith(db);
  }

  Future<PegTestRecord?> getById(int id) async {
    final db = await _databaseProvider();
    final rows = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : PegTestRecord.fromMap(rows.first);
  }

  Future<int> delete(int id) async {
    final db = await _databaseProvider();
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  /// Quick reuse for a new test: the latest instrument / observer typed in a
  /// saved peg test, else the latest field book's instrument / surveyor.
  Future<PegTestMetadata> lastMetadata() async {
    final db = await _databaseProvider();
    Future<String?> latest(String from, String column, String orderBy) async {
      final rows = await db.query(
        from,
        columns: [column],
        where: "$column IS NOT NULL AND TRIM($column) != ''",
        orderBy: orderBy,
        limit: 1,
      );
      return rows.isEmpty
          ? null
          : PegTestRecord.blankToNull(rows.first[column] as String?);
    }

    const pegOrder = 'created_at DESC, id DESC';
    const bookOrder = 'created_at DESC, id DESC';
    return (
      instrument:
          await latest(table, 'instrument', pegOrder) ??
          await latest('field_books', 'instrument', bookOrder),
      observer:
          await latest(table, 'observer', pegOrder) ??
          await latest('field_books', 'surveyor', bookOrder),
    );
  }

  static Future<List<PegTestRecord>> listWith(DatabaseExecutor db) async {
    final rows = await db.query(table, orderBy: 'created_at DESC, id DESC');
    return rows.map(PegTestRecord.fromMap).toList();
  }

  /// Inserts [record] unless an identical one (same time and values) exists.
  /// Returns true when inserted. Used by backup restore, so restoring the
  /// same backup twice (or several project backups that each carry the
  /// records) does not duplicate them.
  static Future<bool> insertIfAbsent(
    DatabaseExecutor db,
    PegTestRecord record,
  ) async {
    final candidates = await db.query(
      table,
      where: 'created_at = ?',
      whereArgs: [record.createdAt.toIso8601String()],
    );
    if (candidates.map(PegTestRecord.fromMap).any(record.sameContentAs)) {
      return false;
    }
    await db.insert(table, record.toMap()..remove('id'));
    return true;
  }
}

final pegTestRecordRepositoryProvider = Provider<PegTestRecordRepository>(
  (ref) => PegTestRecordRepository(),
);

/// Saved peg tests, newest first.
class PegTestRecordListNotifier extends AsyncNotifier<List<PegTestRecord>> {
  PegTestRecordRepository get _repository =>
      ref.read(pegTestRecordRepositoryProvider);

  @override
  Future<List<PegTestRecord>> build() => _repository.list();

  Future<int> add(PegTestRecord record) async {
    final id = await _repository.create(record);
    state = AsyncData(await _repository.list());
    return id;
  }

  Future<void> delete(PegTestRecord record) async {
    final id = record.id;
    if (id != null) await _repository.delete(id);
    state = AsyncData(await _repository.list());
  }
}

final pegTestRecordListProvider =
    AsyncNotifierProvider<PegTestRecordListNotifier, List<PegTestRecord>>(
      PegTestRecordListNotifier.new,
    );
