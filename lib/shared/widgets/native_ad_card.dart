import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme/app_theme.dart';
import '../../features/ads/ad_manager.dart';
import '../../features/ads/ad_providers.dart';
import '../../l10n/l10n.dart';

/// Small native ad rendered as a card matching the app's Card tone.
///
/// Follows [BannerAdWidget]'s gating: only shows when mobile ads are
/// supported, a native unit is configured ([AdManager.hasNativeUnit]) and ads
/// are explicitly not removed; renders nothing until the ad has loaded (no
/// reserved space).
///
/// Kept alive inside lazy lists so scrolling it out of and back into view does
/// not request a new ad each time. The native template's colors are baked in
/// at load time, so the ad is reloaded when the platform brightness changes.
class NativeAdCard extends ConsumerStatefulWidget {
  const NativeAdCard({super.key});

  @override
  ConsumerState<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends ConsumerState<NativeAdCard>
    with AutomaticKeepAliveClientMixin {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  /// Brightness the current template style was built for; null = not requested.
  Brightness? _requestedBrightness;

  @override
  bool get wantKeepAlive => _requestedBrightness != null;

  NativeTemplateStyle _buildStyle(AppColors colors) {
    return NativeTemplateStyle(
      templateType: TemplateType.small,
      mainBackgroundColor: colors.panel,
      cornerRadius: 12,
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: colors.ink,
        style: NativeTemplateFontStyle.bold,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(textColor: colors.subtext),
      tertiaryTextStyle: NativeTemplateTextStyle(textColor: colors.subtext),
      // ink/paper are an inverse pair in both themes (dark ink on light paper,
      // light ink on dark paper), so the CTA label always stays readable.
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: colors.paper,
        backgroundColor: colors.ink,
        style: NativeTemplateFontStyle.bold,
      ),
    );
  }

  void _maybeLoad(String adUnitId, Brightness brightness, AppColors colors) {
    if (_requestedBrightness == brightness) return;
    final wasRequested = _requestedBrightness != null;
    _requestedBrightness = brightness;
    if (!wasRequested) updateKeepAlive();

    final previous = _nativeAd;
    _nativeAd = null;
    _isLoaded = false;
    if (previous != null) {
      // The old AdWidget may still be mounted this frame; dispose afterwards.
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }

    final ad = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: _buildStyle(colors),
      listener: NativeAdListener(
        onAdLoaded: (loaded) {
          if (mounted && identical(loaded, _nativeAd)) {
            setState(() => _isLoaded = true);
          } else {
            loaded.dispose();
          }
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          if (identical(failed, _nativeAd)) _nativeAd = null;
        },
      ),
    );
    _nativeAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    _nativeAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!AdManager.supportsMobileAds) return const SizedBox.shrink();
    final adUnitId = AdManager.nativeId;
    if (adUnitId == null) return const SizedBox.shrink();

    final adsRemoved = ref.watch(adsRemovedProvider);
    if (adsRemoved.valueOrNull != false) return const SizedBox.shrink();

    final colors = context.appColors;
    _maybeLoad(adUnitId, Theme.of(context).brightness, colors);

    final nativeAd = _nativeAd;
    if (!_isLoaded || nativeAd == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              context.l10n.adsNativeAdLabel,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: colors.subtext,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(11),
            ),
            child: SizedBox(height: 100, child: AdWidget(ad: nativeAd)),
          ),
        ],
      ),
    );
  }
}
