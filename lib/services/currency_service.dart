import 'dart:convert';

import 'package:http/http.dart' as http;

class CurrencyRate {
  const CurrencyRate({required this.code, required this.perKrw});

  final String code;
  final double perKrw;
}

class CurrencyRates {
  const CurrencyRates({required this.baseDate, required this.rates});

  final DateTime baseDate;
  final Map<String, CurrencyRate> rates;
}

class CurrencyService {
  CurrencyService({http.Client? client, this.apiKey})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String? apiKey;

  Future<CurrencyRates> fetchLatest({List<String> codes = const ['USD', 'JPY', 'EUR']}) async {
    if (apiKey != null && apiKey!.isNotEmpty) {
      final result = await _fetchFromBok(codes);
      if (result != null) {
        return result;
      }
    }
    return _fetchFallback(codes);
  }

  Future<CurrencyRates?> _fetchFromBok(List<String> codes) async {
    final today = DateTime.now();
    final yyyymmdd = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';
    final Map<String, CurrencyRate> rateMap = {};

    for (final code in codes) {
      final uri = Uri.parse(
        'https://ecos.bok.or.kr/api/StatisticSearch/$apiKey/json/kr/1/1/036Y001/DD/$yyyymmdd/$yyyymmdd/$code',
      );
      try {
        final response = await _client.get(uri);
        if (response.statusCode != 200) {
          return null;
        }
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rows = (data['StatisticSearch'] as Map<String, dynamic>?)?['row']
            as List<dynamic>?;
        if (rows == null || rows.isEmpty) {
          return null;
        }
        final valueStr = (rows.first as Map<String, dynamic>)['DATA_VALUE']?.toString();
        final value = double.tryParse(valueStr ?? '');
        if (value == null || value == 0) {
          return null;
        }
        // BOK returns per foreign currency, convert to per 1 KRW.
        rateMap[code] = CurrencyRate(code: code, perKrw: 1 / value);
      } catch (_) {
        return null;
      }
    }
    return CurrencyRates(baseDate: today, rates: rateMap);
  }

  Future<CurrencyRates> _fetchFallback(List<String> codes) async {
    final uri = Uri.parse(
      'https://api.exchangerate.host/latest?base=KRW&symbols=${codes.join(',')}',
    );
    try {
      final response = await _client.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final ratesRaw = (data['rates'] as Map<String, dynamic>?) ?? {};
        final date = DateTime.tryParse(data['date']?.toString() ?? '') ?? DateTime.now();
        final mapped = <String, CurrencyRate>{};
        for (final code in codes) {
          final value = (ratesRaw[code] as num?)?.toDouble();
          if (value != null && value > 0) {
            mapped[code] = CurrencyRate(code: code, perKrw: value);
          }
        }
        if (mapped.isNotEmpty) {
          return CurrencyRates(baseDate: date, rates: mapped);
        }
      }
    } catch (_) {}

    final fallback = <String, CurrencyRate>{
      'USD': const CurrencyRate(code: 'USD', perKrw: 0.00074),
      'JPY': const CurrencyRate(code: 'JPY', perKrw: 0.11),
      'EUR': const CurrencyRate(code: 'EUR', perKrw: 0.00067),
    };
    return CurrencyRates(baseDate: DateTime.now(), rates: fallback);
  }
}
