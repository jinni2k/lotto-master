import 'package:flutter/material.dart';

import 'screens/analysis_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
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
      home: const LottoHomeShell(),
    );
  }
}

class LottoHomeShell extends StatefulWidget {
  const LottoHomeShell({super.key});

  @override
  State<LottoHomeShell> createState() => _LottoHomeShellState();
}

class _LottoHomeShellState extends State<LottoHomeShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            label: '기록',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_rounded),
            label: '분석',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_rounded),
            label: '추천',
          ),
        ],
      ),
    );
  }
}
