import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/purchase/purchase_controller.dart';

void main() {
  test('Pro purchases are disabled outside Android and iOS', () {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      expect(PurchaseController.supportsStorePurchases, isFalse);
    }
  });
}
