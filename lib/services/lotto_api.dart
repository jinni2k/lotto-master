import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lotto_result.dart';

class LottoApi {
  LottoApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<LottoResult> fetchResult(int drawNo) async {
    final uri = Uri.parse(
      'https://www.dhlottery.co.kr/common.do?method=getLottoNumber&drwNo=$drawNo',
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('API 요청 실패: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['returnValue'] != 'success') {
      throw Exception('API 응답 오류');
    }

    return LottoResult.fromJson(data);
  }

  Future<LottoResult> fetchLatestResult() => fetchResult(0);

  Future<List<LottoResult>> fetchRecentResults({int count = 10}) async {
    final latest = await fetchLatestResult();
    final results = <LottoResult>[latest];
    final latestNo = latest.drawNo;

    for (var i = 1; i < count; i++) {
      final drawNo = latestNo - i;
      if (drawNo <= 0) {
        break;
      }
      results.add(await fetchResult(drawNo));
    }

    return results;
  }
}
