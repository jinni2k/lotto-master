import 'package:flutter/material.dart';

import 'providers/user_provider.dart';
import 'screens/analysis_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_tickets_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/recommend_screen.dart';
import 'screens/scan_screen.dart';
import 'services/ad_service.dart';
import 'services/purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final userProvider = UserProvider();
  await AdService.instance.initialize();
  await PurchaseService.instance.initialize(userProvider);
  runApp(
    UserProviderScope(
      notifier: userProvider,
      child: const LottoMasterApp(),
    ),
  );
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
      routes: {
        PremiumScreen.routeName: (_) => const PremiumScreen(),
      },
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
    ScanScreen(),
    MyTicketsScreen(),
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
            icon: Icon(Icons.document_scanner_rounded),
            label: '스캔',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_rounded),
            label: '내 티켓',
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
