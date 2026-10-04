import '../../../core/database/database_helper.dart';
import '../domain/fieldbook.dart';

class FieldBookRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> create(FieldBook fieldBook) async {
    final db = await _dbHelper.database;
    return await db.insert('field_books', fieldBook.toMap());
  }

  Future<List<FieldBook>> getByProjectId(int projectId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'field_books',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => FieldBook.fromMap(map)).toList();
  }

  Future<FieldBook?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'field_books',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return FieldBook.fromMap(maps.first);
  }

  Future<int> update(FieldBook fieldBook) async {
    final db = await _dbHelper.database;
    return await db.update(
      'field_books',
      fieldBook.toMap(),
      where: 'id = ?',
      whereArgs: [fieldBook.id],
    );
  }

  /// Persists only the closing reference columns, so unsaved edits elsewhere
  /// (e.g. the review panel) are not written as a side effect.
  Future<int> updateClosingReference(FieldBook fieldBook) async {
    final db = await _dbHelper.database;
    return await db.update(
      'field_books',
      {
        'closing_mode': fieldBook.closingMode.name,
        'closing_bm_id': fieldBook.closingBmId,
        'closing_elevation': fieldBook.closingElevation,
      },
      where: 'id = ?',
      whereArgs: [fieldBook.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // Explicit child cleanup in addition to ON DELETE CASCADE.
      await txn.delete(
        'measurements',
        where: 'field_book_id = ?',
        whereArgs: [id],
      );
      return await txn.delete('field_books', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Per-project field-book counts for the home dashboard.
  /// openCount = 검토완료(reviewed)가 아닌 야장 수.
  Future<Map<int, FieldBookProjectStats>> getProjectStats() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT project_id,
             COUNT(*) AS total,
             SUM(CASE WHEN review_status != 'reviewed' THEN 1 ELSE 0 END)
               AS open_count
      FROM field_books
      WHERE project_id IN (SELECT id FROM projects)
      GROUP BY project_id
    ''');
    return {
      for (final row in rows)
        row['project_id'] as int: FieldBookProjectStats(
          total: row['total'] as int? ?? 0,
          openCount: row['open_count'] as int? ?? 0,
        ),
    };
  }

  /// Most recently dated field book across all projects (quick-access).
  Future<FieldBook?> getMostRecent() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'field_books',
      where: 'project_id IN (SELECT id FROM projects)',
      orderBy: 'date DESC, created_at DESC, id DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FieldBook.fromMap(maps.first);
  }
}

class FieldBookProjectStats {
  final int total;
  final int openCount;

  const FieldBookProjectStats({required this.total, required this.openCount});
}
