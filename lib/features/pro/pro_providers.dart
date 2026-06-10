import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pro_pdf_settings.dart';
import 'pro_settings_repository.dart';

final proSettingsRepositoryProvider = Provider<ProSettingsRepository>((ref) {
  return ProSettingsRepository();
});

final proPdfSettingsProvider = FutureProvider<ProPdfSettings>((ref) {
  return ref.watch(proSettingsRepositoryProvider).getPdfSettings();
});

final proDocumentPresetsProvider = FutureProvider<ProDocumentPresets>((ref) {
  return ref.watch(proSettingsRepositoryProvider).getDocumentPresets();
});
