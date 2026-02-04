import 'dart:async';

import '../models/lotto_result.dart';
import '../models/my_ticket.dart';
import 'ticket_storage.dart';

class DrawResultNotification {
  const DrawResultNotification({
    required this.title,
    required this.message,
    required this.drawNo,
  });

  final String title;
  final String message;
  final int drawNo;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _controller = StreamController<DrawResultNotification>.broadcast();

  Stream<DrawResultNotification> get notifications => _controller.stream;

  Future<void> initialize() async {
    // 로컬 알림만 사용 (Firebase 제거)
  }

  DateTime nextDrawTime({DateTime? now}) {
    final current = now ?? DateTime.now();
    final weekdayOffset = (DateTime.saturday - current.weekday) % 7;
    final nextSaturday = current.add(Duration(days: weekdayOffset));
    final scheduled = DateTime(
      nextSaturday.year,
      nextSaturday.month,
      nextSaturday.day,
      20,
      45,
    );
    if (scheduled.isAfter(current)) {
      return scheduled;
    }
    final following = nextSaturday.add(const Duration(days: 7));
    return DateTime(following.year, following.month, following.day, 20, 45);
  }

  Future<DrawResultNotification?> compareTicketsWithResult(LottoResult result) async {
    final tickets = await TicketStorage.instance.loadTickets();
    if (tickets.isEmpty) {
      return null;
    }
    final stats = _buildComparisonStats(result, tickets);
    return DrawResultNotification(
      title: '${result.drawNo}회차 결과 알림',
      message: stats,
      drawNo: result.drawNo,
    );
  }

  String _buildComparisonStats(LottoResult result, List<MyTicket> tickets) {
    var bestMatch = 0;
    var totalNearMiss = 0;
    var winners = 0;

    for (final ticket in tickets) {
      final matchCount = _matchCount(result.numbers, ticket.numbers);
      bestMatch = matchCount > bestMatch ? matchCount : bestMatch;
      totalNearMiss += _nearMissCount(result.numbers, ticket.numbers);
      if (matchCount >= 3) {
        winners += 1;
      }
    }

    return '총 ${tickets.length}장 중 최고 ${bestMatch}개 적중, 아쉬운 번호 ${totalNearMiss}개. '
        '3개 이상 적중 ${winners}장입니다.';
  }

  int _matchCount(List<int> winning, List<int> mine) {
    final winSet = winning.toSet();
    return mine.where(winSet.contains).length;
  }

  int _nearMissCount(List<int> winning, List<int> mine) {
    var count = 0;
    for (final number in mine) {
      final isMatch = winning.contains(number);
      if (isMatch) {
        continue;
      }
      if (winning.any((win) => (win - number).abs() == 1)) {
        count += 1;
      }
    }
    return count;
  }
}
