import '../../../core/database/database_helper.dart';
import '../domain/benchmark.dart';

class BenchMarkRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> create(BenchMark bm) async {
    final db = await _dbHelper.database;
    return await db.insert('benchmarks', bm.toMap());
  }

  Future<List<BenchMark>> getByProjectId(int projectId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'benchmarks',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'name ASC',
    );
    return maps.map((map) => BenchMark.fromMap(map)).toList();
  }

  Future<BenchMark?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('benchmarks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return BenchMark.fromMap(maps.first);
  }

  Future<int> update(BenchMark bm) async {
    final db = await _dbHelper.database;
    return await db.update(
      'benchmarks',
      bm.toMap(),
      where: 'id = ?',
      whereArgs: [bm.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // Explicit cleanup in addition to ON DELETE SET NULL.
      await txn.update(
        'field_books',
        {'start_bm_id': null},
        where: 'start_bm_id = ?',
        whereArgs: [id],
      );
      return await txn.delete('benchmarks', where: 'id = ?', whereArgs: [id]);
    });
  }
}
