import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'project_backup_service.dart';

typedef ProjectBackupShare =
    Future<void> Function({required String fileName, required String source});

final projectBackupServiceProvider = Provider<ProjectBackupService>(
  (ref) => ProjectBackupService(),
);

final projectBackupShareProvider = Provider<ProjectBackupShare>((ref) {
  return ({required String fileName, required String source}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(source);
    await Share.shareXFiles([XFile(file.path)]);
  };
});
