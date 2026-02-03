import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lotto_result.dart';
import 'dream_service.dart';

enum AIStrategyType {
  frequency,
  pattern,
  random,
  dream,
}

extension AIStrategyTypeLabel on AIStrategyType {
  String get label {
    switch (this) {
      case AIStrategyType.frequency:
        return '빈도 기반';
      case AIStrategyType.pattern:
        return '패턴 기반';
      case AIStrategyType.random:
        return '랜덤';
      case AIStrategyType.dream:
        return '꿈 기반';
    }
  }

  String get shortKey => name;
}

class StrategyPerformance {
  const StrategyPerformance({required this.attempts, required this.wins});

  final int attempts;
  final int wins;

  double get successRate => attempts == 0 ? 0 : wins / attempts;

  StrategyPerformance copyWith({int? attempts, int? wins}) {
    return StrategyPerformance(
      attempts: attempts ?? this.attempts,
      wins: wins ?? this.wins,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attempts': attempts,
      'wins': wins,
    };
  }

  factory StrategyPerformance.fromJson(Map<String, dynamic> json) {
    return StrategyPerformance(
      attempts: json['attempts'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
    );
  }
}

class AIRecommendation {
  const AIRecommendation({
    required this.numbers,
    required this.strategy,
    required this.confidence,
    required this.reasons,
    required this.performance,
    required this.overall,
  });

  final List<int> numbers;
  final AIStrategyType strategy;
  final double confidence;
  final List<String> reasons;
  final Map<AIStrategyType, StrategyPerformance> performance;
  final StrategyPerformance overall;
}

class AIOutcomeReport {
  const AIOutcomeReport({
    required this.matchCount,
    required this.isSuccess,
    required this.strategy,
    required this.performance,
    required this.overall,
    required this.evaluatedAt,
  });

  final int matchCount;
  final bool isSuccess;
  final AIStrategyType strategy;
  final Map<AIStrategyType, StrategyPerformance> performance;
  final StrategyPerformance overall;
  final DateTime evaluatedAt;
}

class AIAlgorithmService {
  AIAlgorithmService._();

  static final AIAlgorithmService instance = AIAlgorithmService._();

  static const String _statsKey = 'ai_strategy_stats_v1';
  static const String _lastKey = 'ai_last_recommendation_v1';

  final Random _random = Random();

  Future<AIRecommendation> generateRecommendation(
    List<LottoResult> results, {
    String? dreamKeyword,
  }) async {
    final analysis = _analyzeResults(results);
    final snapshot = await _loadPerformance();
    final weights = _buildWeights(snapshot);
    final strategy = _pickStrategy(weights);
    final numbers = await _buildNumbers(strategy, analysis, dreamKeyword: dreamKeyword);
    final confidence = _buildConfidence(strategy, analysis, snapshot);
    final reasons = _buildReasons(strategy, analysis, dreamKeyword: dreamKeyword);
    await _storeLastRecommendation(numbers, strategy);

    return AIRecommendation(
      numbers: numbers,
      strategy: strategy,
      confidence: confidence,
      reasons: reasons,
      performance: snapshot.byStrategy,
      overall: snapshot.overall,
    );
  }

  Future<AIOutcomeReport?> evaluateRecommendation(LottoResult result) async {
    final last = await _loadLastRecommendation();
    if (last == null) {
      return null;
    }

    final matchCount = _matchCount(result.numbers, last.numbers);
    final isSuccess = matchCount >= 3;
    final updated = await _updatePerformance(last.strategy, isSuccess);

    return AIOutcomeReport(
      matchCount: matchCount,
      isSuccess: isSuccess,
      strategy: last.strategy,
      performance: updated.byStrategy,
      overall: updated.overall,
      evaluatedAt: DateTime.now(),
    );
  }

