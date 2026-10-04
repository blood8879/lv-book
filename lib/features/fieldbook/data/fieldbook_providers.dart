import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fieldbook_repository.dart';
import 'measurement_repository.dart';
import '../domain/fieldbook.dart';
import '../domain/measurement.dart';

final fieldBookRepositoryProvider = Provider((ref) => FieldBookRepository());
final measurementRepositoryProvider = Provider(
  (ref) => MeasurementRepository(),
);

// Field book list for a project
final fieldBookListProvider =
    AsyncNotifierProvider.family<FieldBookListNotifier, List<FieldBook>, int>(
      FieldBookListNotifier.new,
    );

class FieldBookListNotifier extends FamilyAsyncNotifier<List<FieldBook>, int> {
  @override
  Future<List<FieldBook>> build(int projectId) async {
    final repo = ref.read(fieldBookRepositoryProvider);
    return repo.getByProjectId(projectId);
  }

  Future<int> addFieldBook(FieldBook fieldBook) async {
    final repo = ref.read(fieldBookRepositoryProvider);
    final id = await repo.create(fieldBook);
    ref.invalidateSelf();
    return id;
  }

  Future<void> updateFieldBook(FieldBook fieldBook) async {
    final repo = ref.read(fieldBookRepositoryProvider);
    await repo.update(fieldBook);
    ref.invalidateSelf();
  }

  Future<void> deleteFieldBook(int id) async {
    final repo = ref.read(fieldBookRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}

// Measurements for a field book
final measurementListProvider =
    AsyncNotifierProvider.family<
      MeasurementListNotifier,
      List<Measurement>,
      int
    >(MeasurementListNotifier.new);

class MeasurementListNotifier
    extends FamilyAsyncNotifier<List<Measurement>, int> {
  @override
  Future<List<Measurement>> build(int fieldBookId) async {
    final repo = ref.read(measurementRepositoryProvider);
    return repo.getByFieldBookId(fieldBookId);
  }
}
