import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fieldbook_repository.dart';
import 'measurement_repository.dart';
import '../domain/fieldbook.dart';
import '../domain/measurement.dart';
import '../../../core/utils/calculation.dart';

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

  /// Recalculate all IH/GH values from a given starting elevation
  List<Measurement> recalculate(
    List<Measurement> measurements,
    double startElevation,
  ) {
    final result = <Measurement>[];
    double currentIH = 0;
    bool firstPoint = true;

    for (final m in measurements) {
      if (firstPoint && m.bs != null) {
        // First point (BM): IH = start elevation + BS
        final ih = LevelCalculation.calculateIH(startElevation, m.bs!);
        result.add(m.copyWith(ih: ih, gh: startElevation));
        currentIH = ih;
        firstPoint = false;
      } else if (m.type == MeasurementType.tp) {
        // TP: GH = currentIH - FS, then new IH = GH + BS
        double? gh;
        double? ih;
        if (m.fs != null) {
          gh = LevelCalculation.calculateGH(currentIH, m.fs!);
        }
        if (gh != null && m.bs != null) {
          ih = LevelCalculation.calculateIH(gh, m.bs!);
          currentIH = ih;
        }
        result.add(m.copyWith(ih: ih, gh: gh));
      } else {
        // Normal point: GH = currentIH - FS
        double? gh;
        if (m.fs != null) {
          gh = LevelCalculation.calculateGH(currentIH, m.fs!);
        }
        result.add(m.copyWith(gh: gh));
      }
    }
    return result;
  }

  Future<void> addMeasurement({
    required String stationName,
    required MeasurementType type,
    double? bs,
    double? fs,
    required double startElevation,
  }) async {
    final repo = ref.read(measurementRepositoryProvider);
    final current = await repo.getByFieldBookId(arg);
    final orderIndex = current.isEmpty ? 0 : current.last.orderIndex + 1;

    final newMeasurement = Measurement(
      fieldBookId: arg,
      orderIndex: orderIndex,
      stationName: stationName,
      type: type,
      bs: bs,
      fs: fs,
    );

    final updated = [...current, newMeasurement];
    final recalculated = recalculate(updated, startElevation);

    // Save the last one (new) and update any that changed
    final lastRecalc = recalculated.last;
    await repo.create(lastRecalc);

    // If it's a TP, we need to recalculate subsequent entries (none in this case since it's the last)
    ref.invalidateSelf();
  }

  Future<void> updateMeasurement({
    required Measurement measurement,
    required double startElevation,
  }) async {
    final repo = ref.read(measurementRepositoryProvider);
    await repo.update(measurement);

    // Recalculate all
    final all = await repo.getByFieldBookId(arg);
    final recalculated = recalculate(all, startElevation);
    await repo.updateAll(recalculated);

    ref.invalidateSelf();
  }

  Future<void> deleteMeasurement({
    required int id,
    required double startElevation,
  }) async {
    final repo = ref.read(measurementRepositoryProvider);
    await repo.delete(id);

    // Recalculate remaining
    final all = await repo.getByFieldBookId(arg);
    if (all.isNotEmpty) {
      // Reindex
      final reindexed = <Measurement>[];
      for (int i = 0; i < all.length; i++) {
        reindexed.add(all[i].copyWith(orderIndex: i));
      }
      final recalculated = recalculate(reindexed, startElevation);
      await repo.updateAll(recalculated);
    }

    ref.invalidateSelf();
  }

  Future<void> recalculateAll(double startElevation) async {
    final repo = ref.read(measurementRepositoryProvider);
    final all = await repo.getByFieldBookId(arg);
    if (all.isNotEmpty) {
      final recalculated = recalculate(all, startElevation);
      await repo.updateAll(recalculated);
      ref.invalidateSelf();
    }
  }
}
