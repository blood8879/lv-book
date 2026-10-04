import '../../../core/database/database_helper.dart';
import '../domain/project.dart';

class ProjectRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> create(Project project) async {
    final db = await _dbHelper.database;
    return await db.insert('projects', project.toMap());
  }

  Future<List<Project>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('projects', orderBy: 'updated_at DESC');
    return maps.map((map) => Project.fromMap(map)).toList();
  }

  Future<Project?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Project.fromMap(maps.first);
  }

  Future<int> update(Project project) async {
    final db = await _dbHelper.database;
    return await db.update(
      'projects',
      project.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // Explicit child cleanup in addition to ON DELETE CASCADE.
      await txn.delete(
        'measurements',
        where:
            'field_book_id IN (SELECT id FROM field_books WHERE project_id = ?)',
        whereArgs: [id],
      );
      await txn.delete('field_books', where: 'project_id = ?', whereArgs: [id]);
      await txn.delete('benchmarks', where: 'project_id = ?', whereArgs: [id]);
      return await txn.delete('projects', where: 'id = ?', whereArgs: [id]);
    });
  }
}
