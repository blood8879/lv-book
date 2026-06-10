import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ad_providers.dart';
import 'purchase_controller.dart';

final purchaseControllerProvider = ChangeNotifierProvider<PurchaseController>((
  ref,
) {
  final controller = PurchaseController(
    adSettingsRepository: ref.watch(adSettingsRepositoryProvider),
  );
  controller.initialize();
  return controller;
});
