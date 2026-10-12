import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
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
  late int _currentIndex;

  void _setTab(int index) {
    if (mounted && _currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppStateProvider>();
      if (state.isLoggedIn) {
        state.refreshFromApi();
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
    );
  }
}
