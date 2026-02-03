import 'package:flutter/material.dart';

import '../services/store_service.dart';

class LuckyStoreScreen extends StatefulWidget {
  const LuckyStoreScreen({super.key});

  static const routeName = '/lucky-stores';

  @override
  State<LuckyStoreScreen> createState() => _LuckyStoreScreenState();
}

class _LuckyStoreScreenState extends State<LuckyStoreScreen> {
  final StoreService _service = StoreService();
  late Future<List<LuckyStore>> _future;
  String _city = '서울';

  @override
  void initState() {
    super.initState();
    _future = _service.fetchLuckyStores(city: _city);
  }

  void _changeCity(String city) {
    setState(() {
      _city = city;
      _future = _service.fetchLuckyStores(city: _city);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('명당 판매점 지도'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeCity,
            itemBuilder: (context) => const [
              PopupMenuItem(value: '서울', child: Text('서울')),
              PopupMenuItem(value: '경기', child: Text('경기')),
              PopupMenuItem(value: '부산', child: Text('부산')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<LuckyStore>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stores = snapshot.data ?? [];
          if (stores.isEmpty) {
            return _EmptyState(onRetry: () => _changeCity(_city));
          }
          final top = stores.take(1).first;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              _MapMock(store: top, scheme: scheme),
              const SizedBox(height: 14),
              ...stores.map((store) => _StoreCard(store: store, scheme: scheme)),
            ],
          );
        },
      ),
    );
  }
}

class _MapMock extends StatelessWidget {
  const _MapMock({required this.store, required this.scheme});

  final LuckyStore store;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [scheme.primary.withOpacity(0.85), scheme.secondary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            bottom: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${store.region} 베스트 명당',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  store.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  store.address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onPrimary.withOpacity(0.9)),
                ),
              ],
            ),
          ),
          Positioned(
            top: 26,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.onPrimary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('위도 ${store.latitude.toStringAsFixed(3)}, 경도 ${store.longitude.toStringAsFixed(3)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onPrimary)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store, required this.scheme});

  final LuckyStore store;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store_mall_directory_rounded, color: scheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(store.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Chip(label: Text('당첨 ${store.winCount}회')),
            ],
          ),
          const SizedBox(height: 6),
          Text(store.address, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text('좌표: ${store.latitude.toStringAsFixed(3)}, ${store.longitude.toStringAsFixed(3)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.7))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('판매점 정보를 불러오지 못했습니다.'),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
