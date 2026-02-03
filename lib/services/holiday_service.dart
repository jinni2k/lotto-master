import 'dart:convert';

import 'package:http/http.dart' as http;

class Holiday {
  const Holiday({required this.date, required this.name, this.isHoliday = true});

  final DateTime date;
  final String name;
  final bool isHoliday;
}

class HolidayService {
  HolidayService({http.Client? client, this.serviceKey})
      : _client = client ?? http.Client();

  final http.Client _client;
  final String? serviceKey;

  Future<List<Holiday>> fetchHolidays({required int year, int? month}) async {
    if (serviceKey == null || serviceKey!.isEmpty) {
      return _fallback(year, month: month);
    }

    final monthParam = month == null ? '' : '&solMonth=${month.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
      'https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getHoliDeInfo?serviceKey=$serviceKey&numOfRows=50&pageNo=1&solYear=$year$monthParam&_type=json',
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return _fallback(year, month: month);
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (((body['response'] as Map<String, dynamic>?)?['body']
                  as Map<String, dynamic>?)?['items']
              as Map<String, dynamic>?)?['item']
          as List<dynamic>?;
      if (items == null || items.isEmpty) {
        return _fallback(year, month: month);
      }

      return items.map((raw) {
        final map = raw as Map<String, dynamic>;
        final dateStr = map['locdate']?.toString() ?? '';
        final name = map['dateName']?.toString() ?? '공휴일';
        final isHoliday = (map['isHoliday']?.toString() ?? 'Y') == 'Y';
        final parsed = _parseDate(dateStr);
        return Holiday(date: parsed, name: name, isHoliday: isHoliday);
      }).where((h) => month == null || h.date.month == month).toList();
    } catch (_) {
      return _fallback(year, month: month);
    }
  }

  DateTime _parseDate(String yyyymmdd) {
    if (yyyymmdd.length != 8) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    final year = int.tryParse(yyyymmdd.substring(0, 4)) ?? DateTime.now().year;
    final month = int.tryParse(yyyymmdd.substring(4, 6)) ?? 1;
    final day = int.tryParse(yyyymmdd.substring(6, 8)) ?? 1;
    return DateTime(year, month, day);
  }

  List<Holiday> _fallback(int year, {int? month}) {
    final samples = <Holiday>[
      Holiday(date: DateTime(year, 1, 1), name: '신정'),
      Holiday(date: DateTime(year, 3, 1), name: '삼일절'),
      Holiday(date: DateTime(year, 5, 5), name: '어린이날'),
      Holiday(date: DateTime(year, 8, 15), name: '광복절'),
      Holiday(date: DateTime(year, 10, 3), name: '개천절'),
      Holiday(date: DateTime(year, 10, 9), name: '한글날'),
      Holiday(date: DateTime(year, 12, 25), name: '크리스마스'),
    ];
    if (month == null) {
      return samples;
    }
    return samples.where((holiday) => holiday.date.month == month).toList();
  }
}
