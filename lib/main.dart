import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/ads/ad_manager.dart';
import 'features/backup/auto_backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdManager.initialize();
  runApp(const ProviderScope(child: LvBookApp()));
  _runAutoBackup();
}

/// Fire-and-forget daily snapshot; must never block or crash startup.
Future<void> _runAutoBackup() async {
  try {
    await AutoBackupService().runIfDue();
  } catch (_) {
    // Auto backup is a best-effort safety net.
  }
}
