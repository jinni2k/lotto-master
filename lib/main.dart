import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const LottoMasterApp());
}

class LottoMasterApp extends StatelessWidget {
  const LottoMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '로또 마스터',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD700),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD700),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<int> _numbers = [];
  final Random _random = Random();

  void _generateNumbers() {
    final Set<int> numberSet = {};
    while (numberSet.length < 6) {
      numberSet.add(_random.nextInt(45) + 1);
    }
    setState(() {
      _numbers = numberSet.toList()..sort();
    });
  }

  Color _getBallColor(int number) {
    if (number <= 10) return const Color(0xFFFFC107); // 노랑
    if (number <= 20) return const Color(0xFF2196F3); // 파랑
    if (number <= 30) return const Color(0xFFE91E63); // 빨강
    if (number <= 40) return const Color(0xFF9E9E9E); // 회색
    return const Color(0xFF4CAF50); // 초록
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎰 로또 마스터'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 로또 번호 카드
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        '오늘의 행운 번호',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (_numbers.isEmpty)
                        Text(
                          '번호를 생성해주세요',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: _numbers.map((n) => _LottoBall(
                            number: n,
                            color: _getBallColor(n),
                          )).toList(),
                        ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _generateNumbers,
                        icon: const Icon(Icons.casino),
                        label: const Text('번호 생성'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(200, 50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 메뉴 그리드
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _MenuCard(
                      icon: Icons.qr_code_scanner,
                      title: 'QR 스캔',
                      subtitle: '복권 스캔',
                      color: Colors.blue,
                      onTap: () => _showComingSoon(context),
                    ),
                    _MenuCard(
                      icon: Icons.history,
                      title: '당첨 결과',
                      subtitle: '최신 회차',
                      color: Colors.orange,
                      onTap: () => _showComingSoon(context),
                    ),
                    _MenuCard(
                      icon: Icons.analytics,
                      title: '통계 분석',
                      subtitle: '번호 분석',
                      color: Colors.purple,
                      onTap: () => _showComingSoon(context),
                    ),
                    _MenuCard(
                      icon: Icons.people,
                      title: '커뮤니티',
                      subtitle: '정보 공유',
                      color: Colors.green,
                      onTap: () => _showComingSoon(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('준비 중입니다'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _LottoBall extends StatelessWidget {
  const _LottoBall({required this.number, required this.color});

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
