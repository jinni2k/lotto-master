import 'package:flutter/material.dart';

import '../models/my_ticket.dart';
import '../services/ticket_storage.dart';
import '../widgets/lotto_widgets.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  late Future<List<MyTicket>> _future;

  @override
  void initState() {
    super.initState();
    _future = TicketStorage.instance.loadTickets();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = TicketStorage.instance.loadTickets();
    });
    await _future;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _deleteTicket(MyTicket ticket) async {
    await TicketStorage.instance.deleteTicket(ticket.id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<List<MyTicket>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(onRetry: _refresh);
          }
          final tickets = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const SectionTitle(
                  title: '내 티켓',
                  subtitle: '저장한 스캔 결과를 확인하세요.',
                ),
                const SizedBox(height: 12),
                if (tickets.isEmpty)
                  const _EmptyState()
                else
                  ...tickets.map(
                    (ticket) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TicketCard(
                        ticket: ticket,
                        dateLabel: _formatDate(ticket.purchaseDate),
                        onDelete: () => _deleteTicket(ticket),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.dateLabel,
    required this.onDelete,
  });

  final MyTicket ticket;
  final String dateLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final roundLabel = ticket.round == null ? '회차 미지정' : '${ticket.round}회차';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roundLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              )
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ticket.numbers
                .map((number) => NumberBall(number: number, isBonus: false))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '저장된 티켓이 없습니다. 스캔 후 저장해보세요.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '내 티켓을 불러오지 못했어요.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => onRetry(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
