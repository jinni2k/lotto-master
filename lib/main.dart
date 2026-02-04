import 'dart:async';

import 'package:flutter/material.dart';

import 'providers/user_provider.dart';
import 'screens/ai_recommend_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/community_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/dream_screen.dart';
import 'screens/fortune_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lucky_store_screen.dart';
import 'screens/my_tickets_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/recommend_screen.dart';
import 'screens/currency_screen.dart';
import 'screens/simulation_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final userProvider = UserProvider();
  
  try {
    await AdService.instance.initialize();
  } catch (e) {
    debugPrint('AdService init failed: $e');
  }
  
  try {
    await PurchaseService.instance.initialize(userProvider);
  } catch (e) {
    debugPrint('PurchaseService init failed: $e');
  }
  
  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('NotificationService init failed: $e');
  }
  
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
    return MaterialApp(
      title: 'Lotto Master',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routes: {
        '/home': (_) => const LottoHomeShell(),
        PremiumScreen.routeName: (_) => const PremiumScreen(),
        CompareScreen.routeName: (_) => const CompareScreen(),
        DreamScreen.routeName: (_) => const DreamScreen(),
        AIRecommendScreen.routeName: (_) => const AIRecommendScreen(),
        DailyScreen.routeName: (_) => const DailyScreen(),
        FortuneScreen.routeName: (_) => const FortuneScreen(),
        CurrencyScreen.routeName: (_) => const CurrencyScreen(),
        SimulationScreen.routeName: (_) => const SimulationScreen(),
        LuckyStoreScreen.routeName: (_) => const LuckyStoreScreen(),
      },
      home: const SplashScreen(),
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
  StreamSubscription<DrawResultNotification>? _notificationSub;
  DrawResultNotification? _latestNotification;

  static const List<Widget> _screens = [
    HomeScreen(),
    DailyScreen(),
    ScanScreen(),
    MyTicketsScreen(),
    HistoryScreen(),
    AnalysisScreen(),
    RecommendScreen(),
    CommunityScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _notificationSub =
        NotificationService.instance.notifications.listen((notification) {
      if (!mounted) {
        return;
      }
      setState(() {
        _latestNotification = notification;
      });
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                icon: Icon(Icons.today_rounded),
                label: '오늘',
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
              NavigationDestination(
                icon: Icon(Icons.forum_rounded),
                label: '커뮤니티',
              ),
            ],
          ),
        ),
        if (_latestNotification != null)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: _NotificationBanner(
              notification: _latestNotification!,
              onClose: () {
                setState(() {
                  _latestNotification = null;
                });
              },
            ),
          ),
      ],
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner(
      {required this.notification, required this.onClose});

  final DrawResultNotification notification;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(18),
      color: scheme.surface.withOpacity(0.95),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: scheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
