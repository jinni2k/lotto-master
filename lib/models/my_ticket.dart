class MyTicket {
  const MyTicket({
    required this.id,
    required this.numbers,
    required this.purchaseDate,
    required this.round,
  });

  final String id;
  final List<int> numbers;
  final DateTime purchaseDate;
  final int? round;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numbers': numbers,
      'purchaseDate': purchaseDate.toIso8601String(),
      'round': round,
    };
  }

  factory MyTicket.fromJson(Map<String, dynamic> json) {
    return MyTicket(
      id: json['id'] as String,
      numbers: (json['numbers'] as List<dynamic>)
          .map((value) => value as int)
          .toList(growable: false),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      round: json['round'] as int?,
    );
  }
}
