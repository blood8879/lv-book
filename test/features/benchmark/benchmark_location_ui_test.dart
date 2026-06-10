import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lv_book/features/ads/ad_providers.dart';
import 'package:lv_book/features/benchmark/data/benchmark_media_services.dart';
import 'package:lv_book/features/benchmark/data/benchmark_providers.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/benchmark/presentation/benchmark_list_screen.dart';

void main() {
  testWidgets(
    'free users see locked Pro location panel without raw coordinates',
    (tester) async {
      await tester.pumpWidget(
        _buildScreen(
          adsRemoved: false,
          benchmarks: [
            BenchMark(
              id: 1,
              projectId: 1,
              name: 'TBM.1',
              elevation: 10,
              kind: BenchMarkKind.tbm,
              latitude: 37.5665,
              longitude: 126.978,
              photoPath: 'benchmark_photos/project_1/tbm.jpg',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('TBM.1'));
      await tester.pumpAndSettle();

      expect(find.text('Pro 위치 기록'), findsOneWidget);
      expect(find.text('Pro 위치 정보 저장됨'), findsOneWidget);
      expect(find.textContaining('37.566500'), findsNothing);
      expect(find.text('현재 좌표 저장'), findsNothing);
    },
  );

  testWidgets('Pro users capture current coordinate into a benchmark', (
    tester,
  ) async {
    final notifier = _BenchmarkNotifier([
      BenchMark(
        id: 1,
        projectId: 1,
        name: 'TBM.2',
        elevation: 20,
        kind: BenchMarkKind.tbm,
      ),
    ]);

    await tester.pumpWidget(
      _buildScreen(
        adsRemoved: true,
        notifier: notifier,
        locationService: BenchmarkLocationService(
          isServiceEnabled: () async => true,
          checkPermission: () async => BenchmarkLocationPermission.whileInUse,
          requestPermission: () async => BenchmarkLocationPermission.whileInUse,
          getCurrentPosition: () async => const BenchmarkPosition(
            latitude: 37.5665,
            longitude: 126.978,
            accuracyM: 3.2,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('TBM.2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('현재 좌표 저장'));
    await tester.pumpAndSettle();

    expect(find.textContaining('37.566500, 126.978000'), findsOneWidget);
    expect(find.textContaining('정확도 3.2m'), findsOneWidget);
    expect(notifier.items.single.latitude, 37.5665);
    expect(notifier.items.single.longitude, 126.978);
  });

  testWidgets('Pro users attach and remove a benchmark photo', (tester) async {
    final notifier = _BenchmarkNotifier([
      BenchMark(
        id: 1,
        projectId: 1,
        name: 'TBM.3',
        elevation: 30,
        kind: BenchMarkKind.tbm,
      ),
    ]);

    await tester.pumpWidget(
      _buildScreen(
        adsRemoved: true,
        notifier: notifier,
        imagePicker: _FakeBenchmarkImagePicker('/tmp/source.jpg'),
        photoStorage: _FakeBenchmarkPhotoStorage(
          'benchmark_photos/project_1/tbm_3.jpg',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('TBM.3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('사진 선택'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('사진 저장됨'), findsOneWidget);
    expect(notifier.items.single.photoPath, contains('tbm_3.jpg'));

    await tester.ensureVisible(find.text('사진 제거'));
    await tester.tap(find.text('사진 제거'));
    await tester.pump();

    expect(notifier.items.single.photoPath, isNull);
  });

  testWidgets('Pro panel shows missing photo file state', (tester) async {
    await tester.pumpWidget(
      _buildScreen(
        adsRemoved: true,
        benchmarks: [
          BenchMark(
            id: 1,
            projectId: 1,
            name: 'TBM.4',
            elevation: 40,
            kind: BenchMarkKind.tbm,
            photoPath: 'benchmark_photos/project_1/missing.jpg',
          ),
        ],
        photoStorage: _FakeBenchmarkPhotoStorage(
          'benchmark_photos/project_1/unused.jpg',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('TBM.4'));
    await tester.pumpAndSettle();

    expect(find.text('사진 파일을 찾을 수 없습니다.'), findsOneWidget);
  });

  testWidgets('Pro map launch failure is shown in Korean', (tester) async {
    await tester.pumpWidget(
      _buildScreen(
        adsRemoved: true,
        benchmarks: [
          BenchMark(
            id: 1,
            projectId: 1,
            name: 'TBM.5',
            elevation: 50,
            kind: BenchMarkKind.tbm,
            latitude: 37.5665,
            longitude: 126.978,
          ),
        ],
        mapLauncher: BenchmarkMapLauncher(launchUrl: (_) async => false),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('TBM.5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('지도 열기'));
    await tester.pumpAndSettle();

    expect(find.text('지도 앱을 열 수 없습니다. 좌표를 복사해 사용하세요.'), findsOneWidget);
  });
}

Widget _buildScreen({
  required bool adsRemoved,
  List<BenchMark>? benchmarks,
  _BenchmarkNotifier? notifier,
  BenchmarkLocationService? locationService,
  BenchmarkImagePicker? imagePicker,
  BenchmarkPhotoStorage? photoStorage,
  BenchmarkMapLauncher? mapLauncher,
}) {
  final activeNotifier = notifier ?? _BenchmarkNotifier(benchmarks ?? const []);
  return ProviderScope(
    overrides: [
      adsRemovedProvider.overrideWith((ref) async => adsRemoved),
      benchmarkListProvider.overrideWith(() => activeNotifier),
      if (locationService != null)
        benchmarkLocationServiceProvider.overrideWithValue(locationService),
      if (imagePicker != null)
        benchmarkImagePickerProvider.overrideWithValue(imagePicker),
      if (photoStorage != null)
        benchmarkPhotoStorageProvider.overrideWithValue(photoStorage),
      if (mapLauncher != null)
        benchmarkMapLauncherProvider.overrideWithValue(mapLauncher),
    ],
    child: const MaterialApp(home: BenchmarkListScreen(projectId: 1)),
  );
}

class _BenchmarkNotifier extends BenchmarkListNotifier {
  List<BenchMark> items;

  _BenchmarkNotifier(this.items);

  @override
  Future<List<BenchMark>> build(int projectId) async => items;

  @override
  Future<void> updateBenchmark(BenchMark bm) async {
    items = [
      for (final item in items)
        if (item.id == bm.id) bm else item,
    ];
    state = AsyncData(items);
  }
}

class _FakeBenchmarkImagePicker extends BenchmarkImagePicker {
  final String? sourcePath;

  _FakeBenchmarkImagePicker(this.sourcePath);

  @override
  Future<String?> pickPhotoPath({required ImageSource source}) async {
    return sourcePath;
  }
}

class _FakeBenchmarkPhotoStorage extends BenchmarkPhotoStorage {
  final String relativePath;
  String? deletedPath;

  _FakeBenchmarkPhotoStorage(this.relativePath);

  @override
  Future<String> persistPhoto({
    required int projectId,
    required int benchmarkId,
    required String sourcePath,
    String? previousRelativePath,
    DateTime? now,
  }) async {
    return relativePath;
  }

  @override
  Future<void> deletePhoto(String? relativePath) async {
    deletedPath = relativePath;
  }

  @override
  Future<File?> photoFile(String? relativePath) async {
    return null;
  }
}
