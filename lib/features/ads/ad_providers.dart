import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_settings_repository.dart';

final adSettingsRepositoryProvider = Provider<AdSettingsRepository>((ref) {
  return AdSettingsRepository();
});

final adsRemovedProvider = FutureProvider<bool>((ref) {
  return ref.watch(adSettingsRepositoryProvider).areAdsRemoved();
});
