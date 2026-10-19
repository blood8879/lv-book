import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Outcome of asking the store which purchases the signed-in account
/// currently owns.
///
/// A failed query ([succeeded] is false) says nothing about the entitlement:
/// callers must not grant or revoke anything based on it.
class OwnedPurchasesResult {
  /// Purchases the store reports as currently owned (purchased or pending).
  /// Refunded/revoked purchases are absent. Empty when the query failed.
  final List<PurchaseDetails> purchases;

  /// Error description when the query failed; null on success.
  final String? error;

  const OwnedPurchasesResult.success(this.purchases) : error = null;

  const OwnedPurchasesResult.failure(String this.error) : purchases = const [];

  bool get succeeded => error == null;
}

/// Source of the store's currently-owned purchases. Injectable so the
/// entitlement sync can be unit-tested without the platform channel.
abstract class OwnedPurchasesSource {
  /// May throw; the caller treats exceptions like a failed query.
  Future<OwnedPurchasesResult> query();
}

/// Google Play implementation: `BillingClient.queryPurchasesAsync`, which
/// returns only purchases the account owns right now (refunds are absent).
class AndroidOwnedPurchasesSource implements OwnedPurchasesSource {
  final InAppPurchase _inAppPurchase;

  AndroidOwnedPurchasesSource(this._inAppPurchase);

  @override
  Future<OwnedPurchasesResult> query() async {
    final addition = _inAppPurchase
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    final error = response.error;
    if (error != null) {
      return OwnedPurchasesResult.failure(
        '${error.code}: ${error.message}'.trim(),
      );
    }
    return OwnedPurchasesResult.success(response.pastPurchases);
  }
}
