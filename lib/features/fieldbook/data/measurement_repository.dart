import '../../../core/database/database_helper.dart';
import '../domain/measurement.dart';

class MeasurementRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> create(Measurement measurement) async {
    final db = await _dbHelper.database;
    return await db.insert('measurements', measurement.toMap());
  }

  Future<List<Measurement>> getByFieldBookId(int fieldBookId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'measurements',
      where: 'field_book_id = ?',
      whereArgs: [fieldBookId],
      orderBy: 'order_index ASC',
    );
    return maps.map((map) => Measurement.fromMap(map)).toList();
  }

  Future<int> update(Measurement measurement) async {
    final db = await _dbHelper.database;
    return await db.update(
      'measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('measurements', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteByFieldBookId(int fieldBookId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'measurements',
      where: 'field_book_id = ?',
      whereArgs: [fieldBookId],
    );
  }

  Future<void> updateAll(List<Measurement> measurements) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final m in measurements) {
      batch.update(
        'measurements',
        m.toMap(),
        where: 'id = ?',
        whereArgs: [m.id],
      );
    }
    await batch.commit(noResult: true);
  }
}
