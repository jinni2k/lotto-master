import 'package:flutter/material.dart';

import '../services/currency_service.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  static const routeName = '/currency';

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final CurrencyService _service = CurrencyService();
  final TextEditingController _wonController = TextEditingController(text: '1000000000');
  Future<CurrencyRates>? _ratesFuture;

  @override
  void initState() {
    super.initState();
    _ratesFuture = _service.fetchLatest();
  }

  @override
  void dispose() {
    _wonController.dispose();
    super.dispose();
  }

  double _inputWon() {
    final value = double.tryParse(_wonController.text.replaceAll(',', ''));
    return value ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('환율 · 당첨금 환산'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() => _ratesFuture = _service.fetchLatest()),
          ),
        ],
      ),
      body: FutureBuilder<CurrencyRates>(
        future: _ratesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return _ErrorState(onRetry: () => setState(() => _ratesFuture = _service.fetchLatest()));
          }
          final rates = snapshot.data!;
          final won = _inputWon();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              _WonInputField(controller: _wonController, onChanged: (_) => setState(() {})),
              const SizedBox(height: 16),
              _RateSummary(date: rates.baseDate, scheme: scheme),
              const SizedBox(height: 10),
              ...rates.rates.values.map((rate) => _ConversionCard(
                    rate: rate,
                    wonAmount: won,
                    scheme: scheme,
                  )),
              const SizedBox(height: 16),
              _HelperText(),
            ],
          );
        },
      ),
    );
  }
}

class _WonInputField extends StatelessWidget {
  const _WonInputField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: '당첨금 (원)',
        hintText: '예: 1,000,000,000',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        suffixIcon: const Icon(Icons.calculate_rounded),
      ),
      onChanged: onChanged,
    );
  }
}

class _RateSummary extends StatelessWidget {
  const _RateSummary({required this.date, required this.scheme});

  final DateTime date;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final formatted = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '기준일 $formatted · 한국은행/백업 환율',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversionCard extends StatelessWidget {
  const _ConversionCard({required this.rate, required this.wonAmount, required this.scheme});

  final CurrencyRate rate;
  final double wonAmount;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final converted = wonAmount * rate.perKrw;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Text(rate.code, style: Theme.of(context).textTheme.labelLarge),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${rate.code} 환산 금액', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_format(converted, rate.code), style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text('1원 = ${rate.perKrw.toStringAsFixed(6)} ${rate.code}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _format(double value, String code) {
    return '${value.toStringAsFixed(2)} $code';
  }
}

class _HelperText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      '환율은 참고용이며, 은행/환전 시 수수료가 발생할 수 있습니다.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('환율 정보를 불러오지 못했습니다.'),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