  _PatternAnalysis _analyzeResults(List<LottoResult> results) {
    final frequency = <int, int>{for (var i = 1; i <= 45; i++) i: 0};
    var oddTotal = 0;
    var consecutiveHit = 0;
    var low = 0;
    var mid = 0;
    var high = 0;

    for (final result in results) {
      var oddCount = 0;
      final sorted = [...result.numbers]..sort();
      var hasConsecutive = false;
      for (var i = 0; i < sorted.length; i++) {
        final number = sorted[i];
        frequency[number] = (frequency[number] ?? 0) + 1;
        if (number.isOdd) {
          oddCount += 1;
        }
        if (number <= 15) {
          low += 1;
        } else if (number <= 30) {
          mid += 1;
        } else {
          high += 1;
        }
        if (i > 0 && sorted[i] - sorted[i - 1] == 1) {
          hasConsecutive = true;
        }
      }
      oddTotal += oddCount;
      if (hasConsecutive) {
        consecutiveHit += 1;
      }
    }

    final averageOdd = results.isEmpty ? 3 : (oddTotal / results.length).round();
    final clampedOdd = averageOdd.clamp(2, 4).toInt();
    final totalNumbers = results.isEmpty ? 1 : results.length * 6;
    final lowTarget = _normalizedCount(low, totalNumbers);
    final midTarget = _normalizedCount(mid, totalNumbers);
    final highTarget = _normalizedCount(high, totalNumbers);
    final rangeTargets = _buildRangeTargets(lowTarget, midTarget, highTarget);
    final consecutiveRate = results.isEmpty ? 0.0 : consecutiveHit / results.length;

    return _PatternAnalysis(
      frequency: frequency,
      preferredOddCount: clampedOdd,
      rangeTargets: rangeTargets,
      consecutiveRate: consecutiveRate,
    );
  }

  int _normalizedCount(int value, int totalNumbers) {
    final ratio = value / totalNumbers;
    return (ratio * 6).round();
  }

  Map<String, int> _buildRangeTargets(int low, int mid, int high) {
    var sum = low + mid + high;
    var lowTarget = low;
    var midTarget = mid;
    var highTarget = high;
    if (sum == 0) {
      return {'low': 2, 'mid': 2, 'high': 2};
    }
    while (sum < 6) {
      if (lowTarget <= midTarget && lowTarget <= highTarget) {
        lowTarget += 1;
      } else if (midTarget <= highTarget) {
        midTarget += 1;
      } else {
        highTarget += 1;
      }
      sum += 1;
    }
    while (sum > 6) {
      if (highTarget >= midTarget && highTarget >= lowTarget) {
        highTarget -= 1;
      } else if (midTarget >= lowTarget) {
        midTarget -= 1;
      } else {
        lowTarget -= 1;
      }
      sum -= 1;
    }

    return {'low': lowTarget, 'mid': midTarget, 'high': highTarget};
  }

  Map<AIStrategyType, double> _buildWeights(_PerformanceSnapshot snapshot) {
    const base = 1.0;
    final weights = <AIStrategyType, double>{};
    for (final entry in snapshot.byStrategy.entries) {
      final perf = entry.value;
      final successBoost = perf.successRate * 2.4;
      final attemptBoost = perf.attempts == 0
          ? 0.1
          : (perf.attempts * 0.02).clamp(0.0, 0.6).toDouble();
      weights[entry.key] = base + successBoost + attemptBoost;
    }
    return weights;
  }

  AIStrategyType _pickStrategy(Map<AIStrategyType, double> weights) {
    final total = weights.values.fold<double>(0, (sum, value) => sum + value);
    var pick = _random.nextDouble() * total;
    for (final entry in weights.entries) {
      pick -= entry.value;
      if (pick <= 0) {
        return entry.key;
      }
    }
    return AIStrategyType.frequency;
  }

  Future<List<int>> _buildNumbers(
    AIStrategyType strategy,
    _PatternAnalysis analysis, {
    String? dreamKeyword,
  }) async {
    switch (strategy) {
      case AIStrategyType.frequency:
        return _buildFrequencyNumbers(analysis);
      case AIStrategyType.pattern:
        return _buildPatternNumbers(analysis);
      case AIStrategyType.random:
        return _buildRandomNumbers();
      case AIStrategyType.dream:
        return _buildDreamNumbers(dreamKeyword);
    }
  }

  List<int> _buildFrequencyNumbers(_PatternAnalysis analysis) {
    final entries = analysis.frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(18).toList();
    final selected = <int>{};
    while (selected.length < 6) {
      final pick = _weightedPick(top);
      selected.add(pick);
    }
    final numbers = selected.toList()..sort();
    return numbers;
  }

