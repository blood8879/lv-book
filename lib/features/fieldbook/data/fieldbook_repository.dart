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

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('field_books', where: 'id = ?', whereArgs: [id]);
  }
}
