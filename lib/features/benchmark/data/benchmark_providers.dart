import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ads/ad_providers.dart';
import 'benchmark_media_services.dart';
import 'benchmark_repository.dart';
import '../domain/benchmark.dart';

final benchmarkRepositoryProvider = Provider((ref) => BenchMarkRepository());

final benchmarkPhotoStorageProvider = Provider(
  (ref) => BenchmarkPhotoStorage(),
);

final benchmarkImagePickerProvider = Provider((ref) => BenchmarkImagePicker());

final benchmarkLocationServiceProvider = Provider(
  (ref) => BenchmarkLocationService(),
);

final benchmarkMapLauncherProvider = Provider((ref) => BenchmarkMapLauncher());

final benchmarkClipboardProvider = Provider((ref) => BenchmarkClipboard());

final benchmarkProActionServiceProvider = Provider(
  (ref) => BenchmarkProActionService(
    proAccess: () => ref.read(adsRemovedProvider.future),
    locationService: ref.read(benchmarkLocationServiceProvider),
    imagePicker: ref.read(benchmarkImagePickerProvider),
    photoStorage: ref.read(benchmarkPhotoStorageProvider),
    mapLauncher: ref.read(benchmarkMapLauncherProvider),
    clipboard: ref.read(benchmarkClipboardProvider),
  ),
);

final benchmarkListProvider =
    AsyncNotifierProvider.family<BenchmarkListNotifier, List<BenchMark>, int>(
      BenchmarkListNotifier.new,
    );

class BenchmarkListNotifier extends FamilyAsyncNotifier<List<BenchMark>, int> {
  @override
  Future<List<BenchMark>> build(int projectId) async {
    final repo = ref.read(benchmarkRepositoryProvider);
    return repo.getByProjectId(projectId);
  }

  Future<void> addBenchmark(
    String name,
    double elevation,
    String? description, {
    String? locationHint,
    String? protectionNote,
    DateTime? lastVerifiedAt,
    BenchMarkStatus status = BenchMarkStatus.available,
    BenchMarkKind kind = BenchMarkKind.bm,
  }) async {
    final repo = ref.read(benchmarkRepositoryProvider);
    await repo.create(
      BenchMark(
        projectId: arg,
        name: name,
        elevation: elevation,
        description: description,
        locationHint: locationHint,
        protectionNote: protectionNote,
        lastVerifiedAt: lastVerifiedAt,
        status: status,
        kind: kind,
      ),
    );
    ref.invalidateSelf();
  }

  Future<void> updateBenchmark(BenchMark bm) async {
    final repo = ref.read(benchmarkRepositoryProvider);
    await repo.update(bm);
    ref.invalidateSelf();
  }

  Future<void> deleteBenchmark(int id) async {
    final repo = ref.read(benchmarkRepositoryProvider);
    final benchmark = await repo.getById(id);
    await repo.delete(id);
    await ref
        .read(benchmarkPhotoStorageProvider)
        .deletePhoto(benchmark?.photoPath);
    ref.invalidateSelf();
  }
}
