import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lv_book/features/ads/ad_settings_repository.dart';
import 'package:lv_book/features/purchase/purchase_controller.dart';

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  late _FakeInAppPurchase store;
  late _MemoryAdSettingsRepository repository;
  late int entitlementCalls;

  setUp(() {
    store = _FakeInAppPurchase();
    repository = _MemoryAdSettingsRepository();
    entitlementCalls = 0;
  });

  PurchaseController build(
    _FakeOwnedPurchasesSource source, {
    Duration timeout = const Duration(seconds: 15),
  }) {
    return PurchaseController(
      adSettingsRepository: repository,
      inAppPurchase: store,
      onEntitlementChanged: () => entitlementCalls++,
      ownedPurchasesSource: source,
      ownedPurchasesTimeout: timeout,
      restoreGracePeriod: const Duration(milliseconds: 30),
    );
  }

  group('startup entitlement sync (Android)', () {
    test('owned unacknowledged Pro is granted and acknowledged', () async {
      final purchase = _pro(PurchaseStatus.purchased, pendingComplete: true);
      final controller = build(_FakeOwnedPurchasesSource.success([purchase]));

      await controller.initialize();

      expect(repository.adsRemoved, isTrue);
      expect(entitlementCalls, 1);
      expect(store.completed, [purchase]);
      expect(controller.notice, isNull, reason: 'silent');
      controller.dispose();
    });

    test('owned acknowledged Pro while already Pro changes nothing', () async {
      repository.adsRemoved = true;
      final controller = build(
        _FakeOwnedPurchasesSource.success([_pro(PurchaseStatus.purchased)]),
      );

      await controller.initialize();

      expect(repository.adsRemoved, isTrue);
      expect(repository.writes, 0);
      expect(entitlementCalls, 0);
      expect(store.completed, isEmpty);
      controller.dispose();
    });

    test('absent Pro revokes a previously granted entitlement', () async {
      repository.adsRemoved = true;
      final controller = build(_FakeOwnedPurchasesSource.success(const []));

      await controller.initialize();

      expect(repository.adsRemoved, isFalse);
      expect(entitlementCalls, 1);
      expect(controller.notice, isNull, reason: 'silent');
      controller.dispose();
    });

    test('absent Pro while not Pro changes nothing', () async {
      final controller = build(
        _FakeOwnedPurchasesSource.success([
          _purchase('other_product', PurchaseStatus.purchased),
        ]),
      );

      await controller.initialize();

      expect(repository.adsRemoved, isFalse);
      expect(repository.writes, 0);
      expect(entitlementCalls, 0);
      controller.dispose();
    });

    for (final initial in [true, false]) {
      test('pending Pro leaves the flag ($initial) untouched', () async {
        repository.adsRemoved = initial;
        final controller = build(
          _FakeOwnedPurchasesSource.success([
            _pro(PurchaseStatus.pending, pendingComplete: true),
          ]),
        );

        await controller.initialize();

        expect(repository.adsRemoved, initial);
        expect(repository.writes, 0);
        expect(entitlementCalls, 0);
        expect(store.completed, isEmpty);
        controller.dispose();
      });
    }

    final failures = <String, _FakeOwnedPurchasesSource Function()>{
      'query error': () => _FakeOwnedPurchasesSource.failure('offline'),
      'exception': () => _FakeOwnedPurchasesSource.throwing(),
      'timeout': () => _FakeOwnedPurchasesSource.never(),
    };
    for (final entry in failures.entries) {
      test('${entry.key} changes nothing and does not throw', () async {
        repository.adsRemoved = true;
        final controller = build(
          entry.value(),
          timeout: const Duration(milliseconds: 20),
        );

        await controller.initialize();

        expect(controller.storeAvailable, isTrue);
        expect(repository.adsRemoved, isTrue);
        expect(repository.writes, 0);
        expect(entitlementCalls, 0);
        controller.dispose();
      });
    }

    test('store unavailable skips the query', () async {
      store.available = false;
      final source = _FakeOwnedPurchasesSource.success(const []);
      repository.adsRemoved = true;
      final controller = build(source);

      await controller.initialize();

      expect(source.calls, 0);
      expect(repository.adsRemoved, isTrue);
      controller.dispose();
    });

    test('a stream grant during the query is not revoked by the stale '
        'snapshot', () async {
      final source = _FakeOwnedPurchasesSource.deferred();
      final controller = build(source);

      final init = controller.initialize();
      await _settle();
      store.emit([_pro(PurchaseStatus.purchased)]);
      await _settle();
      expect(repository.adsRemoved, isTrue);

      source.complete(const OwnedPurchasesResult.success([]));
      await init;

      expect(repository.adsRemoved, isTrue);
      controller.dispose();
    });

    test('iOS does not query owned purchases', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final source = _FakeOwnedPurchasesSource.success(const []);
      repository.adsRemoved = true;
      final controller = build(source);

      await controller.initialize();

      expect(source.calls, 0);
      expect(repository.adsRemoved, isTrue);
      controller.dispose();
    });
  });

  group('restore (Android)', () {
    Future<PurchaseController> ready(_FakeOwnedPurchasesSource source) async {
      final controller = build(source);
      await controller.initialize();
      entitlementCalls = 0;
      source.calls = 0;
      return controller;
    }

    test('owned Pro grants, acknowledges and reports activation', () async {
      final source = _FakeOwnedPurchasesSource.success(const []);
      final controller = await ready(source);
      final purchase = _pro(PurchaseStatus.purchased, pendingComplete: true);
      source.next = () async => OwnedPurchasesResult.success([purchase]);
      final serial = controller.messageSerial;

      final restore = controller.restorePurchases();
      expect(controller.purchasePending, isTrue);
      await restore;

      expect(source.calls, 1);
      expect(store.restoreCalls, 0, reason: 'Android uses the query');
      expect(repository.adsRemoved, isTrue);
      expect(entitlementCalls, 1);
      expect(store.completed, [purchase]);
      expect(controller.purchasePending, isFalse);
      expect(controller.notice?.code, PurchaseNoticeCode.proActivated);
      expect(controller.messageSerial, serial + 1);

      // No late grace timer overwrites the result.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(controller.notice?.code, PurchaseNoticeCode.proActivated);
      expect(controller.messageSerial, serial + 1);
      controller.dispose();
    });

    test('absent Pro reports nothing to restore', () async {
      final controller = await ready(
        _FakeOwnedPurchasesSource.success(const []),
      );

      await controller.restorePurchases();

      expect(repository.adsRemoved, isFalse);
      expect(entitlementCalls, 0);
      expect(controller.purchasePending, isFalse);
      expect(controller.notice?.code, PurchaseNoticeCode.nothingToRestore);
      controller.dispose();
    });

    test(
      'slow store still decides from the query, not a fixed timer',
      () async {
        final source = _FakeOwnedPurchasesSource.success(const []);
        final controller = await ready(source);
        final deferred = Completer<OwnedPurchasesResult>();
        source.next = () => deferred.future;

        final restore = controller.restorePurchases();
        // Well past restoreGracePeriod (30 ms): still waiting for the store.
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(controller.purchasePending, isTrue);
        expect(controller.notice, isNull);

        deferred.complete(
          OwnedPurchasesResult.success([_pro(PurchaseStatus.purchased)]),
        );
        await restore;
        expect(controller.notice?.code, PurchaseNoticeCode.proActivated);
        expect(repository.adsRemoved, isTrue);
        controller.dispose();
      },
    );

    test('failed query reports a restore error and changes nothing', () async {
      final source = _FakeOwnedPurchasesSource.success(const []);
      final controller = await ready(source);
      repository.adsRemoved = true;
      repository.writes = 0;
      source.next = () async =>
          const OwnedPurchasesResult.failure('SERVICE_UNAVAILABLE');

      await controller.restorePurchases();

      expect(repository.adsRemoved, isTrue);
      expect(repository.writes, 0);
      expect(controller.purchasePending, isFalse);
      expect(
        controller.notice,
        const PurchaseNotice(
          PurchaseNoticeCode.restoreError,
          'SERVICE_UNAVAILABLE',
        ),
      );
      controller.dispose();
    });

    test('query exception reports a restore error', () async {
      final source = _FakeOwnedPurchasesSource.success(const []);
      final controller = await ready(source);
      source.next = () => throw StateError('billing disconnected');

      await controller.restorePurchases();

      expect(controller.purchasePending, isFalse);
      expect(controller.notice?.code, PurchaseNoticeCode.restoreError);
      controller.dispose();
    });

    test('pending Pro reports pending without granting', () async {
      final source = _FakeOwnedPurchasesSource.success(const []);
      final controller = await ready(source);
      source.next = () async =>
          OwnedPurchasesResult.success([_pro(PurchaseStatus.pending)]);

      await controller.restorePurchases();

      expect(repository.adsRemoved, isFalse);
      expect(controller.purchasePending, isFalse);
      expect(controller.notice?.code, PurchaseNoticeCode.pending);
      controller.dispose();
    });
  });
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

