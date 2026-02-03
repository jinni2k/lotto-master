import 'package:animations/animations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/lotto_result.dart';
import '../models/my_ticket.dart';
import '../services/lotto_api.dart';
import '../services/ticket_storage.dart';
import '../widgets/lotto_widgets.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  static const String routeName = '/compare';

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final LottoApi _lottoApi = LottoApi();
  List<MyTicket> _tickets = [];
  LottoResult? _latestResult;
  MyTicket? _selectedTicket;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final results = await _lottoApi.fetchLatestResult();
      final tickets = await TicketStorage.instance.loadTickets();
      if (!mounted) {
        return;
      }
      setState(() {
        _latestResult = results;
        _tickets = tickets;
        _selectedTicket = tickets.isNotEmpty ? tickets.first : null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '당첨 번호를 불러오지 못했어요.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _LuxeBackground(),
        SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                _Header(result: _latestResult, isLoading: _loading),
                const SizedBox(height: 16),
                _TicketSelector(
                  tickets: _tickets,
                  selected: _selectedTicket,
                  onChanged: (ticket) {
                    setState(() {
                      _selectedTicket = ticket;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null)
                  GlassCard(child: Text(_errorMessage!))
                else if (_latestResult == null)
                  const GlassCard(child: Text('최신 회차 정보가 없습니다.'))
                else if (_selectedTicket == null)
                  const GlassCard(child: Text('비교할 티켓이 없습니다.'))
                else
                  _ComparisonSection(
                    ticket: _selectedTicket!,
                    result: _latestResult!,
                    allTickets: _tickets,
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
            scheme.primary.withOpacity(0.2),
            scheme.secondary.withOpacity(0.18),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.result, required this.isLoading});

  final LottoResult? result;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = result == null
        ? '당첨 번호를 불러오는 중입니다.'
        : '${result!.drawNo}회차 · ${result!.drawDate}';
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.auto_graph_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 번호 vs 당첨 번호',
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
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _TicketSelector extends StatelessWidget {
  const _TicketSelector({
    required this.tickets,
    required this.selected,
    required this.onChanged,
  });

  final List<MyTicket> tickets;
  final MyTicket? selected;
  final ValueChanged<MyTicket?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const GlassCard(
        child: Text('저장된 티켓이 없습니다. 먼저 스캔을 완료해주세요.'),
      );
    }
    return GlassCard(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MyTicket>(
          value: selected,
          isExpanded: true,
          items: tickets
              .map(
                (ticket) => DropdownMenuItem<MyTicket>(
                  value: ticket,
                  child: Text('${ticket.round ?? '-'}회차 · ${ticket.numbers.join(', ')}'),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  const _ComparisonSection({
    required this.ticket,
    required this.result,
    required this.allTickets,
  });

  final MyTicket ticket;
  final LottoResult result;
  final List<MyTicket> allTickets;

  @override
  Widget build(BuildContext context) {
    final comparison = _ComparisonResult.from(result, ticket);
    final stats = _AggregateStats.from(result, allTickets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageTransitionSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation, secondaryAnimation) {
            return FadeScaleTransition(
              animation: animation,
              child: child,
            );
          },
          child: _MatchCard(
            key: ValueKey('${ticket.id}-${result.drawNo}'),
            comparison: comparison,
            result: result,
          ),
        ),
        const SizedBox(height: 16),
        _NearMissCard(nearMisses: comparison.nearMisses),
        const SizedBox(height: 16),
        _StatsCard(stats: stats),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({super.key, required this.comparison, required this.result});

  final _ComparisonResult comparison;
  final LottoResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '적중 결과',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...result.numbers.asMap().entries.map((entry) {
                final number = entry.value;
                return NumberBall(
                  number: number,
                  isBonus: comparison.matchedNumbers.contains(number),
                  delay: Duration(milliseconds: 80 * entry.key),
                  animate: true,
                );
              }),
              NumberBall(
                number: result.bonus,
                isBonus: true,
                delay: const Duration(milliseconds: 520),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '적중 ${comparison.matchCount}개 · 보너스 ${comparison.bonusMatched ? '포함' : '미포함'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _NearMissCard extends StatelessWidget {
  const _NearMissCard({required this.nearMisses});

  final List<int> nearMisses;

  @override
  Widget build(BuildContext context) {
    if (nearMisses.isEmpty) {
      return const GlassCard(child: Text('아쉬운 번호가 없습니다.'));
    }
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '아쉬운 번호 (1개 차이)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nearMisses
                .asMap()
                .entries
                .map(
                  (entry) => NumberBall(
                    number: entry.value,
                    isBonus: false,
                    delay: Duration(milliseconds: 70 * entry.key),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.stats});

  final _AggregateStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '누적 통계',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatPill(label: '총 티켓', value: '${stats.totalTickets}장'),
              const SizedBox(width: 8),
              _StatPill(label: '최고 적중', value: '${stats.bestMatch}개'),
              const SizedBox(width: 8),
              _StatPill(label: '평균 적중', value: stats.averageMatch.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                maxY: stats.maxCount.toDouble() + 1,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.labelSmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}개');
                      },
                    ),
                  ),
                ),
                barGroups: stats.matchCounts.entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                        color: scheme.primary,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonResult {
  const _ComparisonResult({
    required this.matchCount,
    required this.bonusMatched,
    required this.matchedNumbers,
    required this.nearMisses,
  });

  final int matchCount;
  final bool bonusMatched;
  final List<int> matchedNumbers;
  final List<int> nearMisses;

  factory _ComparisonResult.from(LottoResult result, MyTicket ticket) {
    final matched = ticket.numbers.where(result.numbers.contains).toList();
    final bonusMatch = ticket.numbers.contains(result.bonus);
    final nearMisses = ticket.numbers.where((number) {
      if (result.numbers.contains(number)) {
        return false;
      }
      return result.numbers.any((win) => (win - number).abs() == 1);
    }).toList();

    return _ComparisonResult(
      matchCount: matched.length,
      bonusMatched: bonusMatch,
      matchedNumbers: matched,
      nearMisses: nearMisses,
    );
  }
}

class _AggregateStats {
  const _AggregateStats({
    required this.totalTickets,
    required this.bestMatch,
    required this.averageMatch,
    required this.matchCounts,
  });

  final int totalTickets;
  final int bestMatch;
  final double averageMatch;
  final Map<int, int> matchCounts;

  int get maxCount => matchCounts.values.fold(0, (prev, curr) => curr > prev ? curr : prev);

  factory _AggregateStats.from(LottoResult result, List<MyTicket> tickets) {
    if (tickets.isEmpty) {
      return const _AggregateStats(
        totalTickets: 0,
        bestMatch: 0,
        averageMatch: 0,
        matchCounts: {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0},
      );
    }
    var best = 0;
    var total = 0;
    final counts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    for (final ticket in tickets) {
      final matchCount = ticket.numbers.where(result.numbers.contains).length;
      counts[matchCount] = (counts[matchCount] ?? 0) + 1;
      best = matchCount > best ? matchCount : best;
      total += matchCount;
    }
    return _AggregateStats(
      totalTickets: tickets.length,
      bestMatch: best,
      averageMatch: total / tickets.length,
      matchCounts: counts,
    );
  }
}
