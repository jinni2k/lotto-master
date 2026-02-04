import 'package:flutter/material.dart';
import '../services/lotto_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  LottoResult? _latestResult;
  List<LottoResult> _recentResults = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await LottoApiService.getRecentResults(5);
      setState(() {
        if (results.isNotEmpty) {
          _latestResult = results.first;
          _recentResults = results;
        } else {
          _error = '데이터를 불러올 수 없습니다';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '네트워크 오류가 발생했습니다';
        _isLoading = false;
      });
    }
  }

  Color _getBallColor(int number) {
    if (number <= 10) return const Color(0xFFFFC107);
    if (number <= 20) return const Color(0xFF2196F3);
    if (number <= 30) return const Color(0xFFE91E63);
    if (number <= 40) return const Color(0xFF9E9E9E);
    return const Color(0xFF4CAF50);
  }

  String _formatMoney(int amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(0)}억원';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만원';
    }
    return '$amount원';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('당첨 결과'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResults,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadResults,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadResults,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 최신 회차 카드
                      if (_latestResult != null) ...[
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '제 ${_latestResult!.round}회',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_latestResult!.drawDate.year}.${_latestResult!.drawDate.month}.${_latestResult!.drawDate.day} 추첨',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 20),
                                // 당첨 번호
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    ..._latestResult!.numbers.map((n) => _LottoBall(
                                      number: n,
                                      color: _getBallColor(n),
                                    )),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      child: Text('+', style: TextStyle(fontSize: 24)),
                                    ),
                                    _LottoBall(
                                      number: _latestResult!.bonusNumber,
                                      color: _getBallColor(_latestResult!.bonusNumber),
                                      isBonus: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(),
                                const SizedBox(height: 12),
                                // 1등 정보
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          '1등 당첨금',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatMoney(_latestResult!.firstPrizeAmount),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Text(
                                          '1등 당첨자',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_latestResult!.firstWinnerCount}명',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 최근 회차 목록
                      Text(
                        '최근 당첨 번호',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._recentResults.skip(1).map((result) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              '${result.round}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Row(
                            children: result.numbers.map((n) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: _SmallBall(number: n, color: _getBallColor(n)),
                            )).toList(),
                          ),
                          subtitle: Text(
                            '${result.drawDate.year}.${result.drawDate.month}.${result.drawDate.day}',
                          ),
                          trailing: Text(
                            '+${result.bonusNumber}',
                            style: TextStyle(
                              color: _getBallColor(result.bonusNumber),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
    );
  }
}

class _LottoBall extends StatelessWidget {
  const _LottoBall({
    required this.number,
    required this.color,
    this.isBonus = false,
  });

  final int number;
  final Color color;
  final bool isBonus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isBonus ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _SmallBall extends StatelessWidget {
  const _SmallBall({required this.number, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
