import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdManager {
  static const String banner1Id = 'ca-app-pub-7612314432840835/8338000107';
  static const String banner2Id = 'ca-app-pub-7612314432840835/2531139657';
  static const String interstitialId = 'ca-app-pub-7612314432840835/4202267796';

  static bool get supportsMobileAds {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
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
