import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/ads/ad_settings_repository.dart';
import 'package:lv_book/features/benchmark/data/benchmark_repository.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/export/bulk_export_service.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/pro/pro_settings_repository.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  test(
    'shareFieldBooks package keeps fieldbook and summary filename collisions',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'lvbook_bulk_export_',
      );
      final sharedFiles = <XFile>[];
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final service = BulkExportService(
        adSettingsRepository: _ProAdSettingsRepository(),
        proSettingsRepository: ProSettingsRepository(
          store: MemoryProSettingsStore(),
        ),
        measurementRepository: _MemoryMeasurementRepository({
          1: [
            Measurement(
              fieldBookId: 1,
              orderIndex: 0,
              stationName: 'BM.1',
              bs: 1,
              gh: 100,
            ),
            Measurement(
              fieldBookId: 1,
              orderIndex: 1,
              stationName: 'END',
              fs: 1,
              gh: 100,
            ),
          ],
        }),
        benchMarkRepository: _MemoryBenchMarkRepository(),
        temporaryDirectoryProvider: () async => tempDir,
        shareFiles: (files) async => sharedFiles.addAll(files),
      );

      final count = await service.shareFieldBooks(
        projectName: '현장',
        fieldBooks: [
          FieldBook(
            id: 1,
            projectId: 1,
            title: '현장_요약',
            date: DateTime(2026, 6, 8),
            startElevation: 100,
          ),
        ],
        format: BulkExportFormat.csv,
        includeSummary: true,
        includeManifest: true,
      );

      expect(count, 1);
      expect(sharedFiles, hasLength(1));

      final zipBytes = await File(sharedFiles.single.path).readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final names = archive.files.map((file) => file.name).toSet();

      expect(
        names,
        containsAll(['현장_요약.csv', '현장_요약-2.csv', '현장_manifest.txt']),
      );
      expect(
        archive.files.where((file) => file.name.endsWith('.csv')),
        hasLength(2),
      );
    },
  );
}

class _ProAdSettingsRepository extends AdSettingsRepository {
  @override
  Future<bool> areAdsRemoved() async => true;
}

class _MemoryMeasurementRepository extends MeasurementRepository {
  final Map<int, List<Measurement>> _measurementsByFieldBookId;

  _MemoryMeasurementRepository(this._measurementsByFieldBookId);

  @override
  Future<List<Measurement>> getByFieldBookId(int fieldBookId) async {
    return _measurementsByFieldBookId[fieldBookId] ?? const [];
  }
}

class _MemoryBenchMarkRepository extends BenchMarkRepository {
  @override
  Future<BenchMark?> getById(int id) async => null;
}
