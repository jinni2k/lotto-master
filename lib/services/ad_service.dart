import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers/user_provider.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
    }
    _initialized = true;
  }

  BannerAd? createBannerAd({
    AdSize size = AdSize.banner,
    BannerAdListener? listener,
  }) {
    if (kIsWeb) {
      return null;
    }
    final unitId = _bannerAdUnitId;
    if (unitId == null) {
      return null;
    }
    return BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: listener ?? const BannerAdListener(),
    );
  }

  String? get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return null;
  }
}

class PremiumAwareBanner extends StatelessWidget {
  const PremiumAwareBanner({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isPremium = UserProviderScope.of(context).isPremium;
    if (isPremium) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: padding,
      child: const Center(child: BannerAdView()),
    );
  }
}

class BannerAdView extends StatefulWidget {
  const BannerAdView({super.key});

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final ad = AdService.instance.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) {
            return;
          }
          setState(() {
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
        },
      ),
    );
    if (ad == null) {
      return;
    }
    _ad = ad;
    _ad!.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: _ad!.size.height.toDouble(),
      width: _ad!.size.width.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
