import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../ads/ad_settings_repository.dart';

class PurchaseController extends ChangeNotifier {
  static const proProductId = 'lv_book_pro';

  final AdSettingsRepository adSettingsRepository;
  final InAppPurchase _inAppPurchase;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _proProduct;
  bool _storeAvailable = false;
  bool _loading = false;
  bool _purchasePending = false;
  String? _message;

  PurchaseController({
    required this.adSettingsRepository,
    InAppPurchase? inAppPurchase,
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

  Future<void> initialize() async {
    if (_subscription != null) return;

    _loading = true;
    _message = null;
    notifyListeners();

    if (!supportsStorePurchases) {
      _loading = false;
      _storeAvailable = false;
      _message = '현재 플랫폼에서는 스토어 결제를 사용할 수 없습니다.';
      notifyListeners();
      return;
    }

    _subscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (Object error) {
        _purchasePending = false;
        _message = '결제 업데이트를 처리하지 못했습니다: $error';
        notifyListeners();
      },
    );

    _storeAvailable = await _inAppPurchase.isAvailable();
    if (!_storeAvailable) {
      _loading = false;
      _message = '스토어 결제를 사용할 수 없습니다.';
      notifyListeners();
      return;
    }

    final response = await _inAppPurchase.queryProductDetails({proProductId});
    if (response.error != null) {
      _message = '상품 정보를 불러오지 못했습니다: ${response.error!.message}';
    } else if (response.productDetails.isEmpty) {
      _message = 'Play Console에서 $proProductId 상품을 찾지 못했습니다.';
    } else {
      _proProduct = response.productDetails.first;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> buyPro() async {
    final product = _proProduct;
    if (product == null) {
      _message = 'Pro 상품 정보가 아직 준비되지 않았습니다.';
      notifyListeners();
      return;
    }

    _purchasePending = true;
    _message = null;
    notifyListeners();

    final purchaseParam = PurchaseParam(productDetails: product);
    final started = await _inAppPurchase.buyNonConsumable(
      purchaseParam: purchaseParam,
    );

    if (!started) {
      _purchasePending = false;
      _message = '결제를 시작하지 못했습니다.';
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _message = '스토어 결제를 사용할 수 없습니다.';
      notifyListeners();
      return;
    }

    _purchasePending = true;
    _message = null;
    notifyListeners();
    await _inAppPurchase.restorePurchases();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          _message = '결제를 처리하는 중입니다.';
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == proProductId) {
            await adSettingsRepository.setAdsRemoved(true);
            _message = '레벨 야장 Pro가 활성화되었습니다.';
          }
          _purchasePending = false;
          break;
        case PurchaseStatus.error:
          _purchasePending = false;
          _message = purchase.error?.message ?? '결제가 실패했습니다.';
          break;
        case PurchaseStatus.canceled:
          _purchasePending = false;
          _message = '결제가 취소되었습니다.';
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
