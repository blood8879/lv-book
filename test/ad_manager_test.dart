import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/ads/ad_manager.dart';

void main() {
  test('mobile ads are disabled outside Android and iOS', () {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      expect(AdManager.supportsMobileAds, isFalse);
    }
  });
}
