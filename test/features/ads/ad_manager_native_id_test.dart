import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/ads/ad_manager.dart';

void main() {
  test('release builds request no native ad without a real unit id', () {
    expect(
      AdManager.resolveNativeId(
        isIOS: false,
        isDebug: false,
        realAndroidId: '',
      ),
      isNull,
    );
    expect(
      AdManager.resolveNativeId(isIOS: true, isDebug: false, realIosId: ''),
      isNull,
    );
  });

  test('debug builds fall back to Google test units', () {
    expect(
      AdManager.resolveNativeId(isIOS: false, isDebug: true, realAndroidId: ''),
      startsWith('ca-app-pub-3940256099942544/'),
    );
  });

  test('a configured real unit id is used in release', () {
    expect(
      AdManager.resolveNativeId(
        isIOS: false,
        isDebug: false,
        realAndroidId: 'ca-app-pub-7612314432840835/1234567890',
      ),
      'ca-app-pub-7612314432840835/1234567890',
    );
  });

  test('debug builds use the test unit even when a real id is configured', () {
    expect(
      AdManager.resolveNativeId(
        isIOS: false,
        isDebug: true,
        realAndroidId: 'ca-app-pub-7612314432840835/1234567890',
      ),
      'ca-app-pub-3940256099942544/2247696110',
    );
  });

  test('release Android uses the lv_book_native unit', () {
    expect(
      AdManager.resolveNativeId(isIOS: false, isDebug: false),
      'ca-app-pub-7612314432840835/2090884745',
    );
  });
}
