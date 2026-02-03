import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/my_ticket.dart';

class TicketStorage {
  TicketStorage._();

  static final TicketStorage instance = TicketStorage._();

  static const String _storageKey = 'my_tickets';

  Future<List<MyTicket>> loadTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => MyTicket.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> saveTicket(MyTicket ticket) async {
    final tickets = await loadTickets();
    final updated = [ticket, ...tickets.where((t) => t.id != ticket.id)];
    await _writeTickets(updated);
  }

  Future<void> deleteTicket(String id) async {
    final tickets = await loadTickets();
    final updated = tickets.where((ticket) => ticket.id != id).toList();
    await _writeTickets(updated);
  }

  Future<void> _writeTickets(List<MyTicket> tickets) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tickets.map((ticket) => ticket.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
