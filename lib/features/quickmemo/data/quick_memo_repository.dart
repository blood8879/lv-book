import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../domain/quick_memo.dart';

/// CRUD access for standalone quick memos, newest first.
///
/// The database accessor is injectable so tests can supply an in-memory
/// (ffi) database instead of the app's on-device file.
class QuickMemoRepository {
  final Future<Database> Function() _databaseProvider;

  QuickMemoRepository({Future<Database> Function()? databaseProvider})
    : _databaseProvider =
          databaseProvider ?? (() => DatabaseHelper.instance.database);

  Future<int> create(QuickMemo memo) async {
    final db = await _databaseProvider();
    return db.insert('quick_memos', memo.toMap());
  }

  Future<List<QuickMemo>> list() async {
    final db = await _databaseProvider();
    final maps = await db.query(
      'quick_memos',
      orderBy: 'created_at DESC, id DESC',
    );
    return maps.map(QuickMemo.fromMap).toList();
  }

  Future<int> delete(int id) async {
    final db = await _databaseProvider();
    return db.delete('quick_memos', where: 'id = ?', whereArgs: [id]);
  }
}
