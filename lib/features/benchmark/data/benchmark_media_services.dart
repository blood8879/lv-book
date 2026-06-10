import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../domain/benchmark.dart';

typedef DirectoryProvider = Future<Directory> Function();
typedef BenchmarkUrlLauncher = Future<bool> Function(Uri uri);
typedef BenchmarkPermissionReader =
    Future<BenchmarkLocationPermission> Function();
typedef BenchmarkPermissionRequester =
    Future<BenchmarkLocationPermission> Function();
typedef BenchmarkServiceEnabledReader = Future<bool> Function();
typedef BenchmarkPositionReader = Future<BenchmarkPosition> Function();
typedef BenchmarkClipboardWriter = Future<void> Function(String value);
typedef BenchmarkProAccessReader = Future<bool> Function();
typedef BenchmarkUpdater = Future<void> Function(BenchMark benchmark);

class BenchmarkPhotoStorage {
  final DirectoryProvider rootDirectoryProvider;

  BenchmarkPhotoStorage({DirectoryProvider? rootDirectoryProvider})
    : rootDirectoryProvider =
          rootDirectoryProvider ?? getApplicationDocumentsDirectory;

  Future<String> persistPhoto({
    required int projectId,
    required int benchmarkId,
    required String sourcePath,
    String? previousRelativePath,
    DateTime? now,
  }) async {
    final root = await rootDirectoryProvider();
    final capturedAt = now ?? DateTime.now();
    final relativeDir = p.join('benchmark_photos', 'project_$projectId');
    final targetDir = Directory(p.join(root.path, relativeDir));
    await targetDir.create(recursive: true);

    final extension = _safeExtension(sourcePath);
    final fileName =
        'benchmark_${benchmarkId}_${capturedAt.microsecondsSinceEpoch}$extension';
    final relativePath = p.join(relativeDir, fileName);
    final targetFile = File(p.join(root.path, relativePath));
    await File(sourcePath).copy(targetFile.path);

    return relativePath;
  }

  Future<bool> exists(String relativePath) async {
    return (await photoFile(relativePath)) != null;
  }

  Future<File?> photoFile(String? relativePath) async {
    if (!_isSafeRelativePath(relativePath)) return null;
    final root = await rootDirectoryProvider();
    final file = File(p.join(root.path, relativePath));
    if (await file.exists()) return file;
    return null;
  }

  Future<void> deletePhoto(String? relativePath) async {
    if (!_isSafeRelativePath(relativePath)) return;
    final root = await rootDirectoryProvider();
    final file = File(p.join(root.path, relativePath));
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _safeExtension(String sourcePath) {
    final extension = p.extension(sourcePath).toLowerCase();
    if (extension == '.jpeg' || extension == '.jpg' || extension == '.png') {
      return extension;
    }
    return '.jpg';
  }

  bool _isSafeRelativePath(String? relativePath) {
    if (relativePath == null || relativePath.trim().isEmpty) return false;
    if (p.posix.isAbsolute(relativePath) ||
        p.windows.isAbsolute(relativePath)) {
      return false;
    }
    final normalizedPath = relativePath.replaceAll('\\', p.separator);
    final segments = p
        .split(normalizedPath)
        .where((segment) => segment.isNotEmpty);
    return !segments.contains('..');
  }
}

class BenchmarkImagePicker {
  final ImagePicker _picker;

  BenchmarkImagePicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  Future<String?> pickPhotoPath({required ImageSource source}) async {
    final image = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 75,
    );
    return image?.path;
  }

  Future<String?> retrieveLostPhotoPath() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return null;
    return response.files?.firstOrNull?.path;
  }
}

enum BenchmarkLocationPermission { denied, deniedForever, whileInUse, always }

class BenchmarkPosition {
  final double latitude;
  final double longitude;
  final double accuracyM;

  const BenchmarkPosition({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
  });
}

class BenchmarkLocationException implements Exception {
  final String message;

  const BenchmarkLocationException(this.message);

  @override
  String toString() => message;
}

