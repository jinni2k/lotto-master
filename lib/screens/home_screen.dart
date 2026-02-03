import 'dart:async';

import 'package:flutter/material.dart';

import '../models/lotto_result.dart';
import '../providers/user_provider.dart';
import '../screens/compare_screen.dart';
import '../screens/dream_screen.dart';
import '../screens/fortune_screen.dart';
import '../screens/lucky_store_screen.dart';
import '../screens/premium_screen.dart';
import '../screens/currency_screen.dart';
import '../screens/simulation_screen.dart';
import '../services/ad_service.dart';
import '../services/holiday_service.dart';
import '../services/fortune_service.dart';
import '../services/lotto_api.dart';
import '../services/notification_service.dart';
import '../widgets/lotto_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LottoApi _lottoApi = LottoApi();
  final FortuneService _fortuneService = const FortuneService();
  final HolidayService _holidayService = HolidayService();
  List<LottoResult> _results = [];
  DateTime? _lastUpdated;
  bool _loading = true;
  String? _errorMessage;
  FortuneResult? _fortune;
  List<int> _dailyLuckyNumbers = [];
  Timer? _ddayTimer;
  Duration _dday = Duration.zero;
  late DateTime _nextDraw;
  Holiday? _nextHoliday;

  @override
  void initState() {
    super.initState();
    _nextDraw = NotificationService.instance.nextDrawTime();
    _fortune = _fortuneService.generateFortune(
      birthday: DateTime.now().subtract(const Duration(days: 12000)),
      byZodiac: true,
    );
    _dailyLuckyNumbers = _fortune?.luckyNumbers ?? [3, 12, 18, 24, 33, 41];
    _loadHoliday();
    _updateCountdown();
    _ddayTimer = Timer.periodic(const Duration(minutes: 1), (_) => _updateCountdown());
    _loadData();
  }

  @override
  void dispose() {
    _ddayTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final results = await _lottoApi.fetchRecentResults(count: 10);
      if (!mounted) {
        return;
      }
      setState(() {
        _results = results;
        _lastUpdated = DateTime.now();
        _loading = false;
        _dailyLuckyNumbers = _topNumbers();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '데이터를 불러오지 못했어요.';
        _loading = false;
      });
    }
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final diff = _nextDraw.difference(now);
    setState(() {
      _dday = diff.isNegative ? Duration.zero : diff;
    });
  }

  Future<void> _loadHoliday() async {
    final now = DateTime.now();
    final holidays = await _holidayService.fetchHolidays(year: now.year, month: now.month);
    final upcoming = holidays
        .where((h) => !h.date.isBefore(DateTime(now.year, now.month, now.day)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (upcoming.isNotEmpty) {
      setState(() {
        _nextHoliday = upcoming.first;
      });
      return;
    }
    final nextMonth = now.add(const Duration(days: 32));
    final nextList = await _holidayService.fetchHolidays(year: nextMonth.year, month: nextMonth.month);
    final sorted = List<Holiday>.from(nextList)..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.isNotEmpty) {
      setState(() {
        _nextHoliday = sorted.first;
      });
    }
  }

  List<int> _topNumbers() {
    final counts = <int, int>{};
    for (final result in _results) {
      for (final number in result.numbers) {
        counts[number] = (counts[number] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.length >= 6) {
      return sorted.take(6).map((e) => e.key).toList();
    }
    return _dailyLuckyNumbers.isNotEmpty ? _dailyLuckyNumbers : [3, 9, 17, 24, 33, 41];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _LuxeBackground(),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroHeader(
                    onRefresh: _loadData,
                    isLoading: _loading,
                    lastUpdated: _lastUpdated,
                    nextDrawTime: NotificationService.instance.nextDrawTime(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _PremiumCTA(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _QuickActions(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _HomeInsights(
                      dday: _dday,
                      nextDraw: _nextDraw,
                      fortune: _fortune,
                      luckyNumbers: _dailyLuckyNumbers,
                      nextHoliday: _nextHoliday,
                      onOpenFortune: () => Navigator.pushNamed(context, FortuneScreen.routeName),
                      onOpenCurrency: () => Navigator.pushNamed(context, CurrencyScreen.routeName),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          title: '최근 10회차 당첨 번호',
                          subtitle: '동행복권 API 기반 데이터',
                        ),
                        const SizedBox(height: 12),
                        _RecentRoundsList(
                          results: _results,
                          isLoading: _loading,
                          errorMessage: _errorMessage,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          title: '번호별 출현 빈도',
                          subtitle: '최근 10회차 기준',
                        ),
                        const SizedBox(height: 12),
                        _FrequencyGrid(results: _results),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          title: '빈도 기반 추천 번호',
                          subtitle: '출현 빈도 상위 조합',
                        ),
                        const SizedBox(height: 12),
                        _RecommendationCard(results: _results),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: PremiumAwareBanner(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LuxeBackground extends StatelessWidget {
  const _LuxeBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.background,
            scheme.primary.withOpacity(0.16),
            scheme.secondary.withOpacity(0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _PremiumCTA extends StatelessWidget {
  const _PremiumCTA();

  @override
  Widget build(BuildContext context) {
    final user = UserProviderScope.of(context);
    if (user.isPremium) {
      return _PremiumActiveCard(onPressed: () {
        Navigator.pushNamed(context, PremiumScreen.routeName);
      });
    }
    return _PremiumUpsellCard(onPressed: () {
      Navigator.pushNamed(context, PremiumScreen.routeName);
    });
  }
}

class _PremiumActiveCard extends StatelessWidget {
  const _PremiumActiveCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: scheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '프리미엄 이용 중',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: const Text('관리'),
          ),
        ],
      ),
    );
  }
}

class _PremiumUpsellCard extends StatelessWidget {
  const _PremiumUpsellCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.star_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '프리미엄으로 업그레이드',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '광고 제거와 심화 리포트를 확인하세요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.65),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onPressed,
            child: const Text('보기'),
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.onRefresh,
    required this.isLoading,
    required this.lastUpdated,
    required this.nextDrawTime,
  });

  final VoidCallback onRefresh;
  final bool isLoading;
  final DateTime? lastUpdated;
  final DateTime nextDrawTime;

  String _formatDateTime(DateTime time) {
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.95),
            colorScheme.secondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lotto Master',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
              ),
              _LiveBadge(isLoading: isLoading),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '당첨 데이터를 실시간으로 갱신합니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimary.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(label: '마지막 업데이트: ${lastUpdated == null ? '-' : _formatDateTime(lastUpdated!)}'),
              _InfoChip(label: '다음 알림: ${_formatDateTime(nextDrawTime)}'),
              const _InfoChip(label: '최근 10회차'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('데이터 새로고침'),
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              color: colorScheme.onPrimary,
              backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isLoading ? colorScheme.secondary : Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isLoading ? '로딩 중' : 'LIVE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionCard(
        title: '당첨 비교',
        subtitle: '내 티켓과 결과 매칭',
        icon: Icons.compare_arrows_rounded,
        onTap: () => Navigator.pushNamed(context, CompareScreen.routeName),
      ),
      _ActionCard(
        title: '꿈 해몽',
        subtitle: '키워드별 행운 번호',
        icon: Icons.auto_stories_rounded,
        onTap: () => Navigator.pushNamed(context, DreamScreen.routeName),
      ),
      _ActionCard(
        title: '환율 계산',
        subtitle: '당첨금 달러/엔/유로',
        icon: Icons.currency_exchange_rounded,
        onTap: () => Navigator.pushNamed(context, CurrencyScreen.routeName),
      ),
      _ActionCard(
        title: '행운 판매점',
        subtitle: '명당 지도 보기',
        icon: Icons.map_rounded,
        onTap: () => Navigator.pushNamed(context, LuckyStoreScreen.routeName),
      ),
      _ActionCard(
        title: '운세',
        subtitle: '띠·별자리·행운 번호',
        icon: Icons.auto_awesome_rounded,
        onTap: () => Navigator.pushNamed(context, FortuneScreen.routeName),
      ),
      _ActionCard(
        title: '시뮬레이션',
        subtitle: '당첨금 사용 플랜',
        icon: Icons.savings_rounded,
        onTap: () => Navigator.pushNamed(context, SimulationScreen.routeName),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map((item) => SizedBox(width: width, child: item))
              .toList(growable: false),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withOpacity(0.65),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeInsights extends StatelessWidget {
  const _HomeInsights({
    required this.dday,
    required this.nextDraw,
    required this.fortune,
    required this.luckyNumbers,
    required this.nextHoliday,
    required this.onOpenFortune,
    required this.onOpenCurrency,
  });

  final Duration dday;
  final DateTime nextDraw;
  final FortuneResult? fortune;
  final List<int> luckyNumbers;
  final Holiday? nextHoliday;
  final VoidCallback onOpenFortune;
  final VoidCallback onOpenCurrency;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remainingDays = dday.inDays;
    final hours = dday.inHours % 24;
    final minutes = dday.inMinutes % 60;
    final ddayLabel = remainingDays <= 0 && hours <= 0 && minutes <= 0
        ? '오늘 추첨'
        : 'D-${remainingDays} · ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} 남음';

    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.timer_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('다음 추첨까지', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(ddayLabel, style: Theme.of(context).textTheme.bodyMedium),
                    if (nextHoliday != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '가장 가까운 공휴일: ${_formatDate(nextHoliday!.date)} ${nextHoliday!.name}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurface.withOpacity(0.65)),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                _formatDate(nextDraw),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome_rounded, color: scheme.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('오늘의 운세', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      fortune?.message ?? '행운 가득한 하루가 될 거예요.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenFortune,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.numbers_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('추천 번호 요약', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: luckyNumbers
                          .map((n) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(n.toString().padLeft(2, '0'),
                                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenCurrency,
                icon: const Icon(Icons.attach_money_rounded),
                tooltip: '환산 보기',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime time) {
    return '${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.65),
              ),
        ),
      ],
    );
  }
}

class _RecentRoundsList extends StatelessWidget {
  const _RecentRoundsList({
    required this.results,
    required this.isLoading,
    required this.errorMessage,
  });

  final List<LottoResult> results;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading && results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return GlassCard(
        child: Text(
          errorMessage!,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return Column(
      children: results
          .map(
            (round) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RoundCard(result: round),
            ),
          )
          .toList(),
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.result});

  final LottoResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${result.drawNo}회차',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                result.drawDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...result.numbers.asMap().entries.map(
                    (entry) => NumberBall(
                      number: entry.value,
                      isBonus: false,
                      delay: Duration(milliseconds: 80 * entry.key),
                    ),
                  ),
              NumberBall(
                number: result.bonus,
                isBonus: true,
                delay: const Duration(milliseconds: 520),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FrequencyGrid extends StatelessWidget {
  const _FrequencyGrid({required this.results});

  final List<LottoResult> results;

  Map<int, int> _buildFrequency() {
    final counts = <int, int>{};
    for (final result in results) {
      for (final number in result.numbers) {
        counts[number] = (counts[number] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _buildFrequency();
    final items = List.generate(12, (index) {
      final number = index + 1;
      return _FrequencyItem(number: number, count: counts[number] ?? 0);
    });

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.3,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return _FrequencyChip(item: item);
        },
      ),
    );
  }
}

class _FrequencyItem {
  const _FrequencyItem({required this.number, required this.count});

  final int number;
  final int count;
}

class _FrequencyChip extends StatelessWidget {
  const _FrequencyChip({required this.item});

  final _FrequencyItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item.number.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text(
            '${item.count}회',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.results});

  final List<LottoResult> results;

  List<int> _recommendNumbers() {
    final counts = <int, int>{};
    for (final result in results) {
      for (final number in result.numbers) {
        counts[number] = (counts[number] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(6).map((entry) => entry.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recommended = results.isEmpty ? [3, 9, 17, 24, 33, 41] : _recommendNumbers();
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추천 조합 1',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommended
                .asMap()
                .entries
                .map(
                  (entry) => NumberBall(
                    number: entry.value,
                    isBonus: false,
                    delay: Duration(milliseconds: 80 * entry.key),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            '추천 기준: 최근 10회차 빈도 상위 번호 중 균형 분포',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }
}
