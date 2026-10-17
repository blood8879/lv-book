import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'features/ads/ad_manager.dart';
import 'features/backup/auto_backup_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Draw behind the status and navigation bars on every Android version (it
  // is only the default from Android 15 / targetSdk 35). Screens keep their
  // content clear of the bars through MediaQuery padding (SafeArea/Scaffold).
  // MainActivity does the same natively for the launch frames and API < 29.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
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
