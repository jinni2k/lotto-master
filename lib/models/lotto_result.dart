class LottoResult {
  const LottoResult({
    required this.drawNo,
    required this.drawDate,
    required this.numbers,
    required this.bonus,
  });

  final int drawNo;
  final String drawDate;
  final List<int> numbers;
  final int bonus;

  factory LottoResult.fromJson(Map<String, dynamic> json) {
    final numbers = List<int>.generate(
      6,
      (index) => _parseInt(json['drwtNo${index + 1}']),
    );

    return LottoResult(
      drawNo: _parseInt(json['drwNo']),
      drawDate: json['drwNoDate'] as String? ?? '-',
      numbers: numbers,
      bonus: _parseInt(json['bnusNo']),
    );
  }

  static int _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
