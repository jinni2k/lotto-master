import 'package:flutter/material.dart';

import '../providers/user_provider.dart';
import '../screens/premium_screen.dart';
import '../services/ad_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HeroHeader(
              onRefresh: () {},
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SectionTitle(
                    title: '최근 10회차 당첨 번호',
                    subtitle: '동행복권 API 기반 데이터',
                  ),
                  SizedBox(height: 12),
                  _RecentRoundsList(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SectionTitle(
                    title: '번호별 출현 빈도',
                    subtitle: '최근 10회차 기준',
                  ),
                  SizedBox(height: 12),
                  _FrequencyGrid(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _SectionTitle(
                    title: '빈도 기반 추천 번호',
                    subtitle: '출현 빈도 상위 조합',
                  ),
                  SizedBox(height: 12),
                  _RecommendationCard(),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1E4CC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: Color(0xFF2E7D32)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFE6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.star_rounded, color: Color(0xFF1A4F7A)),
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
                        color: Colors.black54,
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
  const _HeroHeader({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.9),
            colorScheme.primary.withOpacity(0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lotto Master',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '과거 당첨 데이터를 불러와 분석합니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(label: 'API 연결 준비'),
              const SizedBox(width: 8),
              _InfoChip(label: '최근 10회차'),
              const SizedBox(width: 8),
              _InfoChip(label: '빈도 분석'),
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
        ],
      ),
    );
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
                color: Colors.black54,
              ),
        ),
      ],
    );
  }
}

class _RecentRoundsList extends StatelessWidget {
  const _RecentRoundsList();

  @override
  Widget build(BuildContext context) {
    final rounds = List.generate(10, (index) {
      final roundNumber = 1120 - index;
      return _RoundResult(
        round: roundNumber,
        date: '2026-02-${3 - index}'.padLeft(10, '0'),
        numbers: [5, 11, 20, 23, 32, 41],
        bonus: 7,
      );
    });

    return Column(
      children: rounds
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

class _RoundResult {
  const _RoundResult({
    required this.round,
    required this.date,
    required this.numbers,
    required this.bonus,
  });

  final int round;
  final String date;
  final List<int> numbers;
  final int bonus;
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.result});

  final _RoundResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                '${result.round}회차',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                result.date,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...result.numbers.map(
                (number) => _NumberBall(number: number, isBonus: false),
              ),
              _NumberBall(number: result.bonus, isBonus: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberBall extends StatelessWidget {
  const _NumberBall({required this.number, required this.isBonus});

  final int number;
  final bool isBonus;

  @override
  Widget build(BuildContext context) {
    final baseColor = isBonus ? const Color(0xFFE97C40) : const Color(0xFF1A4F7A);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: baseColor.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _FrequencyGrid extends StatelessWidget {
  const _FrequencyGrid();

  @override
  Widget build(BuildContext context) {
    final items = List.generate(12, (index) {
      return _FrequencyItem(number: index + 1, count: 4 + (index % 5));
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D6C6)),
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
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
            children: const [
              _NumberBall(number: 3, isBonus: false),
              _NumberBall(number: 9, isBonus: false),
              _NumberBall(number: 17, isBonus: false),
              _NumberBall(number: 24, isBonus: false),
              _NumberBall(number: 33, isBonus: false),
              _NumberBall(number: 41, isBonus: false),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '추천 기준: 최근 10회차 빈도 상위 번호 중 균형 분포',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}
