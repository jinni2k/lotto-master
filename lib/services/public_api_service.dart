import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class DailyWeather {
  const DailyWeather({
    required this.summary,
    required this.temperature,
    required this.max,
    required this.min,
    required this.windSpeed,
  });

  final String summary;
  final double temperature;
  final double max;
  final double min;
  final double windSpeed;
}

class DailyFortune {
  const DailyFortune({
    required this.message,
    required this.mood,
    required this.luckScore,
  });

  final String message;
  final String mood;
  final int luckScore;
}

class DailyNewsItem {
  const DailyNewsItem({
    required this.title,
    required this.source,
    required this.link,
    required this.publishedAt,
  });

  final String title;
  final String source;
  final String link;
  final DateTime publishedAt;
}

class PublicApiService {
  PublicApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<DailyWeather> fetchWeather(
      {double latitude = 37.5665, double longitude = 126.9780}) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current_weather=true&daily=temperature_2m_max,temperature_2m_min&timezone=auto',
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Weather API error ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = (data['current_weather'] as Map<String, dynamic>?) ?? {};
      final daily = (data['daily'] as Map<String, dynamic>?) ?? {};
      final maxTemps = (daily['temperature_2m_max'] as List<dynamic>?) ?? [];
      final minTemps = (daily['temperature_2m_min'] as List<dynamic>?) ?? [];
      final code = current['weathercode'] as int? ?? 0;
      return DailyWeather(
        summary: _weatherDescription(code),
        temperature: (current['temperature'] as num?)?.toDouble() ?? 0,
        max: (maxTemps.isNotEmpty
                ? maxTemps.first as num
                : current['temperature'] as num? ?? 0)
            .toDouble(),
        min: (minTemps.isNotEmpty
                ? minTemps.first as num
                : current['temperature'] as num? ?? 0)
            .toDouble(),
        windSpeed: (current['windspeed'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return const DailyWeather(
        summary: '맑음',
        temperature: 22,
        max: 25,
        min: 18,
        windSpeed: 2,
      );
    }
  }

  Future<DailyFortune> fetchFortune() async {
    const uri = 'https://api.adviceslip.com/advice';
    try {
      final response = await _client.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final advice =
            (data['slip'] as Map<String, dynamic>?)?['advice'] as String?;
        final score = 60 + Random().nextInt(35);
        return DailyFortune(
          message: advice ?? '긍정적인 마음이 행운을 부릅니다.',
          mood: '행운 지수',
          luckScore: score,
        );
      }
    } catch (_) {}

    return DailyFortune(
      message: '느긋하게 하루를 보내세요. 작은 선택이 행운이 됩니다.',
      mood: '잔잔한 운세',
      luckScore: 68 + Random().nextInt(18),
    );
  }

  Future<List<DailyNewsItem>> fetchNews() async {
    final uri = Uri.parse(
      'https://hn.algolia.com/api/v1/search_by_date?query=lotto%20OR%20lottery&tags=story&hitsPerPage=6',
    );

    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        throw Exception('News API error');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final hits = (data['hits'] as List<dynamic>? ?? []);
      return hits.take(5).map((raw) {
        final map = raw as Map<String, dynamic>;
        final title = (map['title'] as String? ?? '').trim();
        final source = (map['author'] as String? ?? '뉴스').trim();
        final publishedAt =
            DateTime.tryParse(map['created_at'] as String? ?? '') ??
                DateTime.now();
        final url = (map['url'] as String? ?? '').isEmpty
            ? 'https://news.ycombinator.com/'
            : map['url'] as String;
        return DailyNewsItem(
          title: title.isEmpty ? '로또 관련 소식' : title,
          source: source.isEmpty ? '뉴스' : source,
          link: url,
          publishedAt: publishedAt,
        );
      }).toList(growable: false);
    } catch (_) {
      return [
        DailyNewsItem(
          title: '행운 숫자를 나눠보세요. 커뮤니티에서 인기 번호 확인!',
          source: '커뮤니티',
          link: '',
          publishedAt: DateTime.now(),
        ),
      ];
    }
  }

  List<int> generateLuckyNumbers({int count = 6, int maxNumber = 45}) {
    final now = DateTime.now();
    final seed = now.day * now.month + now.weekday;
    final random = Random(seed);
    final picked = <int>{};
    while (picked.length < count) {
      picked.add(random.nextInt(maxNumber) + 1);
    }
    final numbers = picked.toList()..sort();
    return numbers;
  }

  String _weatherDescription(int code) {
    if (code == 0) return '쾌청';
    if (code == 1 || code == 2) return '대체로 맑음';
    if (code == 3) return '구름 많음';
    if (code == 45 || code == 48) return '안개';
    if (code == 51 || code == 53 || code == 55) return '이슬비';
    if (code == 61 || code == 63 || code == 65) return '비';
    if (code == 71 || code == 73 || code == 75) return '눈';
    if (code == 80 || code == 81 || code == 82) return '소나기';
    if (code == 95) return '폭풍우';
    return '날씨 데이터';
  }
}
