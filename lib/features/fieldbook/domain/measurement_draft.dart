import 'measurement.dart';

abstract class MeasurementDraftStore {
  Future<void> save({
    required int fieldBookId,
    required List<Measurement> rows,
  });

  Future<List<Measurement>> load({required int fieldBookId});

  Future<void> clear({required int fieldBookId});
}

class MemoryMeasurementDraftStore implements MeasurementDraftStore {
  final Map<int, List<Measurement>> _rowsByFieldBookId = {};

  @override
  Future<void> save({
    required int fieldBookId,
    required List<Measurement> rows,
  }) async {
    _rowsByFieldBookId[fieldBookId] = List<Measurement>.from(rows);
  }

  @override
  Future<List<Measurement>> load({required int fieldBookId}) async {
    return List<Measurement>.from(_rowsByFieldBookId[fieldBookId] ?? const []);
  }

  @override
  Future<void> clear({required int fieldBookId}) async {
    _rowsByFieldBookId.remove(fieldBookId);
  }
}
