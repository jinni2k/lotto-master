import 'package:flutter/material.dart';

import 'screens/analysis_screen.dart';
import 'screens/history_screen.dart';
import 'screens/recommend_screen.dart';

void main() {
  runApp(const LottoMasterApp());
}

class LottoMasterApp extends StatelessWidget {
  const LottoMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1A4F7A);
    return MaterialApp(
      title: 'Lotto Master',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F1E8),
      ),
      home: const LottoHome(),
    );
  }
}

class LottoHome extends StatefulWidget {
  const LottoHome({super.key});

  @override
  State<LottoHome> createState() => _LottoHomeState();
}

class _LottoHomeState extends State<LottoHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HistoryScreen(),
    AnalysisScreen(),
    RecommendScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '최근',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: '추천',
          ),
        ],
      ),
    );
  }
}