  List<int> _buildPatternNumbers(_PatternAnalysis analysis) {
    final selected = <int>{};
    var oddTarget = analysis.preferredOddCount;
    final ranges = {
      'low': List.generate(15, (index) => index + 1),
      'mid': List.generate(15, (index) => index + 16),
      'high': List.generate(15, (index) => index + 31),
    };
    for (final entry in analysis.rangeTargets.entries) {
      var count = entry.value;
      final candidates = ranges[entry.key] ?? [];
      while (count > 0 && candidates.isNotEmpty) {
        final picked = _weightedPickNumbers(candidates, analysis.frequency);
        if (selected.contains(picked)) {
          continue;
        }
        if (oddTarget > 0 && picked.isOdd) {
          selected.add(picked);
          oddTarget -= 1;
          count -= 1;
        } else if (oddTarget == 0 && picked.isEven) {
          selected.add(picked);
          count -= 1;
        } else if (oddTarget > 0 && picked.isEven) {
          selected.add(picked);
          count -= 1;
        } else if (oddTarget == 0 && picked.isOdd) {
          selected.add(picked);
          count -= 1;
        }
      }
    }

    if (analysis.consecutiveRate > 0.55) {
      final base = _random.nextInt(44) + 1;
      selected.add(base);
      if (selected.length < 6) {
        selected.add(base + 1);
      }
    }

    while (selected.length < 6) {
      final pick = _weightedPickNumbers(List.generate(45, (index) => index + 1), analysis.frequency);
      selected.add(pick);
    }

    final numbers = selected.toList()..sort();
    return numbers;
  }

  List<int> _buildRandomNumbers() {
    final numbers = <int>{};
    while (numbers.length < 6) {
      numbers.add(_random.nextInt(45) + 1);
    }
    final list = numbers.toList()..sort();
    return list;
  }

  Future<List<int>> _buildDreamNumbers(String? dreamKeyword) async {
    final service = DreamService.instance;
    DreamMatch? match;
    if (dreamKeyword != null && dreamKeyword.trim().isNotEmpty) {
      final matches = service.search(dreamKeyword);
      if (matches.isNotEmpty) {
        match = matches.first;
      }
    }
    if (match == null) {
      final entries = await service.loadEntries();
      if (entries.isNotEmpty) {
        final matches = service.search(entries.first.keyword);
        if (matches.isNotEmpty) {
          match = matches.first;
        }
      }
    }
    final allMatches = service.search('');
    match ??= allMatches[_random.nextInt(allMatches.length)];
    final numbers = [...match.numbers]..sort();
    return numbers;
  }

  int _weightedPick(List<MapEntry<int, int>> entries) {
    final total = entries.fold<int>(0, (sum, entry) => sum + entry.value + 1);
    var pick = _random.nextInt(total);
    for (final entry in entries) {
      pick -= entry.value + 1;
      if (pick < 0) {
        return entry.key;
      }
    }
    return entries.first.key;
  }

  int _weightedPickNumbers(List<int> candidates, Map<int, int> frequency) {
    final weights = candidates.map((number) => (frequency[number] ?? 0) + 1).toList();
    final total = weights.fold<int>(0, (sum, value) => sum + value);
    var pick = _random.nextInt(total);
    for (var i = 0; i < candidates.length; i++) {
      pick -= weights[i];
      if (pick < 0) {
        return candidates[i];
      }
    }
    return candidates.first;
  }

  double _buildConfidence(
    AIStrategyType strategy,
    _PatternAnalysis analysis,
    _PerformanceSnapshot snapshot,
  ) {
    final perf = snapshot.byStrategy[strategy] ?? const StrategyPerformance(attempts: 0, wins: 0);
    final performanceBoost = perf.successRate * 32;
    final stabilityBoost = analysis.consecutiveRate * 8;
    final base = 48.0;
    final score = base + performanceBoost + stabilityBoost;
    return score.clamp(35.0, 92.0).toDouble();
  }

  List<String> _buildReasons(
    AIStrategyType strategy,
    _PatternAnalysis analysis, {
    String? dreamKeyword,
  }) {
    final reasons = <String>[];
    final range = analysis.rangeTargets;
    reasons.add('최근 패턴 홀짝 평균 ${analysis.preferredOddCount}:${6 - analysis.preferredOddCount}');
    reasons.add('구간 분포 1~15 ${range['low']}개, 16~30 ${range['mid']}개, 31~45 ${range['high']}개');
    reasons.add('연속 번호 포함 회차 비율 ${(analysis.consecutiveRate * 100).round()}%');
    switch (strategy) {
      case AIStrategyType.frequency:
        reasons.add('최근 상위 빈도 번호를 가중치로 반영');
        break;
      case AIStrategyType.pattern:
        reasons.add('최근 패턴에 맞춰 홀짝과 구간 균형 조정');
        break;
      case AIStrategyType.random:
        reasons.add('편향을 줄이기 위해 무작위 샘플링 적용');
        break;
      case AIStrategyType.dream:
        final keyword = dreamKeyword?.trim();
        reasons.add(keyword == null || keyword.isEmpty ? '꿈 키워드 매칭 데이터 반영' : '꿈 키워드 "$keyword" 매칭 반영');
        break;
    }
    return reasons;
  }

