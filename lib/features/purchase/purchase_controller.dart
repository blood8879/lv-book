import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../l10n/l10n.dart';
import '../ads/ad_settings_repository.dart';

/// What happened in the last purchase/restore step. The controller stores a
/// code (plus optional technical detail); the UI renders it with
/// [PurchaseNotice.localizedMessage] in the app language.
enum PurchaseNoticeCode {
  storeUnsupportedPlatform,
  updateError,
  storeUnavailable,
  productLoadError,
  productNotFound,
  storeInitError,
  productNotReady,
  startError,
  startFailed,
  restoreError,
  nothingToRestore,
  pending,
  proActivated,
  purchaseError,
  canceled,
}

@immutable
class PurchaseNotice {
  final PurchaseNoticeCode code;

  /// Technical detail (exception text, store error message, product id).
  final String? detail;

  const PurchaseNotice(this.code, [this.detail]);

  /// Whether the notice should be shown as an error rather than a success.
  bool get isError => switch (code) {
    PurchaseNoticeCode.pending || PurchaseNoticeCode.proActivated => false,
    _ => true,
  };

  String localizedMessage(AppLocalizations l10n) {
    final detail = this.detail ?? '';
    return switch (code) {
      PurchaseNoticeCode.storeUnsupportedPlatform =>
        l10n.purchaseStoreUnsupportedPlatform,
      PurchaseNoticeCode.updateError => l10n.purchaseUpdateError(detail),
      PurchaseNoticeCode.storeUnavailable => l10n.purchaseStoreUnavailable,
      PurchaseNoticeCode.productLoadError => l10n.purchaseProductLoadError(
        detail,
      ),
      PurchaseNoticeCode.productNotFound => l10n.purchaseProductNotFound(
        detail,
      ),
      PurchaseNoticeCode.storeInitError => l10n.purchaseStoreInitError(detail),
      PurchaseNoticeCode.productNotReady => l10n.purchaseProductNotReady,
      PurchaseNoticeCode.startError => l10n.purchaseStartError(detail),
      PurchaseNoticeCode.startFailed => l10n.purchaseStartFailed,
      PurchaseNoticeCode.restoreError => l10n.purchaseRestoreError(detail),
      PurchaseNoticeCode.nothingToRestore => l10n.purchaseNothingToRestore,
      PurchaseNoticeCode.pending => l10n.purchasePendingMessage,
      PurchaseNoticeCode.proActivated => l10n.purchaseProActivatedMessage,
      // The store's own error text is already localized by the store.
      PurchaseNoticeCode.purchaseError =>
        (this.detail?.trim().isNotEmpty ?? false)
            ? this.detail!
            : l10n.purchaseFailedMessage,
      PurchaseNoticeCode.canceled => l10n.purchaseCanceledMessage,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is PurchaseNotice && other.code == code && other.detail == detail;

  @override
  int get hashCode => Object.hash(code, detail);
}

class PurchaseController extends ChangeNotifier {
  static const proProductId = 'lv_book_pro';

  /// Legacy Korean text of [PurchaseNoticeCode.nothingToRestore].
  static String get noPurchasesToRestoreMessage =>
      l10nKo.purchaseNothingToRestore;

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
  PurchaseNotice? _notice;

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

  /// Last purchase/restore notice; render with
  /// [PurchaseNotice.localizedMessage].
  PurchaseNotice? get notice => _notice;

  /// Legacy Korean text of [notice].
  String? get message => _notice?.localizedMessage(l10nKo);

  /// Increments every time [notice] is set, so listeners can show the same
  /// text twice in a row (e.g. two restores with nothing to restore).
  int get messageSerial => _messageSerial;

  bool _disposed = false;

  void _setMessage(PurchaseNotice? value) {
    _notice = value;
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
      _setMessage(
        const PurchaseNotice(PurchaseNoticeCode.storeUnsupportedPlatform),
      );
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
          _setMessage(PurchaseNotice(PurchaseNoticeCode.updateError, '$error'));
          _notify();
        },
      );

      _storeAvailable = await _inAppPurchase.isAvailable();
      if (!_storeAvailable) {
        _loading = false;
        _setMessage(const PurchaseNotice(PurchaseNoticeCode.storeUnavailable));
        _notify();
        return;
      }

      final response = await _inAppPurchase.queryProductDetails({proProductId});
      if (response.error != null) {
        _setMessage(
          PurchaseNotice(
            PurchaseNoticeCode.productLoadError,
            response.error!.message,
          ),
        );
      } else if (response.productDetails.isEmpty) {
        _setMessage(
          const PurchaseNotice(
            PurchaseNoticeCode.productNotFound,
            proProductId,
          ),
        );
      } else {
        _proProduct = response.productDetails.first;
      }
    } catch (error) {
      _storeAvailable = false;
      _setMessage(PurchaseNotice(PurchaseNoticeCode.storeInitError, '$error'));
    }

    _loading = false;
    _notify();
  }

  Future<void> buyPro() async {
    final product = _proProduct;
    if (product == null) {
      _setMessage(const PurchaseNotice(PurchaseNoticeCode.productNotReady));
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
      _setMessage(PurchaseNotice(PurchaseNoticeCode.startError, '$error'));
      _notify();
      return;
    }

    if (!started) {
      _purchasePending = false;
      _setMessage(const PurchaseNotice(PurchaseNoticeCode.startFailed));
      _notify();
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) {
      _setMessage(const PurchaseNotice(PurchaseNoticeCode.storeUnavailable));
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
      _setMessage(PurchaseNotice(PurchaseNoticeCode.restoreError, '$error'));
      _notify();
      return;
    }

    if (!_restoreInProgress || _disposed) return;
    // Restored purchases arrive on the purchase stream; when there is nothing
    // to restore the stores send no event at all, so stop waiting after a
    // short grace period instead of leaving the buttons in the processing state forever.
    _restoreTimer = Timer(restoreGracePeriod, () {
      if (!_restoreInProgress) return;
      _finishRestore();
      _purchasePending = false;
      _setMessage(const PurchaseNotice(PurchaseNoticeCode.nothingToRestore));
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
          _setMessage(const PurchaseNotice(PurchaseNoticeCode.pending));
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchase.productID == proProductId) {
            await adSettingsRepository.setAdsRemoved(true);
            entitlementChanged = true;
            _setMessage(const PurchaseNotice(PurchaseNoticeCode.proActivated));
          }
          _purchasePending = false;
          break;
        case PurchaseStatus.error:
          _purchasePending = false;
          _setMessage(
            PurchaseNotice(
              PurchaseNoticeCode.purchaseError,
              purchase.error?.message,
            ),
          );
          break;
        case PurchaseStatus.canceled:
          _purchasePending = false;
          _setMessage(const PurchaseNotice(PurchaseNoticeCode.canceled));
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
