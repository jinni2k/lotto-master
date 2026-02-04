import 'dart:convert';
import 'package:http/http.dart' as http;

class LottoResult {
  final int round;
  final DateTime drawDate;
  final List<int> numbers;
  final int bonusNumber;
  final int firstPrizeAmount;
  final int firstWinnerCount;

  LottoResult({
    required this.round,
    required this.drawDate,
    required this.numbers,
    required this.bonusNumber,
    required this.firstPrizeAmount,
    required this.firstWinnerCount,
  });

  factory LottoResult.fromJson(Map<String, dynamic> json) {
    return LottoResult(
      round: json['drwNo'] ?? 0,
      drawDate: DateTime.tryParse(json['drwNoDate'] ?? '') ?? DateTime.now(),
      numbers: [
        json['drwtNo1'] ?? 0,
        json['drwtNo2'] ?? 0,
        json['drwtNo3'] ?? 0,
        json['drwtNo4'] ?? 0,
        json['drwtNo5'] ?? 0,
        json['drwtNo6'] ?? 0,
      ],
      bonusNumber: json['bnusNo'] ?? 0,
      firstPrizeAmount: json['firstWinamnt'] ?? 0,
      firstWinnerCount: json['firstPrzwnerCo'] ?? 0,
    );
  }
}

class LottoApiService {
  static const String _baseUrl = 'https://www.dhlottery.co.kr/common.do';

  /// 특정 회차 당첨 번호 조회
  static Future<LottoResult?> getResult(int round) async {
    try {
      final url = Uri.parse('$_baseUrl?method=getLottoNumber&drwNo=$round');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['returnValue'] == 'success') {
          return LottoResult.fromJson(json);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 최신 회차 번호 추정 (매주 토요일 추첨)
  static int estimateLatestRound() {
    // 1회차: 2002년 12월 7일
    final firstDraw = DateTime(2002, 12, 7);
    final now = DateTime.now();
    final diff = now.difference(firstDraw).inDays;
    return (diff / 7).floor() + 1;
  }

  /// 최신 당첨 결과 조회
  static Future<LottoResult?> getLatestResult() async {
    int round = estimateLatestRound();
    
    // 최신 회차부터 확인 (없으면 이전 회차)
    for (int i = 0; i < 3; i++) {
      final result = await getResult(round - i);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// 최근 N개 회차 결과 조회
  static Future<List<LottoResult>> getRecentResults(int count) async {
    final results = <LottoResult>[];
    final latest = await getLatestResult();
    
    if (latest == null) return results;
    
    results.add(latest);
    
    for (int i = 1; i < count; i++) {
      final result = await getResult(latest.round - i);
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }
}
