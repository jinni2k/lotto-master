import 'package:flutter/material.dart';

import '../models/lotto_result.dart';
import '../services/lotto_api.dart';
import '../widgets/lotto_widgets.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
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
          final items = _buildFrequencyItems(results);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const SectionTitle(
                  title: '번호별 출현 빈도',
                  subtitle: '최근 10회차 기준',
                ),
                const SizedBox(height: 12),
                Container(
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
                      crossAxisCount: 5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.3,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _FrequencyChip(item: item);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_FrequencyItem> _buildFrequencyItems(List<LottoResult> results) {
    final counts = List<int>.filled(46, 0);
    for (final result in results) {
      for (final number in result.numbers) {
        counts[number] += 1;
      }
    }

    return List<_FrequencyItem>.generate(
      45,
      (index) => _FrequencyItem(number: index + 1, count: counts[index + 1]),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              '분석 데이터를 불러오지 못했어요.',
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
