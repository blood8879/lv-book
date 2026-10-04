import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../ads/ad_settings_repository.dart';

class PurchaseController extends ChangeNotifier {
  static const proProductId = 'lv_book_pro';
  static const noPurchasesToRestoreMessage = '복원할 구매 내역이 없습니다.';

  final AdSettingsRepository adSettingsRepository;
  final InAppPurchase _inAppPurchase;

  /// Called after the Pro entitlement is persisted (purchase or restore), so
  /// app-wide state such as `adsRemovedProvider` can refresh immediately.
  final VoidCallback? onEntitlementChanged;

  /// Upper bound for the store's restore call itself.
  final Duration restoreTimeout;

  /// How long to wait for restored purchase events after the store reports the
  /// restore finished. Stores deliver nothing when there is nothing to restore.
  final Duration restoreGracePeriod;

  Timer? _restoreTimer;
  bool _restoreInProgress = false;
  int _messageSerial = 0;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _proProduct;
  bool _storeAvailable = false;
  bool _loading = false;
  bool _purchasePending = false;
  String? _message;

  PurchaseController({
    required this.adSettingsRepository,
    InAppPurchase? inAppPurchase,
    this.onEntitlementChanged,
    this.restoreTimeout = const Duration(seconds: 30),
    this.restoreGracePeriod = const Duration(seconds: 3),
  }) : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance;

  static bool get supportsStorePurchases {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  ProductDetails? get proProduct => _proProduct;
  bool get storeAvailable => _storeAvailable;
  bool get loading => _loading;
  bool get purchasePending => _purchasePending;
  String? get message => _message;

  /// Increments every time [message] is set, so listeners can show the same
  /// text twice in a row (e.g. two restores with nothing to restore).
  int get messageSerial => _messageSerial;

  bool _disposed = false;

  void _setMessage(String? value) {
    _message = value;
    if (value != null) _messageSerial++;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (_subscription != null) return;

    _loading = true;
    _setMessage(null);
    _notify();

    if (!supportsStorePurchases) {
      _loading = false;
      _storeAvailable = false;
      _setMessage('현재 플랫폼에서는 스토어 결제를 사용할 수 없습니다.');
      _notify();
      return;
    }

    try {
      _subscription = _inAppPurchase.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (Object error) {
          _finishRestore();
          _purchasePending = false;
          _setMessage('결제 업데이트를 처리하지 못했습니다: $error');
          _notify();
        },
      );

      _storeAvailable = await _inAppPurchase.isAvailable();
      if (!_storeAvailable) {
        _loading = false;
        _setMessage('스토어 결제를 사용할 수 없습니다.');
        _notify();
        return;
      }

      final response = await _inAppPurchase.queryProductDetails({proProductId});
      if (response.error != null) {
        _setMessage('상품 정보를 불러오지 못했습니다: ${response.error!.message}');
      } else if (response.productDetails.isEmpty) {
        _setMessage('Play Console에서 $proProductId 상품을 찾지 못했습니다.');
      } else {
        _proProduct = response.productDetails.first;
      }
    } catch (error) {
      _storeAvailable = false;
      _setMessage('스토어 결제를 초기화하지 못했습니다: $error');
    }

    _loading = false;
    _notify();
  }

  Future<void> buyPro() async {
    final product = _proProduct;
    if (product == null) {
      _setMessage('Pro 상품 정보가 아직 준비되지 않았습니다.');
      _notify();
      return;
    }

    _purchasePending = true;
    _setMessage(null);
    _notify();

    final purchaseParam = PurchaseParam(productDetails: product);
    bool started;
    try {
      started = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (error) {
      _purchasePending = false;
      _setMessage('결제를 시작하지 못했습니다: $error');
      _notify();
      return;
    }

    if (!started) {
      _purchasePending = false;
      _setMessage('결제를 시작하지 못했습니다.');
      _notify();
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _setMessage('스토어 결제를 사용할 수 없습니다.');
      _notify();
      return;
    }

    _restoreTimer?.cancel();
    _restoreInProgress = true;
    _purchasePending = true;
    _setMessage(null);
    _notify();

    try {
      await _inAppPurchase.restorePurchases().timeout(restoreTimeout);
    } on TimeoutException {
      // Fall through: whatever the store delivered so far has been handled;
      // the grace period below still clears the pending state.
    } catch (error) {
      if (!_restoreInProgress) return;
      _finishRestore();
      _purchasePending = false;
      _setMessage('구매 복원에 실패했습니다: $error');
      _notify();
      return;
    }

    if (!_restoreInProgress || _disposed) return;
    // Restored purchases arrive on the purchase stream; when there is nothing
    // to restore the stores send no event at all, so stop waiting after a
    // short grace period instead of leaving the buttons in '처리 중' forever.
    _restoreTimer = Timer(restoreGracePeriod, () {
      if (!_restoreInProgress) return;
      _finishRestore();
      _purchasePending = false;
      _setMessage(noPurchasesToRestoreMessage);
      _notify();
    });
  }

  void _finishRestore() {
    _restoreInProgress = false;
    _restoreTimer?.cancel();
    _restoreTimer = null;
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    var entitlementChanged = false;
    for (final purchase in purchases) {
      if (purchase.status != PurchaseStatus.pending) _finishRestore();
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          _setMessage('결제를 처리하는 중입니다.');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == proProductId) {
            await adSettingsRepository.setAdsRemoved(true);
            entitlementChanged = true;
            _setMessage('레벨 야장 Pro가 활성화되었습니다.');
          }
          _purchasePending = false;
          break;
        case PurchaseStatus.error:
          _purchasePending = false;
          _setMessage(purchase.error?.message ?? '결제가 실패했습니다.');
          break;
        case PurchaseStatus.canceled:
          _purchasePending = false;
          _setMessage('결제가 취소되었습니다.');
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }

    if (entitlementChanged) onEntitlementChanged?.call();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _restoreTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
