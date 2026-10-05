import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/hakkiri_bottom_nav.dart';
import 'home_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'challenges_screen.dart';
import 'settings_screen.dart';

class MainTabScaffold extends StatefulWidget {
  final int initialIndex;

  const MainTabScaffold({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screens = const [
      HomeScreenContent(),
      AnalyticsDashboardContent(),
      ChallengesScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: HakkiriBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}
