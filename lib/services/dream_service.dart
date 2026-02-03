import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DreamMatch {
  const DreamMatch({
    required this.keyword,
    required this.meaning,
    required this.numbers,
  });

  final String keyword;
  final String meaning;
  final List<int> numbers;
}

class DreamEntry {
  const DreamEntry({
    required this.id,
    required this.keyword,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String keyword;
  final String notes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyword': keyword,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DreamEntry.fromJson(Map<String, dynamic> json) {
    return DreamEntry(
      id: json['id'] as String,
      keyword: json['keyword'] as String,
      notes: json['notes'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class DreamService {
  DreamService._();

  static final DreamService instance = DreamService._();

  static const String _storageKey = 'dream_journal_entries';

  final Map<String, DreamMatch> _dreamMap = {
    '돼지': DreamMatch(
      keyword: '돼지',
      meaning: '재물 운과 기회가 커지는 길몽으로 알려져 있어요.',
      numbers: [3, 12, 21, 28, 37, 44],
    ),
    '용': DreamMatch(
      keyword: '용',
      meaning: '큰 성취나 승진을 상징하는 대표적인 행운 꿈이에요.',
      numbers: [1, 7, 16, 29, 35, 42],
    ),
    '물': DreamMatch(
      keyword: '물',
      meaning: '맑은 물은 정화와 상승, 흐린 물은 조정이 필요함을 뜻해요.',
      numbers: [5, 14, 20, 27, 33, 41],
    ),
    '산': DreamMatch(
      keyword: '산',
      meaning: '버티고 올라가는 힘이 생기는 시기라는 신호예요.',
      numbers: [4, 11, 18, 26, 32, 45],
    ),
    '비': DreamMatch(
      keyword: '비',
      meaning: '걱정이 씻기고 새 기회가 도착하는 흐름을 의미해요.',
      numbers: [2, 9, 15, 24, 34, 40],
    ),
    '돈': DreamMatch(
      keyword: '돈',
      meaning: '실속 있는 이득과 계약에 유리한 운이 들어오는 꿈이에요.',
      numbers: [6, 13, 19, 30, 36, 43],
    ),
    '하늘': DreamMatch(
      keyword: '하늘',
      meaning: '시야가 넓어지고 좋은 소식이 가까워지는 신호예요.',
      numbers: [8, 17, 23, 31, 38, 39],
    ),
    '나무': DreamMatch(
      keyword: '나무',
      meaning: '오래 가는 성장이 시작되는 시기라는 뜻이에요.',
      numbers: [10, 22, 25, 34, 40, 41],
    ),
    '불': DreamMatch(
      keyword: '불',
      meaning: '강한 열정과 성과가 폭발할 수 있는 시기를 말해요.',
      numbers: [3, 8, 21, 27, 36, 44],
    ),
    '집': DreamMatch(
      keyword: '집',
      meaning: '안정과 기반이 단단해지는 기회를 뜻해요.',
      numbers: [12, 17, 24, 28, 39, 42],
    ),
    '길': DreamMatch(
      keyword: '길',
      meaning: '새로운 선택지가 열리고 이동 운이 강해지는 꿈이에요.',
      numbers: [7, 15, 22, 29, 33, 40],
    ),
    '꽃': DreamMatch(
      keyword: '꽃',
      meaning: '관계 운이 좋아지고 축하받을 일이 생길 수 있어요.',
      numbers: [9, 16, 25, 32, 37, 45],
    ),
  };

  List<DreamMatch> search(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return _dreamMap.values.toList(growable: false);
    }
    return _dreamMap.values
        .where((match) => match.keyword.contains(normalized))
        .toList(growable: false);
  }

  Future<List<DreamEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => DreamEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> saveEntry(DreamEntry entry) async {
    final entries = await loadEntries();
    final updated = [entry, ...entries.where((e) => e.id != entry.id)];
    await _writeEntries(updated);
  }

  Future<void> deleteEntry(String id) async {
    final entries = await loadEntries();
    final updated = entries.where((entry) => entry.id != id).toList();
    await _writeEntries(updated);
  }

  Future<void> _writeEntries(List<DreamEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map((entry) => entry.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
