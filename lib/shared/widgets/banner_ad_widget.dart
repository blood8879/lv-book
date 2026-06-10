import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/ads/ad_manager.dart';
import '../../features/ads/ad_providers.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  final String adUnitId;

  const BannerAdWidget({super.key, required this.adUnitId});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int? _loadedWidth;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadAd(int width) async {
    if (_loadedWidth == width && _bannerAd != null) return;
    await _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    _loadedWidth = width;

    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (size == null || !mounted) return;

    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdManager.supportsMobileAds) return const SizedBox.shrink();

    final adsRemoved = ref.watch(adsRemovedProvider);
    if (adsRemoved.valueOrNull != false) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.truncate();
        if (width <= 0) return const SizedBox.shrink();

        _loadAd(width);

        if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
        return Center(
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        );
      },
    );
  }
}
