import 'package:flutter/material.dart';

import '../services/ai_algorithm.dart';
import '../services/lotto_api.dart';
import '../services/public_api_service.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  static const String routeName = '/daily';

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  final PublicApiService _publicApi = PublicApiService();
  final LottoApi _lottoApi = LottoApi();
  final AIAlgorithmService _ai = AIAlgorithmService.instance;
  final TextEditingController _dreamController = TextEditingController();

  late Future<_DailyBundle> _bundleFuture;

  @override
  void initState() {
    super.initState();
    _bundleFuture = _loadBundle();
  }

  @override
  void dispose() {
    _dreamController.dispose();
    super.dispose();
  }

  Future<_DailyBundle> _loadBundle() async {
    final resultsFuture = _lottoApi.fetchRecentResults(count: 18);
    final weatherFuture = _publicApi.fetchWeather();
    final fortuneFuture = _publicApi.fetchFortune();
    final newsFuture = _publicApi.fetchNews();

    final recommendation = await _ai.generateRecommendation(
      await resultsFuture,
      dreamKeyword: _dreamController.text.trim().isEmpty
          ? null
          : _dreamController.text.trim(),
    );
    final weather = await weatherFuture;
    final fortune = await fortuneFuture;
    final news = await newsFuture;

    return _DailyBundle(
      weather: weather,
      fortune: fortune,
      news: news,
      recommendation: recommendation,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _bundleFuture = _loadBundle();
    });
    await _bundleFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 운세'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: FutureBuilder<_DailyBundle>(
        future: _bundleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(onRetry: _refresh);
          }
          final bundle = snapshot.data;
          if (bundle == null) {
            return _ErrorState(onRetry: _refresh);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              _DreamInput(
                controller: _dreamController,
                onSubmitted: (_) => _refresh(),
              ),
              const SizedBox(height: 14),
              _WeatherCard(weather: bundle.weather),
              const SizedBox(height: 14),
              _FortuneCard(fortune: bundle.fortune),
              const SizedBox(height: 14),
              _LuckyNumbersCard(recommendation: bundle.recommendation),
              const SizedBox(height: 14),
              _NewsCard(news: bundle.news),
            ],
          );
        },
      ),
    );
  }
}

class _DreamInput extends StatelessWidget {
  const _DreamInput({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: '오늘 기억나는 꿈 키워드',
        hintText: '예) 바다, 용, 숫자 7',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        suffixIcon: IconButton(
          onPressed: () => onSubmitted(controller.text),
          icon: const Icon(Icons.auto_graph_rounded),
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.weather});

  final DailyWeather weather;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, color: Color(0xFFE97C40)),
              const SizedBox(width: 10),
              Text(
                '오늘 날씨',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                weather.summary,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${weather.temperature.toStringAsFixed(1)}℃',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              Text(
                  '최고 ${weather.max.toStringAsFixed(0)}℃ · 최저 ${weather.min.toStringAsFixed(0)}℃'),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.air_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('${weather.windSpeed.toStringAsFixed(1)} m/s'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FortuneCard extends StatelessWidget {
  const _FortuneCard({required this.fortune});

  final DailyFortune fortune;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1C6FB7)),
              const SizedBox(width: 10),
              Text(
                fortune.mood,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fortune.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: fortune.luckScore / 100,
              minHeight: 10,
              backgroundColor: const Color(0xFFECE4D8),
              color: const Color(0xFF1C6FB7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '행운 지수 ${fortune.luckScore}점',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _LuckyNumbersCard extends StatelessWidget {
  const _LuckyNumbersCard({required this.recommendation});

  final AIRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final topStrategy = recommendation.performance.entries.toList()
      ..sort((a, b) => b.value.successRate.compareTo(a.value.successRate));
    final best = topStrategy.isNotEmpty ? topStrategy.first : null;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFF8AC7FF)),
              const SizedBox(width: 10),
              Text(
                '오늘의 행운 번호',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '신뢰도 ${recommendation.confidence.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommendation.numbers
                .map((n) => _NumberBall(number: n))
                .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            '추천 전략: ${recommendation.strategy.label}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (best != null) ...[
            const SizedBox(height: 4),
            Text(
              '최근 효자 전략: ${best.key.label} · 적중률 ${(best.value.successRate * 100).round()}%',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.news});

  final List<DailyNewsItem> news;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.newspaper_rounded, color: Color(0xFF2E4A62)),
              const SizedBox(width: 10),
              Text(
                '오늘의 소식',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...news.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.source} · ${_formatDate(item.publishedAt)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$month/$day ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
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
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
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
              '오늘 정보를 불러오지 못했습니다.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyBundle {
  const _DailyBundle({
    required this.weather,
    required this.fortune,
    required this.news,
    required this.recommendation,
  });

  final DailyWeather weather;
  final DailyFortune fortune;
  final List<DailyNewsItem> news;
  final AIRecommendation recommendation;
}