class BenchmarkLocationService {
  final BenchmarkServiceEnabledReader isServiceEnabled;
  final BenchmarkPermissionReader checkPermission;
  final BenchmarkPermissionRequester requestPermission;
  final BenchmarkPositionReader getCurrentPosition;

  BenchmarkLocationService({
    BenchmarkServiceEnabledReader? isServiceEnabled,
    BenchmarkPermissionReader? checkPermission,
    BenchmarkPermissionRequester? requestPermission,
    BenchmarkPositionReader? getCurrentPosition,
  }) : isServiceEnabled =
           isServiceEnabled ?? geo.Geolocator.isLocationServiceEnabled,
       checkPermission =
           checkPermission ??
           (() async =>
               _fromGeoPermission(await geo.Geolocator.checkPermission())),
       requestPermission =
           requestPermission ??
           (() async =>
               _fromGeoPermission(await geo.Geolocator.requestPermission())),
       getCurrentPosition =
           getCurrentPosition ??
           (() async {
             final position = await geo.Geolocator.getCurrentPosition(
               locationSettings: const geo.LocationSettings(
                 accuracy: geo.LocationAccuracy.high,
                 timeLimit: Duration(seconds: 12),
               ),
             );
             return BenchmarkPosition(
               latitude: position.latitude,
               longitude: position.longitude,
               accuracyM: position.accuracy,
             );
           });

  Future<BenchmarkPosition> currentPosition() async {
    if (!await isServiceEnabled()) {
      throw const BenchmarkLocationException('기기 위치 서비스가 꺼져 있습니다.');
    }

    var permission = await checkPermission();
    if (permission == BenchmarkLocationPermission.denied) {
      permission = await requestPermission();
    }
    if (permission == BenchmarkLocationPermission.denied) {
      throw const BenchmarkLocationException('위치 권한이 거부되었습니다.');
    }
    if (permission == BenchmarkLocationPermission.deniedForever) {
      throw const BenchmarkLocationException(
        '위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용하세요.',
      );
    }

    return getCurrentPosition();
  }

  static BenchmarkLocationPermission _fromGeoPermission(
    geo.LocationPermission permission,
  ) {
    switch (permission) {
      case geo.LocationPermission.denied:
        return BenchmarkLocationPermission.denied;
      case geo.LocationPermission.deniedForever:
        return BenchmarkLocationPermission.deniedForever;
      case geo.LocationPermission.whileInUse:
        return BenchmarkLocationPermission.whileInUse;
      case geo.LocationPermission.always:
        return BenchmarkLocationPermission.always;
      case geo.LocationPermission.unableToDetermine:
        return BenchmarkLocationPermission.denied;
    }
  }
}

class BenchmarkMapLaunchException implements Exception {
  final String message;

  const BenchmarkMapLaunchException(this.message);

  @override
  String toString() => message;
}

class BenchmarkMapLauncher {
  static const failureMessage = '지도 앱을 열 수 없습니다. 좌표를 복사해 사용하세요.';

  final BenchmarkUrlLauncher launchUrl;

  BenchmarkMapLauncher({BenchmarkUrlLauncher? launchUrl})
    : launchUrl = launchUrl ?? ((uri) => launchUrlExternal(uri));

  Future<void> openMap(BenchMark benchmark) async {
    final lat = benchmark.latitude;
    final lon = benchmark.longitude;
    if (lat == null || lon == null) {
      throw const BenchmarkMapLaunchException('저장된 좌표가 없습니다.');
    }

    final coordinate = '${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}';
    final geoUri = Uri.parse(
      'geo:$coordinate?q=$coordinate(${Uri.encodeComponent(benchmark.mapQueryLabel)})',
    );
    if (await launchUrl(geoUri)) return;

    final fallback = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': coordinate,
    });
    if (await launchUrl(fallback)) return;

    throw const BenchmarkMapLaunchException(failureMessage);
  }

  static Future<bool> launchUrlExternal(Uri uri) {
    return url_launcher.launchUrl(
      uri,
      mode: url_launcher.LaunchMode.externalApplication,
    );
  }
}

class BenchmarkClipboard {
  final BenchmarkClipboardWriter writer;

