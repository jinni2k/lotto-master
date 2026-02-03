import 'package:flutter/material.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  static const routeName = '/simulation';

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  double _totalPrize = 1000000000; // 10억 기본값

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final categories = _buildCategories();
    final fun = _buildFunComparisons();

    return Scaffold(
      appBar: AppBar(
        title: const Text('당첨금 사용 시뮬레이션'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: [
          _PrizeSlider(
            total: _totalPrize,
            onChanged: (value) => setState(() => _totalPrize = value),
          ),
          const SizedBox(height: 14),
          _SectionHeader(title: '카테고리 분배'),
          const SizedBox(height: 10),
          ...categories.map((c) => _CategoryCard(item: c, scheme: scheme)),
          const SizedBox(height: 14),
          _SectionHeader(title: '재미있는 비교'),
          const SizedBox(height: 10),
          ...fun.map((f) => _FunCompareCard(item: f, scheme: scheme)),
        ],
      ),
    );
  }

  List<_CategoryItem> _buildCategories() {
    const referencePrices = {
      '아파트(평균 34평)': 850000000,
      '전기차/스포츠카': 120000000,
      '세계 일주(2인)': 25000000,
      '인덱스 투자': 10000000,
    };

    final ratios = {
      '아파트(평균 34평)': 0.55,
      '전기차/스포츠카': 0.15,
      '세계 일주(2인)': 0.1,
      '인덱스 투자': 0.2,
    };

    return ratios.entries.map((entry) {
      final budget = _totalPrize * entry.value;
      final refPrice = (referencePrices[entry.key] ?? budget).toDouble();
      final units = (budget / refPrice).clamp(0, 999).toDouble();
      return _CategoryItem(
        title: entry.key,
        budget: budget,
        referencePrice: refPrice,
        units: units,
      );
    }).toList();
  }

  List<_FunCompare> _buildFunComparisons() {
    const priceMap = {
      '치킨': 20000,
      '아메리카노': 5000,
      '아이폰': 1550000,
      '야구장 좌석': 35000,
      'PC방 시간': 1500,
    };
    return priceMap.entries.map((entry) {
      final count = (_totalPrize / entry.value).floor();
      return _FunCompare(name: entry.key, count: count, unitPrice: entry.value.toDouble());
    }).toList();
  }
}

class _PrizeSlider extends StatelessWidget {
  const _PrizeSlider({required this.total, required this.onChanged});

  final double total;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_rounded),
              const SizedBox(width: 8),
              Text(
                '당첨금 설정',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(_formatMoney(total), style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          Slider(
            value: total,
            min: 100000000.0,
            max: 20000000000.0,
            divisions: 100,
            label: _formatMoney(total),
            onChanged: onChanged,
          ),
          Text(
            '10억 ~ 200억 범위에서 자유롭게 가정할 수 있어요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double value) {
    final billions = value ~/ 100000000;
    return '${billions}억 원';
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.title,
    required this.budget,
    required this.referencePrice,
    required this.units,
  });

  final String title;
  final double budget;
  final double referencePrice;
  final double units;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.item, required this.scheme});

  final _CategoryItem item;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final percent = (item.budget / item.referencePrice).clamp(0, 4.0).toDouble();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: scheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(_formatMoney(item.budget), style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: percent > 1 ? 1 : percent,
            minHeight: 8,
            color: scheme.primary,
            backgroundColor: scheme.primaryContainer.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            '참고 시세: ${_formatMoney(item.referencePrice)} · 구매 가능 수량: ${item.units.toStringAsFixed(1)}개',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.65)),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double value) {
    final billions = value ~/ 100000000;
    final millions = ((value % 100000000) ~/ 1000000);
    if (billions > 0) {
      return '${billions}억 ${millions}만 원';
    }
    return '${millions}만 원';
  }
}

class _FunCompare {
  const _FunCompare({required this.name, required this.count, required this.unitPrice});

  final String name;
  final int count;
  final double unitPrice;
}

class _FunCompareCard extends StatelessWidget {
  const _FunCompareCard({required this.item, required this.scheme});

  final _FunCompare item;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final icon = Icons.celebration_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.secondary.withOpacity(0.18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.name} 몇 개?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.count.toString().replaceAllMapped(RegExp(r"(?=(\d{3})+(?!\d))"), (m) => ',')} 개 (개당 ${item.unitPrice.toStringAsFixed(0)}원)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
