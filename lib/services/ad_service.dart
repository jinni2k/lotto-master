import 'package:flutter/material.dart';

import '../providers/user_provider.dart';

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  Future<void> initialize() async {
    // 광고 비활성화 (AdMob 설정 필요)
  }
}

class PremiumAwareBanner extends StatelessWidget {
  const PremiumAwareBanner({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    // 광고 비활성화
    return const SizedBox.shrink();
  }
}

class BannerAdView extends StatelessWidget {
  const BannerAdView({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
