import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_providers.dart';
import 'purchase_controller.dart';

/// App-wide purchase controller.
///
/// Instantiated at app start (see `LvBookApp`) and never auto-disposed, so the
/// store's purchase stream is listened to for the whole app lifetime. A
/// purchase/restore that completes on any screen refreshes [adsRemovedProvider]
/// immediately (banners, native ads and Pro gating update without a restart).
final purchaseControllerProvider = ChangeNotifierProvider<PurchaseController>((
  ref,
) {
  final controller = PurchaseController(
    adSettingsRepository: ref.watch(adSettingsRepositoryProvider),
    onEntitlementChanged: () => ref.invalidate(adsRemovedProvider),
  );
  controller.initialize();
  return controller;
});