PurchaseDetails _pro(PurchaseStatus status, {bool pendingComplete = false}) =>
    _purchase(PurchaseController.proProductId, status, pendingComplete);

PurchaseDetails _purchase(
  String productId,
  PurchaseStatus status, [
  bool pendingComplete = false,
]) {
  return PurchaseDetails(
    productID: productId,
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: '',
      source: 'test',
    ),
    transactionDate: null,
    status: status,
  )..pendingCompletePurchase = pendingComplete;
}

class _FakeOwnedPurchasesSource implements OwnedPurchasesSource {
  Future<OwnedPurchasesResult> Function() next;
  int calls = 0;
  Completer<OwnedPurchasesResult>? _deferred;

  _FakeOwnedPurchasesSource(this.next);

  factory _FakeOwnedPurchasesSource.success(List<PurchaseDetails> purchases) =>
      _FakeOwnedPurchasesSource(
        () async => OwnedPurchasesResult.success(purchases),
      );

  factory _FakeOwnedPurchasesSource.failure(String error) =>
      _FakeOwnedPurchasesSource(
        () async => OwnedPurchasesResult.failure(error),
      );

  factory _FakeOwnedPurchasesSource.throwing() => _FakeOwnedPurchasesSource(
    () async => throw Exception('platform channel error'),
  );

