import 'dart:convert';

import 'package:http/http.dart' as http;

class LuckyStore {
  const LuckyStore({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.winCount,
    required this.region,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int winCount;
  final String region;
}

class StoreService {
  StoreService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<LuckyStore>> fetchLuckyStores({String city = '서울'}) async {
    final uri = Uri.parse('https://raw.githubusercontent.com/lotto-master-data/stores/main/$city.json');
    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        return _fallback(city);
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      return data.map((raw) {
        final map = raw as Map<String, dynamic>;
        return LuckyStore(
          name: map['name']?.toString() ?? '복권명당',
          address: map['address']?.toString() ?? '$city 시내',
          latitude: (map['lat'] as num?)?.toDouble() ?? 37.5665,
          longitude: (map['lng'] as num?)?.toDouble() ?? 126.9780,
          winCount: (map['wins'] as num?)?.toInt() ?? 1,
          region: map['region']?.toString() ?? city,
        );
      }).toList(growable: false);
    } catch (_) {
      return _fallback(city);
    }
  }

  List<LuckyStore> _fallback(String city) {
    return const [
      LuckyStore(
        name: '광화문 복권방',
        address: '서울 종로구 세종대로 172',
        latitude: 37.5759,
        longitude: 126.9769,
        winCount: 9,
        region: '서울',
      ),
      LuckyStore(
        name: '강남 로또센터',
        address: '서울 강남구 테헤란로 152',
        latitude: 37.5010,
        longitude: 127.0396,
        winCount: 7,
        region: '서울',
      ),
      LuckyStore(
        name: '수원 행운명당',
        address: '경기 수원시 팔달구 정조로 809',
        latitude: 37.2794,
        longitude: 127.0177,
        winCount: 6,
        region: '경기',
      ),
    ];
  }
}
