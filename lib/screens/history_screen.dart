import 'package:flutter/material.dart';

import '../models/lotto_result.dart';
import '../services/lotto_api.dart';
import '../widgets/lotto_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final LottoApi _api = LottoApi();
  late Future<List<LottoResult>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.fetchRecentResults();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _api.fetchRecentResults();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<LottoResult>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(onRetry: _refresh);
          }

          final results = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const SectionTitle(
                  title: '최근 10회차 당첨 번호',
                  subtitle: '동행복권 API 기반 데이터',
                ),
                const SizedBox(height: 12),
                if (results.isEmpty)
                  const _EmptyState()
                else
                  ...results.map(
                    (result) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RoundCard(result: result),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard({required this.result});

  final LottoResult result;

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
                '${result.drawNo}회차',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                result.drawDate,
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
                (number) => NumberBall(number: number, isBonus: false),
              ),
              NumberBall(number: result.bonus, isBonus: true),
            ],
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '데이터를 불러오지 못했어요.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => onRetry(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '표시할 회차 정보가 없습니다.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
