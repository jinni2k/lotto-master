import 'dart:math';

class FortuneResult {
  const FortuneResult({
    required this.title,
    required this.message,
    required this.luckyNumbers,
    required this.luckyColor,
    required this.luckyItem,
  });

  final String title;
  final String message;
  final List<int> luckyNumbers;
  final String luckyColor;
  final String luckyItem;
}

class FortuneService {
  const FortuneService();

  FortuneResult generateFortune({required DateTime birthday, bool byZodiac = true}) {
    final symbol = byZodiac ? _zodiac(birthday.year) : _constellation(birthday.month, birthday.day);
    final seed = birthday.year * birthday.month * birthday.day + symbol.codeUnitAt(0);
    final random = Random(seed);
    final score = 60 + random.nextInt(35);
    final message = _fortuneMessage(symbol, score);
    final numbers = _luckyNumbers(random);
    final color = _luckyColors[random.nextInt(_luckyColors.length)];
    final item = _luckyItems[random.nextInt(_luckyItems.length)];
    final title = '$symbol 오늘의 운세';
    return FortuneResult(
      title: title,
      message: message,
      luckyNumbers: numbers,
      luckyColor: color,
      luckyItem: item,
    );
  }

  String _zodiac(int year) {
    const animals = ['쥐', '소', '호랑이', '토끼', '용', '뱀', '말', '양', '원숭이', '닭', '개', '돼지'];
    return animals[(year + 8) % 12];
  }

  String _constellation(int month, int day) {
    const list = [
      '염소자리', '물병자리', '물고기자리', '양자리', '황소자리', '쌍둥이자리',
      '게자리', '사자자리', '처녀자리', '천칭자리', '전갈자리', '사수자리',
    ];
    final thresholds = [20, 19, 21, 21, 21, 22, 23, 23, 23, 23, 22, 22];
    final index = day < thresholds[month - 1] ? month - 1 : month % 12;
    return list[index];
  }

  String _fortuneMessage(String symbol, int score) {
    if (score > 90) {
      return '$symbol의 날입니다! 과감한 선택이 큰 행운으로 돌아올 거예요.';
    }
    if (score > 80) {
      return '운세가 좋은 편입니다. 마음에 두었던 일을 실행해 보세요.';
    }
    if (score > 70) {
      return '안정적인 하루, 작은 기회가 있습니다. 주변 사람을 믿어보세요.';
    }
    return '차분히 준비하며 보내세요. 느긋함이 행운을 부릅니다.';
  }

  List<int> _luckyNumbers(Random random) {
    final set = <int>{};
    while (set.length < 6) {
      set.add(random.nextInt(45) + 1);
    }
    final numbers = set.toList()..sort();
    return numbers;
  }

  static const _luckyColors = [
    '네이비',
    '올리브 그린',
    '로즈골드',
    '스카이블루',
    '버건디',
    '라벤더',
  ];

  static const _luckyItems = [
    '동전 지갑',
    '파란 양말',
    '따뜻한 커피',
    '노트 한 권',
    '열쇠고리',
    '책갈피',
  ];
}