  int _matchCount(List<int> winning, List<int> candidate) {
    final winSet = winning.toSet();
    return candidate.where(winSet.contains).length;
  }

  Future<void> _storeLastRecommendation(List<int> numbers, AIStrategyType strategy) async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'numbers': numbers,
      'strategy': strategy.shortKey,
      'createdAt': DateTime.now().toIso8601String(),
    });
    await prefs.setString(_lastKey, data);
  }

  Future<_StoredRecommendation?> _loadLastRecommendation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final numbers = (json['numbers'] as List<dynamic>?)
            ?.map((value) => value as int)
            .toList(growable: false) ??
        [];
    final strategyKey = json['strategy'] as String?;
    final strategy = AIStrategyType.values.firstWhere(
      (type) => type.shortKey == strategyKey,
      orElse: () => AIStrategyType.frequency,
    );
    return _StoredRecommendation(numbers: numbers, strategy: strategy);
  }

  Future<_PerformanceSnapshot> _loadPerformance() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statsKey);
    if (raw == null || raw.isEmpty) {
      return _PerformanceSnapshot.initial();
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _PerformanceSnapshot.fromJson(json);
  }

  Future<_PerformanceSnapshot> _updatePerformance(AIStrategyType strategy, bool isSuccess) async {
    final snapshot = await _loadPerformance();
    final current = snapshot.byStrategy[strategy] ?? const StrategyPerformance(attempts: 0, wins: 0);
    final updated = current.copyWith(
      attempts: current.attempts + 1,
      wins: current.wins + (isSuccess ? 1 : 0),
    );
    final overall = snapshot.overall.copyWith(
      attempts: snapshot.overall.attempts + 1,
      wins: snapshot.overall.wins + (isSuccess ? 1 : 0),
    );

    final updatedSnapshot = snapshot.copyWith(strategy: strategy, performance: updated, overall: overall);
    await _savePerformance(updatedSnapshot);
    return updatedSnapshot;
  }

  Future<void> _savePerformance(_PerformanceSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(snapshot.toJson()));
  }
}

class _PatternAnalysis {
  const _PatternAnalysis({
    required this.frequency,
    required this.preferredOddCount,
    required this.rangeTargets,
    required this.consecutiveRate,
  });

  final Map<int, int> frequency;
  final int preferredOddCount;
  final Map<String, int> rangeTargets;
  final double consecutiveRate;
}

class _StoredRecommendation {
  const _StoredRecommendation({required this.numbers, required this.strategy});

  final List<int> numbers;
  final AIStrategyType strategy;
}

class _PerformanceSnapshot {
  const _PerformanceSnapshot({required this.byStrategy, required this.overall});

  final Map<AIStrategyType, StrategyPerformance> byStrategy;
  final StrategyPerformance overall;

  factory _PerformanceSnapshot.initial() {
    return _PerformanceSnapshot(
      byStrategy: {
        for (final strategy in AIStrategyType.values)
          strategy: const StrategyPerformance(attempts: 0, wins: 0)
      },
      overall: const StrategyPerformance(attempts: 0, wins: 0),
    );
  }

  _PerformanceSnapshot copyWith({
    AIStrategyType? strategy,
    StrategyPerformance? performance,
    StrategyPerformance? overall,
  }) {
    final updated = Map<AIStrategyType, StrategyPerformance>.from(byStrategy);
    if (strategy != null && performance != null) {
      updated[strategy] = performance;
    }
    return _PerformanceSnapshot(
      byStrategy: updated,
      overall: overall ?? this.overall,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall.toJson(),
      'strategies': {
        for (final entry in byStrategy.entries) entry.key.shortKey: entry.value.toJson(),
      },
    };
  }

  factory _PerformanceSnapshot.fromJson(Map<String, dynamic> json) {
    final strategies = json['strategies'] as Map<String, dynamic>? ?? {};
    final byStrategy = <AIStrategyType, StrategyPerformance>{};
    for (final strategy in AIStrategyType.values) {
      final data = strategies[strategy.shortKey] as Map<String, dynamic>?;
      byStrategy[strategy] = data == null
          ? const StrategyPerformance(attempts: 0, wins: 0)
          : StrategyPerformance.fromJson(data);
    }
    final overallData = json['overall'] as Map<String, dynamic>? ?? {};
    return _PerformanceSnapshot(
      byStrategy: byStrategy,
      overall: StrategyPerformance.fromJson(overallData),
    );
  }
}