  BenchmarkClipboard({BenchmarkClipboardWriter? writer})
    : writer =
          writer ?? ((value) => Clipboard.setData(ClipboardData(text: value)));

  Future<void> copyCoordinate(BenchMark benchmark) async {
    final text = benchmark.copyCoordinateText;
    if (text == null) {
      throw const BenchmarkMapLaunchException('저장된 좌표가 없습니다.');
    }
    await writer(text);
  }
}

class BenchmarkProActionException implements Exception {
  final String message;

  const BenchmarkProActionException(this.message);

  @override
  String toString() => message;
}

class BenchmarkProActionService {
  final BenchmarkProAccessReader proAccess;
  final BenchmarkLocationService locationService;
  final BenchmarkImagePicker imagePicker;
  final BenchmarkPhotoStorage photoStorage;
  final BenchmarkMapLauncher mapLauncher;
  final BenchmarkClipboard clipboard;

  BenchmarkProActionService({
    required this.proAccess,
    required this.locationService,
    required this.imagePicker,
    required this.photoStorage,
    required this.mapLauncher,
    required this.clipboard,
  });

  Future<BenchMark> captureCoordinate({
    required BenchMark benchmark,
    required BenchmarkUpdater updateBenchmark,
    DateTime? capturedAt,
  }) async {
    await _ensurePro();
    final position = await locationService.currentPosition();
    final now = capturedAt ?? DateTime.now();
    final updated = benchmark.copyWith(
      latitude: position.latitude,
      longitude: position.longitude,
      coordinateAccuracyM: position.accuracyM,
      coordinateCapturedAt: now,
      lastVerifiedAt: now,
    );
    await updateBenchmark(updated);
    return updated;
  }

  Future<BenchMark?> attachPhoto({
    required BenchMark benchmark,
    required ImageSource source,
    required BenchmarkUpdater updateBenchmark,
    DateTime? capturedAt,
  }) async {
    await _ensurePro();
    final benchmarkId = benchmark.id;
    if (benchmarkId == null) {
      throw const BenchmarkProActionException('저장된 BM만 사진을 추가할 수 있습니다.');
    }

    final sourcePath = await imagePicker.pickPhotoPath(source: source);
    if (sourcePath == null) return null;

    final relativePath = await photoStorage.persistPhoto(
      projectId: benchmark.projectId,
      benchmarkId: benchmarkId,
      sourcePath: sourcePath,
      now: capturedAt,
    );
    final updated = benchmark.copyWith(
      photoPath: relativePath,
      lastVerifiedAt: capturedAt ?? DateTime.now(),
    );

    try {
      await updateBenchmark(updated);
    } catch (_) {
      await _deletePhotoBestEffort(relativePath);
      rethrow;
    }

    await _deletePhotoBestEffort(benchmark.photoPath);
    return updated;
  }

  Future<BenchMark> removePhoto({
    required BenchMark benchmark,
    required BenchmarkUpdater updateBenchmark,
    DateTime? removedAt,
  }) async {
    await _ensurePro();
    final oldPath = benchmark.photoPath;
    final updated = benchmark.copyWith(
      clearPhoto: true,
      lastVerifiedAt: removedAt ?? DateTime.now(),
    );
    await updateBenchmark(updated);
    await _deletePhotoBestEffort(oldPath);
    return updated;
  }

  Future<void> copyCoordinate(BenchMark benchmark) async {
    await _ensurePro();
    await clipboard.copyCoordinate(benchmark);
  }

  Future<void> openMap(BenchMark benchmark) async {
    await _ensurePro();
    await mapLauncher.openMap(benchmark);
  }

  Future<void> _ensurePro() async {
    if (!await proAccess()) {
      throw const BenchmarkProActionException('레벨 야장 Pro 구매 후 사용할 수 있습니다.');
    }
  }

  Future<void> _deletePhotoBestEffort(String? relativePath) async {
    try {
      await photoStorage.deletePhoto(relativePath);
    } catch (_) {
      // The DB update is the source of truth; stale files are safer than stale DB paths.
    }
  }
}
