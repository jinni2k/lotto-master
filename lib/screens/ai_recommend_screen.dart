import 'package:flutter/material.dart';

import '../services/ai_algorithm.dart';
import '../services/lotto_api.dart';

class AIRecommendScreen extends StatefulWidget {
  const AIRecommendScreen({super.key});

  static const String routeName = '/ai-recommend';

  @override
  State<AIRecommendScreen> createState() => _AIRecommendScreenState();
}

class _AIRecommendScreenState extends State<AIRecommendScreen> {
  final LottoApi _api = LottoApi();
  final AIAlgorithmService _ai = AIAlgorithmService.instance;
  final TextEditingController _dreamController = TextEditingController();
  late Future<AIRecommendation> _recommendationFuture;
  AIOutcomeReport? _lastOutcome;
  bool _evaluating = false;

  @override
  void initState() {
    super.initState();
    _recommendationFuture = _loadRecommendation();
  }

  @override
  void dispose() {
    _dreamController.dispose();
    super.dispose();
  }

  Future<AIRecommendation> _loadRecommendation() async {
    final results = await _api.fetchRecentResults(count: 30);
    final dreamKeyword = _dreamController.text.trim();
    return _ai.generateRecommendation(
      results,
      dreamKeyword: dreamKeyword.isEmpty ? null : dreamKeyword,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _recommendationFuture = _loadRecommendation();
      _lastOutcome = null;
    });
    await _recommendationFuture;
  }

  Future<void> _evaluate() async {
    setState(() {
      _evaluating = true;
    });
    try {
      final latest = await _api.fetchLatestResult();
      final outcome = await _ai.evaluateRecommendation(latest);
      if (!mounted) {
        return;
      }
      setState(() {
        _lastOutcome = outcome;
      });
    } finally {
      if (mounted) {
        setState(() {
          _evaluating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 진화 추천'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<AIRecommendation>(
        future: _recommendationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(onRetry: _refresh);
          }

          final recommendation = snapshot.data;
          if (recommendation == null) {
            return _ErrorState(onRetry: _refresh);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _DreamKeywordField(
                controller: _dreamController,
                onSubmit: (_) => _refresh(),
              ),
              const SizedBox(height: 16),
              _HeaderCard(
                strategy: recommendation.strategy,
                onEvaluate: _evaluating ? null : _evaluate,
              ),
              const SizedBox(height: 16),
              _RecommendationCard(
                numbers: recommendation.numbers,
                confidence: recommendation.confidence,
                overall: recommendation.overall,
              ),
              const SizedBox(height: 16),
              _ReasonCard(reasons: recommendation.reasons),
              const SizedBox(height: 16),
              _PerformanceCard(
                performance: recommendation.performance,
                overall: recommendation.overall,
              ),
              if (_lastOutcome != null) ...[
                const SizedBox(height: 16),
                _OutcomeCard(outcome: _lastOutcome!),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _DreamKeywordField extends StatelessWidget {
  const _DreamKeywordField({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: '꿈/키워드로 학습 강화',
                hintText: '예) 호수, 숫자 7, 용',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: onSubmit,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => onSubmit(controller.text),
            child: const Text('반영'),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.strategy, required this.onEvaluate});

  final AIStrategyType strategy;
  final VoidCallback? onEvaluate;

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
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '전략: ${strategy.label}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '성과 기반 가중치로 자동 조정 중',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onEvaluate,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('적중 평가'),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.numbers,
    required this.confidence,
    required this.overall,
  });

  final List<int> numbers;
  final double confidence;
  final StrategyPerformance overall;

  @override
  Widget build(BuildContext context) {
    final rate = (overall.successRate * 100).round();
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
            'AI 추천 번호',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                numbers.map((number) => _NumberBall(number: number)).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            '신뢰도 ${confidence.toStringAsFixed(0)}점',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: confidence / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFECE4D8),
              color: const Color(0xFF1C6FB7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '과거 AI 추천 적중률 ${rate}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.reasons});

  final List<String> reasons;

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
            '추천 근거',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...reasons.map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle,
                      size: 18, color: Color(0xFF1C6FB7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.performance, required this.overall});

  final Map<AIStrategyType, StrategyPerformance> performance;
  final StrategyPerformance overall;

  @override
  Widget build(BuildContext context) {
    final entries = performance.entries.toList()
      ..sort((a, b) => b.value.successRate.compareTo(a.value.successRate));
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
            '전략별 성과 비교',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...entries.map(
            (entry) => _PerformanceRow(
              label: entry.key.label,
              performance: entry.value,
            ),
          ),
          const Divider(height: 24),
          Text(
            '총 ${overall.attempts}회 평가 · 적중 ${overall.wins}회',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.label, required this.performance});

  final String label;
  final StrategyPerformance performance;

  @override
  Widget build(BuildContext context) {
    final rate = (performance.successRate * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            '$rate% (${performance.wins}/${performance.attempts})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.outcome});

  final AIOutcomeReport outcome;

  @override
  Widget build(BuildContext context) {
    final resultText = outcome.isSuccess ? '성공 패턴 반영' : '실패 패턴 학습';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 회차 평가',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '맞춘 개수 ${outcome.matchCount}개 · $resultText',
            style: Theme.of(context).textTheme.bodySmall,
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
              'AI 추천 데이터를 불러오지 못했습니다.',
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
