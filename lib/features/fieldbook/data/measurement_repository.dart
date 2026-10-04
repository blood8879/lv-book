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

  /// Atomically replaces every measurement of [fieldBookId] with
  /// [measurements] (ids are ignored and re-assigned). When [startElevation]
  /// is given, the field book's start elevation is updated in the same
  /// transaction so edits to 시작 표고 are never lost.
  Future<void> replaceForFieldBook(
    int fieldBookId,
    List<Measurement> measurements, {
    double? startElevation,
  }) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'measurements',
        where: 'field_book_id = ?',
        whereArgs: [fieldBookId],
      );
      final batch = txn.batch();
      for (final m in measurements) {
        final map = Map<String, dynamic>.from(m.toMap())
          ..remove('id')
          ..['field_book_id'] = fieldBookId;
        batch.insert('measurements', map);
      }
      if (startElevation != null) {
        batch.update(
          'field_books',
          {'start_elevation': startElevation},
          where: 'id = ?',
          whereArgs: [fieldBookId],
        );
      }
      await batch.commit(noResult: true);
    });
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
