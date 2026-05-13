import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _isLoaded = false;
  int? _loadedWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadForCurrentWidth();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadForCurrentWidth() async {
    final adUnitId = AdService.bannerAdUnitId;
    if (adUnitId == null) {
      return;
    }

    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0 || width == _loadedWidth) {
      return;
    }
    _loadedWidth = width;

    const adSize = AdSize.banner;
    if (!mounted) {
      return;
    }

    await _bannerAd?.dispose();
    setState(() {
      _isLoaded = false;
      _adSize = adSize;
      _bannerAd = null;
    });

    final ad = BannerAd(
      adUnitId: adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) {
            return;
          }
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    );

    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final bannerAd = _bannerAd;
    final adSize = _adSize;
    if (!_isLoaded || bannerAd == null || adSize == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: adSize.height.toDouble(),
        child: ClipRect(
          child: ColoredBox(
            color: const Color(0xFF14111B),
            child: Center(
              child: SizedBox(
                width: adSize.width.toDouble(),
                height: adSize.height.toDouble(),
                child: AdWidget(ad: bannerAd),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
