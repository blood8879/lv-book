import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../features/ads/ad_manager.dart';
import '../../features/ads/ad_providers.dart';

/// Banner ad for [Scaffold.bottomNavigationBar].
///
/// Keeps the ad above the system navigation / gesture bar (the app draws
/// edge-to-edge) and, as a Scaffold bottom bar, makes the Scaffold lift its
/// FAB and snack bars above the ad instead of overlapping it. With no ad it
/// collapses to just the bottom inset.
class BottomBannerAd extends StatelessWidget {
  final String adUnitId;

  const BottomBannerAd({super.key, required this.adUnitId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(top: false, child: BannerAdWidget(adUnitId: adUnitId));
  }
}

class BannerAdWidget extends ConsumerStatefulWidget {
  final String adUnitId;

  const BannerAdWidget({super.key, required this.adUnitId});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  /// Width changes smaller than this (logical px) don't trigger a reload.
  static const _widthTolerance = 8;

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  /// True while an adaptive-size lookup / ad creation is in flight, so a
  /// rebuild during that async gap can't start a second (leaked) BannerAd.
  bool _loading = false;

  /// Width the current (or last attempted) ad was requested for. A failed load
  /// keeps this so we don't retry on every rebuild for the same width.
  int? _requestedWidth;

  /// Most recent width seen in build, used to catch up after an in-flight load.
  int? _latestWidth;

  void _maybeLoad(int width) {
    _latestWidth = width;
    if (_loading) return;
    final requested = _requestedWidth;
    if (requested != null && (requested - width).abs() < _widthTolerance) {
      return;
    }
    _requestedWidth = width;
    _loadAd(width);
  }

  Future<void> _loadAd(int width) async {
    _loading = true;
    final previous = _bannerAd;
    _bannerAd = null;
    _isLoaded = false;
    if (previous != null) {
      // The previous AdWidget may still be mounted in the current frame;
      // dispose only after it has been removed from the tree.
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }

    try {
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      if (size == null || !mounted) return;

      final ad = BannerAd(
        adUnitId: widget.adUnitId,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted || !identical(ad, _bannerAd)) {
              ad.dispose();
              return;
            }
            setState(() => _isLoaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (identical(ad, _bannerAd)) {
              _bannerAd = null;
              _isLoaded = false;
            }
          },
        ),
      );
      _bannerAd = ad;
      await ad.load();
    } catch (_) {
      // Ads are best-effort; leave the slot empty.
    } finally {
      _loading = false;
      final latest = _latestWidth;
      if (mounted &&
          latest != null &&
          (latest - width).abs() >= _widthTolerance) {
        _requestedWidth = latest;
        _loadAd(latest);
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdManager.supportsMobileAds) return const SizedBox.shrink();

    final adsRemoved = ref.watch(adsRemovedProvider);
    if (adsRemoved.valueOrNull != false) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return const SizedBox.shrink();
        final width = constraints.maxWidth.truncate();
        if (width <= 0) return const SizedBox.shrink();

        _maybeLoad(width);

        final ad = _bannerAd;
        if (!_isLoaded || ad == null) return const SizedBox.shrink();
        // heightFactor: 1 sizes this to the ad. A plain Center would take all
        // available height when used as Scaffold.bottomNavigationBar and push
        // the body off screen.
        return Align(
          heightFactor: 1,
          child: SizedBox(
            width: ad.size.width.toDouble(),
            height: ad.size.height.toDouble(),
            child: AdWidget(ad: ad),
          ),
        );
      },
    );
  }
}
