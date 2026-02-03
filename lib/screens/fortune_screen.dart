import 'package:flutter/material.dart';

import '../services/fortune_service.dart';

class FortuneScreen extends StatefulWidget {
  const FortuneScreen({super.key});

  static const routeName = '/fortune';

  @override
  State<FortuneScreen> createState() => _FortuneScreenState();
}

class _FortuneScreenState extends State<FortuneScreen> {
  final FortuneService _service = const FortuneService();
  DateTime _birthday = DateTime.now().subtract(const Duration(days: 25 * 365));
  bool _useZodiac = true;

  void _pickBirthday() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthday = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fortune = _service.generateFortune(birthday: _birthday, byZodiac: _useZodiac);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('띠/별자리 운세'),
        actions: [
          IconButton(
            onPressed: _pickBirthday,
            icon: const Icon(Icons.cake_rounded),
            tooltip: '생일 변경',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _HeaderCard(
            birthday: _birthday,
            useZodiac: _useZodiac,
            onToggle: (value) => setState(() => _useZodiac = value),
            onPick: _pickBirthday,
          ),
          const SizedBox(height: 14),
          _FortuneCard(result: fortune, scheme: scheme),
          const SizedBox(height: 14),
          _LuckyNumberCard(numbers: fortune.luckyNumbers, scheme: scheme),
          const SizedBox(height: 14),
          _LuckyTipCard(color: fortune.luckyColor, item: fortune.luckyItem, scheme: scheme),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.birthday,
    required this.useZodiac,
    required this.onToggle,
    required this.onPick,
  });

  final DateTime birthday;
  final bool useZodiac;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = '${birthday.year}-${birthday.month.toString().padLeft(2, '0')}-${birthday.day.toString().padLeft(2, '0')}';
    return Container(
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
              const Icon(Icons.auto_awesome_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '생일 번호 & 운세',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: onPick, child: const Text('생일 변경')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(dateLabel, style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(useZodiac ? '띠 기준' : '별자리 기준'),
              Switch(value: useZodiac, onChanged: onToggle),
            ],
          ),
        ],
      ),
    );
  }
}

class _FortuneCard extends StatelessWidget {
  const _FortuneCard({required this.result, required this.scheme});

  final FortuneResult result;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary.withOpacity(0.85), scheme.secondary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            result.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onPrimary.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}

class _LuckyNumberCard extends StatelessWidget {
  const _LuckyNumberCard({required this.numbers, required this.scheme});

  final List<int> numbers;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(Icons.numbers_rounded, color: scheme.primary),
              const SizedBox(width: 8),
              Text('행운 번호', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: numbers
                .map((n) => Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        n.toString().padLeft(2, '0'),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _LuckyTipCard extends StatelessWidget {
  const _LuckyTipCard({required this.color, required this.item, required this.scheme});

  final String color;
  final String item;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_rounded, color: scheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('오늘의 포인트', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('라키 컬러: $color · 행운 아이템: $item',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
