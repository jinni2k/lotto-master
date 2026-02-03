import 'package:flutter/material.dart';

import '../services/dream_service.dart';
import '../widgets/lotto_widgets.dart';

class DreamScreen extends StatefulWidget {
  const DreamScreen({super.key});

  static const String routeName = '/dream';

  @override
  State<DreamScreen> createState() => _DreamScreenState();
}

class _DreamScreenState extends State<DreamScreen> {
  final DreamService _dreamService = DreamService.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  List<DreamMatch> _matches = [];
  late Future<List<DreamEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _matches = _dreamService.search('');
    _entriesFuture = _dreamService.loadEntries();
    _searchController.addListener(_handleSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _keywordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    setState(() {
      _matches = _dreamService.search(_searchController.text);
    });
  }

  Future<void> _saveEntry() async {
    final keyword = _keywordController.text.trim();
    final notes = _notesController.text.trim();
    if (keyword.isEmpty) {
      return;
    }
    final entry = DreamEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      keyword: keyword,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await _dreamService.saveEntry(entry);
    setState(() {
      _entriesFuture = _dreamService.loadEntries();
      _keywordController.clear();
      _notesController.clear();
    });
  }

  Future<void> _deleteEntry(String id) async {
    await _dreamService.deleteEntry(id);
    setState(() {
      _entriesFuture = _dreamService.loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _LuxeBackground(),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _Header(),
              const SizedBox(height: 16),
              _SearchPanel(controller: _searchController),
              const SizedBox(height: 12),
              _MatchesList(matches: _matches),
              const SizedBox(height: 24),
              _JournalComposer(
                keywordController: _keywordController,
                notesController: _notesController,
                onSave: _saveEntry,
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<DreamEntry>>(
                future: _entriesFuture,
                builder: (context, snapshot) {
                  final entries = snapshot.data ?? [];
                  if (entries.isEmpty) {
                    return const GlassCard(
                      child: Text('아직 저장된 꿈 일기가 없습니다.'),
                    );
                  }
                  return Column(
                    children: entries
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _JournalEntryCard(
                              entry: entry,
                              onDelete: () => _deleteEntry(entry.id),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LuxeBackground extends StatelessWidget {
  const _LuxeBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.background,
            scheme.primary.withOpacity(0.16),
            scheme.secondary.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.auto_stories_rounded, color: scheme.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '꿈 해몽 검색',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '키워드를 입력하면 행운 번호를 제안해요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.65),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '예: 돼지, 물, 산, 길',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}

class _MatchesList extends StatelessWidget {
  const _MatchesList({required this.matches});

  final List<DreamMatch> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const GlassCard(child: Text('검색 결과가 없습니다.'));
    }
    return Column(
      children: matches
          .map(
            (match) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.keyword,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      match.meaning,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: match.numbers
                          .asMap()
                          .entries
                          .map(
                            (entry) => NumberBall(
                              number: entry.value,
                              isBonus: false,
                              delay: Duration(milliseconds: 60 * entry.key),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _JournalComposer extends StatelessWidget {
  const _JournalComposer({
    required this.keywordController,
    required this.notesController,
    required this.onSave,
  });

  final TextEditingController keywordController;
  final TextEditingController notesController;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '꿈 일기',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: keywordController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '꿈 키워드',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '꿈 내용이나 느낌을 기록하세요.',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text('저장'),
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({required this.entry, required this.onDelete});

  final DreamEntry entry;
  final VoidCallback onDelete;

  String _formatDate(DateTime time) {
    final year = time.year.toString().padLeft(4, '0');
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.bookmark_rounded, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.keyword,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.notes.isEmpty ? '메모 없음' : entry.notes,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(entry.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
