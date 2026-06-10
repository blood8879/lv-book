import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lv_book/features/benchmark/data/benchmark_media_services.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';

void main() {
  test(
    'photo storage persists relative paths without deleting previous files',
    () async {
      final temp = await Directory.systemTemp.createTemp('lv-book-photo-test-');
      addTearDown(() => temp.delete(recursive: true));
      final sourceA = File('${temp.path}/source-a.jpg')..writeAsStringSync('A');
      final sourceB = File('${temp.path}/source-b.jpg')..writeAsStringSync('B');
      final storage = BenchmarkPhotoStorage(
        rootDirectoryProvider: () async => temp,
      );

      final first = await storage.persistPhoto(
        projectId: 4,
        benchmarkId: 9,
        sourcePath: sourceA.path,
        now: DateTime(2026, 6, 9, 12),
      );
      final second = await storage.persistPhoto(
        projectId: 4,
        benchmarkId: 9,
        sourcePath: sourceB.path,
        previousRelativePath: first,
        now: DateTime(2026, 6, 9, 12, 1),
      );

      expect(first, startsWith('benchmark_photos/project_4/benchmark_9_'));
      expect(second, startsWith('benchmark_photos/project_4/benchmark_9_'));
      expect(second, isNot(first));
      expect(File('${temp.path}/$first').readAsStringSync(), 'A');
      expect(File('${temp.path}/$second').readAsStringSync(), 'B');
    },
  );

  test(
    'Pro action service blocks free users before location side effects',
    () async {
      var locationCalled = false;
      var updateCalled = false;
      final actions = BenchmarkProActionService(
        proAccess: () async => false,
        locationService: BenchmarkLocationService(
          isServiceEnabled: () async {
            locationCalled = true;
            return true;
          },
        ),
        imagePicker: BenchmarkImagePicker(),
        photoStorage: BenchmarkPhotoStorage(),
        mapLauncher: BenchmarkMapLauncher(),
        clipboard: BenchmarkClipboard(),
      );

      await expectLater(
        actions.captureCoordinate(
          benchmark: BenchMark(
            id: 1,
            projectId: 1,
            name: 'TBM.1',
            elevation: 1,
          ),
          updateBenchmark: (_) async {
            updateCalled = true;
          },
        ),
        throwsA(isA<BenchmarkProActionException>()),
      );
      expect(locationCalled, isFalse);
      expect(updateCalled, isFalse);
    },
  );

  test('Pro action service deletes replaced photo after DB update', () async {
    final temp = await Directory.systemTemp.createTemp('lv-book-photo-action-');
    addTearDown(() => temp.delete(recursive: true));
    final oldSource = File('${temp.path}/old.jpg')..writeAsStringSync('old');
    final newSource = File('${temp.path}/new.jpg')..writeAsStringSync('new');
    final storage = BenchmarkPhotoStorage(
      rootDirectoryProvider: () async => temp,
    );
    final oldPath = await storage.persistPhoto(
      projectId: 1,
      benchmarkId: 1,
      sourcePath: oldSource.path,
      now: DateTime(2026, 6, 9, 10),
    );
    final actions = _buildProActions(
      imagePicker: _FakeBenchmarkImagePicker(newSource.path),
      photoStorage: storage,
    );
    var oldExistedDuringUpdate = false;

    final updated = await actions.attachPhoto(
      benchmark: BenchMark(
        id: 1,
        projectId: 1,
        name: 'TBM.1',
        elevation: 1,
        photoPath: oldPath,
      ),
      source: ImageSource.gallery,
      updateBenchmark: (benchmark) async {
        oldExistedDuringUpdate = File('${temp.path}/$oldPath').existsSync();
      },
      capturedAt: DateTime(2026, 6, 9, 11),
    );

    expect(updated!.photoPath, isNot(oldPath));
    expect(oldExistedDuringUpdate, isTrue);
    expect(File('${temp.path}/$oldPath').existsSync(), isFalse);
    expect(File('${temp.path}/${updated.photoPath}').readAsStringSync(), 'new');
  });

  test(
    'Pro action service clears DB state before deleting removed photo',
    () async {
      final temp = await Directory.systemTemp.createTemp(
        'lv-book-photo-remove-',
      );
      addTearDown(() => temp.delete(recursive: true));
      final source = File('${temp.path}/old.jpg')..writeAsStringSync('old');
      final storage = BenchmarkPhotoStorage(
        rootDirectoryProvider: () async => temp,
      );
      final oldPath = await storage.persistPhoto(
        projectId: 1,
        benchmarkId: 1,
        sourcePath: source.path,
      );
      final actions = _buildProActions(photoStorage: storage);
      var oldExistedDuringUpdate = false;
      BenchMark? dbBenchmark;

      await actions.removePhoto(
        benchmark: BenchMark(
          id: 1,
          projectId: 1,
          name: 'TBM.1',
          elevation: 1,
          photoPath: oldPath,
        ),
        updateBenchmark: (benchmark) async {
          dbBenchmark = benchmark;
          oldExistedDuringUpdate = File('${temp.path}/$oldPath').existsSync();
        },
      );

      expect(dbBenchmark!.photoPath, isNull);
      expect(oldExistedDuringUpdate, isTrue);
      expect(File('${temp.path}/$oldPath').existsSync(), isFalse);
    },
  );

  test(
    'map launcher builds fallback URL and reports launcher failure',
    () async {
      final launched = <Uri>[];
      final launcher = BenchmarkMapLauncher(
        launchUrl: (uri) async {
          launched.add(uri);
          return false;
        },
      );
      final bm = BenchMark(
        projectId: 1,
        name: 'TBM.1',
        elevation: 10,
        latitude: 37.5665,
        longitude: 126.978,
      );

      await expectLater(
        launcher.openMap(bm),
        throwsA(
          isA<BenchmarkMapLaunchException>().having(
            (error) => error.message,
            'message',
            '지도 앱을 열 수 없습니다. 좌표를 복사해 사용하세요.',
          ),
        ),
      );
      expect(launched.map((uri) => uri.scheme), ['geo', 'https']);
      expect(launched.last.queryParameters['query'], '37.566500,126.978000');
    },
  );

  test('location capture denial returns controlled Korean message', () async {
    final service = BenchmarkLocationService(
      isServiceEnabled: () async => true,
      checkPermission: () async => BenchmarkLocationPermission.deniedForever,
      requestPermission: () async => BenchmarkLocationPermission.deniedForever,
      getCurrentPosition: () async => throw StateError('must not run'),
    );

    await expectLater(
      service.currentPosition(),
      throwsA(
        isA<BenchmarkLocationException>().having(
          (error) => error.message,
          'message',
          '위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용하세요.',
        ),
      ),
    );
  });
}

BenchmarkProActionService _buildProActions({
  BenchmarkImagePicker? imagePicker,
  BenchmarkPhotoStorage? photoStorage,
}) {
  return BenchmarkProActionService(
    proAccess: () async => true,
    locationService: BenchmarkLocationService(),
    imagePicker: imagePicker ?? BenchmarkImagePicker(),
    photoStorage: photoStorage ?? BenchmarkPhotoStorage(),
    mapLauncher: BenchmarkMapLauncher(),
    clipboard: BenchmarkClipboard(),
  );
}

class _FakeBenchmarkImagePicker extends BenchmarkImagePicker {
  final String? sourcePath;

  _FakeBenchmarkImagePicker(this.sourcePath);

  @override
  Future<String?> pickPhotoPath({required ImageSource source}) async {
    return sourcePath;
  }
}