  factory _FakeOwnedPurchasesSource.never() =>
      _FakeOwnedPurchasesSource(() => Completer<OwnedPurchasesResult>().future);

  factory _FakeOwnedPurchasesSource.deferred() {
    final completer = Completer<OwnedPurchasesResult>();
    return _FakeOwnedPurchasesSource(() => completer.future)
      .._deferred = completer;
  }

  void complete(OwnedPurchasesResult result) => _deferred!.complete(result);

  @override
  Future<OwnedPurchasesResult> query() {
    calls++;
    return next();
  }
}

class _FakeInAppPurchase implements InAppPurchase {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();
  final completed = <PurchaseDetails>[];
  bool available = true;
  int restoreCalls = 0;

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: [
        for (final id in identifiers)
          ProductDetails(
            id: id,
            title: 'Pro',
            description: '',
            price: '\$1',
            rawPrice: 1,
            currencyCode: 'USD',
          ),
      ],
      notFoundIDs: const [],
    );
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoreCalls++;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryAdSettingsRepository extends AdSettingsRepository {
  bool adsRemoved = false;
  int writes = 0;

  @override
  Future<bool> areAdsRemoved() async => adsRemoved;

  @override
  Future<void> setAdsRemoved(bool removed) async {
    writes++;
    adsRemoved = removed;
  }
}
