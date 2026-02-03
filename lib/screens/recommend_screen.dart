import 'package:flutter/material.dart';

import '../models/lotto_result.dart';
import '../providers/user_provider.dart';
import '../screens/ai_recommend_screen.dart';
import '../screens/premium_screen.dart';
import '../services/ad_service.dart';
import '../services/lotto_api.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});

  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final LottoApi _api = LottoApi();
  late Future<List<LottoResult>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _resultsFuture = _api.fetchRecentResults();
  }

  Future<void> _refresh() async {
    setState(() {
      _resultsFuture = _api.fetchRecentResults();
    });
    await _resultsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<LottoResult>>(
        future: _resultsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(onRetry: _refresh);
          }

          final results = snapshot.data ?? [];
          final frequency = _buildFrequency(results);
          final recommendation = _buildRecommendation(frequency);

          final isPremium = UserProviderScope.of(context).isPremium;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _ScreenHeader(onRefresh: _refresh),
                const SizedBox(height: 16),
                const _AIIntroCard(),
                const SizedBox(height: 16),
                _RecommendationCard(numbers: recommendation),
                const SizedBox(height: 16),
                _FrequencyHint(frequency: frequency),
                const SizedBox(height: 16),
                if (isPremium)
                  _PremiumRecommendation(numbers: recommendation)
                else
                  const _PremiumLockedCard(),
                const SizedBox(height: 16),
                const PremiumAwareBanner(),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<int, int> _buildFrequency(List<LottoResult> results) {
    final frequency = <int, int>{};
    for (var i = 1; i <= 45; i++) {
      frequency[i] = 0;
    }

    for (final result in results) {
      for (final number in result.numbers) {
        frequency[number] = (frequency[number] ?? 0) + 1;
      }
    }
    return frequency;
  }

  List<int> _buildRecommendation(Map<int, int> frequency) {
    final sorted = frequency.entries.toList()
      ..sort((a, b) {
        final compare = b.value.compareTo(a.value);
        return compare != 0 ? compare : a.key.compareTo(b.key);
      });

    final selected = sorted.take(6).map((entry) => entry.key).toList();
    var next = 1;
    while (selected.length < 6 && next <= 45) {
      if (!selected.contains(next)) {
        selected.add(next);
      }
      next += 1;
    }

    selected.sort();
    return selected;
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '추천',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '최근 10회차 빈도 기반 추천입니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.numbers});

  final List<int> numbers;

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
            children: numbers
                .map((number) => _NumberBall(number: number))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            '추천 기준: 최근 10회차 상위 빈도 번호 우선',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}

class _AIIntroCard extends StatelessWidget {
  const _AIIntroCard();

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
            'AI 진화 추천',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '패턴 학습과 성과 추적을 반영한 맞춤 추천을 확인해보세요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AIRecommendScreen.routeName);
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('AI 추천 보기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberBall extends StatelessWidget {
  const _NumberBall({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF1A4F7A);
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

class _FrequencyHint extends StatelessWidget {
  const _FrequencyHint({required this.frequency});

  final Map<int, int> frequency;

  @override
  Widget build(BuildContext context) {
    final sorted = frequency.entries.toList()
      ..sort((a, b) {
        final compare = b.value.compareTo(a.value);
        return compare != 0 ? compare : a.key.compareTo(b.key);
      });
    final top = sorted.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상위 10개 번호',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: top
                .map(
                  (entry) => _TopNumberChip(
                    number: entry.key,
                    count: entry.value,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TopNumberChip extends StatelessWidget {
  const _TopNumberChip({required this.number, required this.count});

  final int number;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number.toString().padLeft(2, '0'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            '${count}회',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '추천 데이터를 불러오지 못했습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumLockedCard extends StatelessWidget {
  const _PremiumLockedCard();

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
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: Color(0xFF1A4F7A)),
              const SizedBox(width: 8),
              Text(
                '프리미엄 추천',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '고급 모델 기반 추천 조합과 검증 지표를 제공합니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, PremiumScreen.routeName);
              },
              child: const Text('프리미엄 보기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumRecommendation extends StatelessWidget {
  const _PremiumRecommendation({required this.numbers});

  final List<int> numbers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프리미엄 추천 조합',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: numbers
                .reversed
                .map((number) => _NumberBall(number: number))
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '추가 검증: 최근 30회차 구간 편향 최소화',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}
