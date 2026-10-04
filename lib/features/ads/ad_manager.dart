import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static const String banner1Id = 'ca-app-pub-7612314432840835/8338000107';
  static const String banner2Id = 'ca-app-pub-7612314432840835/2531139657';
  static const String interstitialId = 'ca-app-pub-7612314432840835/4202267796';

  // Android 네이티브 유닛 'lv_book_native'(AdMob, 2026-10-04 생성).
  // TODO(ads): iOS 유닛은 iOS AdMob 앱 등록 후 채울 것. 비어 있는 동안 릴리스
  // 빌드는 네이티브 광고를 요청하지 않으며(NativeAdCard는 높이 0으로 숨김),
  // 디버그 빌드만 구글 공식 테스트 유닛으로 광고를 띄운다.
  static const String _nativeAndroidId =
      'ca-app-pub-7612314432840835/2090884745';
  static const String _nativeIosId = '';

  static const String _testNativeAndroidId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String _testNativeIosId =
      'ca-app-pub-3940256099942544/3986624511';

  /// Native ad unit to request, or null when none should be requested.
  ///
  /// Release builds never fall back to Google's test unit, so production can't
  /// show a "Test Ad" placeholder before a real unit is configured.
  static String? get nativeId => resolveNativeId(
    isIOS: defaultTargetPlatform == TargetPlatform.iOS,
    isDebug: kDebugMode,
  );

  static bool get hasNativeUnit => nativeId != null;

  @visibleForTesting
  static String? resolveNativeId({
    required bool isIOS,
    required bool isDebug,
    String? realAndroidId,
    String? realIosId,
  }) {
    // Debug builds always use Google's test unit so development never
    // requests (or accidentally clicks) live ads.
    if (isDebug) return isIOS ? _testNativeIosId : _testNativeAndroidId;
    final real = isIOS
        ? (realIosId ?? _nativeIosId)
        : (realAndroidId ?? _nativeAndroidId);
    return real.isNotEmpty ? real : null;
  }

  // TODO(ads): iOS AdMob 앱이 아직 없다. 위 배너/전면 ID는 Android 유닛이므로
  // iOS 앱을 등록하고 iOS 유닛 ID와 Info.plist의 GADApplicationIdentifier(현재
  // 구글 테스트 App ID)를 실제 값으로 바꾼 뒤 iOS를 다시 허용할 것.
  static bool get supportsMobileAds {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  static Future<void> initialize() async {
    if (!supportsMobileAds) return;
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd(
    String adUnitId, {
    required Function onLoaded,
    required Function onFailed,
  }) {
    return BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed();
        },
      ),
    );
  }

  static Future<InterstitialAd?> loadInterstitialAd() async {
    if (!supportsMobileAds) return null;

    InterstitialAd? interstitialAd;
    await InterstitialAd.load(
      adUnitId: interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          interstitialAd = null;
        },
      ),
    );
    // Wait briefly for callback
    await Future.delayed(const Duration(seconds: 1));
    return interstitialAd;
  }
}
