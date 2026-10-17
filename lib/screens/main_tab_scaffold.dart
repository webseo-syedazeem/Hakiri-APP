import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../core/services/push_notification_service.dart';
import '../providers/app_state_provider.dart';
import '../widgets/hakkiri_bottom_nav.dart';
import 'home_screen.dart';
import 'progress_screen.dart';
import 'practice_screen.dart';
import 'profile_screen.dart';

class MainTabScaffold extends StatefulWidget {
  final int initialIndex;

  const MainTabScaffold({
    super.key,
    this.initialIndex = 0,
  });

  /// Switch the global bottom navigation tab from any screen or child widget.
  /// Index 0: Today/Home, Index 1: Progress, Index 2: Practice, Index 3: Profile/Settings
  static void switchTab(BuildContext context, int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    final scope = MainTabScaffoldScope.of(context);
    if (scope != null) {
      scope.switchTab(index);
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MainTabScaffold(initialIndex: index)),
      (route) => route.isFirst,
    );
  }

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class MainTabScaffoldScope extends InheritedWidget {
  final void Function(int index) switchTab;
  final int currentIndex;

  const MainTabScaffoldScope({
    super.key,
    required this.switchTab,
    required this.currentIndex,
    required super.child,
  });

  static MainTabScaffoldScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainTabScaffoldScope>();
  }

  @override
  bool updateShouldNotify(MainTabScaffoldScope oldWidget) =>
      currentIndex != oldWidget.currentIndex;
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  static const _tabNames = ['Today', 'Progress', 'Practice', 'Profile'];
  late int _currentIndex;
  DateTime? _lastBackPressTime;

  void _setTab(int index) {
    if (mounted && _currentIndex != index) {
      setState(() => _currentIndex = index);
      final tabName = (index >= 0 && index < _tabNames.length)
          ? _tabNames[index]
          : 'Tab$index';
      AnalyticsService.instance.logTabSelected(
        tabIndex: index,
        tabName: tabName,
      );
      AnalyticsService.instance.logScreenView(
        screenName: '${tabName}Screen',
      );
      if (index == 0) {
        PushNotificationService.instance.requestPermissionOnHomeScreen();
      }
    }
  }

  void _handleBackPress() {
    // 1. If currently on Profile or any non-Home tab, return to Home
    if (_currentIndex != 0) {
      _setTab(0);
      return;
    }

    // 2. On Home tab: double back press within 2 seconds to exit app
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          elevation: 4,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text(
                'Press back again to exit',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // 3. Second press within 2 seconds -> close the app
    ScaffoldMessenger.of(context).clearSnackBars();
    SystemNavigator.pop();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    final tabName = (widget.initialIndex >= 0 && widget.initialIndex < _tabNames.length)
        ? _tabNames[widget.initialIndex]
        : 'Tab${widget.initialIndex}';
    AnalyticsService.instance.logScreenView(
      screenName: '${tabName}Screen',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppStateProvider>();
      if (state.isLoggedIn) {
        state.refreshFromApi();
      }
      if (_currentIndex == 0) {
        PushNotificationService.instance.requestPermissionOnHomeScreen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [
      HomeScreenContent(),
      ProgressScreenContent(),
      PracticeScreenContent(),
      ProfileScreenContent(),
    ];

    return MainTabScaffoldScope(
      switchTab: _setTab,
      currentIndex: _currentIndex,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _handleBackPress();
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // Dark icons (battery, clock, wifi) on Android
            statusBarBrightness: Brightness.light,    // Dark text/icons on iOS
            systemNavigationBarColor: AppColors.background,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: AppColors.background,
            bottomNavigationBar: HakkiriBottomNav(
              currentIndex: _currentIndex,
              onTap: _setTab,
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
        ),
      ),
    );
  }
}
