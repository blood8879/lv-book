import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lv_book/features/ads/ad_settings_repository.dart';
import 'package:lv_book/features/purchase/purchase_controller.dart';

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test(
    'restore with nothing to restore clears pending after grace period',
    () async {
      final store = _FakeInAppPurchase();
      final controller = PurchaseController(
        adSettingsRepository: _MemoryAdSettingsRepository(),
        inAppPurchase: store,
        restoreGracePeriod: const Duration(milliseconds: 30),
      );
      controller.initialize();
      await _settle();
      expect(controller.storeAvailable, isTrue);

      unawaited(controller.restorePurchases());
      await _settle();
      expect(controller.purchasePending, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(controller.purchasePending, isFalse);
      expect(
        controller.message,
        PurchaseController.noPurchasesToRestoreMessage,
      );
      controller.dispose();
    },
  );

  test('restore that never completes is bounded by restoreTimeout', () async {
    final store = _FakeInAppPurchase(restoreCompleter: Completer<void>());
    final controller = PurchaseController(
      adSettingsRepository: _MemoryAdSettingsRepository(),
      inAppPurchase: store,
      restoreTimeout: const Duration(milliseconds: 100),
      restoreGracePeriod: const Duration(milliseconds: 200),
    );
    controller.initialize();
    await _settle();

    unawaited(controller.restorePurchases());
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(controller.purchasePending, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(controller.purchasePending, isFalse);
    controller.dispose();
  });

  test('restored Pro purchase grants entitlement and notifies app', () async {
    final store = _FakeInAppPurchase();
    final repository = _MemoryAdSettingsRepository();
    var entitlementCalls = 0;
    final controller = PurchaseController(
      adSettingsRepository: repository,
      inAppPurchase: store,
      onEntitlementChanged: () => entitlementCalls++,
      restoreGracePeriod: const Duration(milliseconds: 30),
    );
    controller.initialize();
    await _settle();

    unawaited(controller.restorePurchases());
    await _settle();
    store.emit([
      PurchaseDetails(
        productID: PurchaseController.proProductId,
        verificationData: PurchaseVerificationData(
          localVerificationData: '',
          serverVerificationData: '',
          source: 'test',
        ),
        transactionDate: null,
        status: PurchaseStatus.restored,
      ),
    ]);
    await _settle();

    expect(repository.adsRemoved, isTrue);
    expect(entitlementCalls, 1);
    expect(controller.purchasePending, isFalse);
    final serial = controller.messageSerial;

    // Grace timer must not later overwrite the success message.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(controller.message, contains('활성화'));
    expect(controller.messageSerial, serial);
    controller.dispose();
  });
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

class _FakeInAppPurchase implements InAppPurchase {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();
  final Completer<void>? restoreCompleter;

  _FakeInAppPurchase({this.restoreCompleter});

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: const [],
      notFoundIDs: identifiers.toList(),
    );
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) {
    return restoreCompleter?.future ?? Future<void>.value();
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryAdSettingsRepository extends AdSettingsRepository {
  bool adsRemoved = false;

  @override
  Future<bool> areAdsRemoved() async => adsRemoved;

  @override
  Future<void> setAdsRemoved(bool removed) async {
    adsRemoved = removed;
  }
}
