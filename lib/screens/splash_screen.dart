import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../core/constants/app_colors.dart';
import '../core/services/analytics_service.dart';
import '../providers/app_state_provider.dart';
import 'assessment_screen.dart';
import 'home_screen.dart';
import 'landing_screen.dart';
import 'locked_profile_screen.dart';

/// Cinematic Fish Video Splash Screen.
/// Plays the bioluminescent live-animation video (assets/video/splash.mp4)
/// with a clean seamless blue background (no concentric circular rings/banding)
/// and the glowing Hakkiri brand mark.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

const String _kSplashVideoAsset = 'assets/video/splash.mp4';

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  Timer? _timer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(screenName: 'SplashScreen');

    // Entry fade & scale animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );

    _entryController.forward();

    // Default safety timer in case video takes longer to initialize
    _timer = Timer(const Duration(milliseconds: 4000), _navigateToNext);

    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(_kSplashVideoAsset);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _videoReady = true;
      });
      // Allow user to enjoy the live bioluminescent video animation
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 3800), _navigateToNext);
    } catch (_) {
      // If video playback fails, proceed promptly with the clean blue splash
      if (mounted) {
        _timer?.cancel();
        _timer = Timer(const Duration(milliseconds: 2500), _navigateToNext);
      }
    }
  }

  Future<void> _navigateToNext() async {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    _videoController?.pause();

    final state = Provider.of<AppStateProvider>(context, listen: false);
    await state.restoreLocalSessionOnly();
    if (!mounted) return;

    // Sync subscription from API before routing — local session has no plan flag.
    if (state.isLoggedIn) {
      try {
        await state.refreshFromApi();
      } catch (_) {
        // Offline: fall back to last known in-memory flags (default locked).
      }
    }
    if (!mounted) return;

    final Widget next;
    if (state.isLoggedIn && state.isOnboarded && state.isSubscribed) {
      next = const HomeScreen();
    } else if (state.isLoggedIn && state.isOnboarded && !state.isSubscribed) {
      // Assessment done but no Pro — locked profile until they subscribe.
      next = const LockedProfileScreen();
    } else if (state.isLoggedIn && !state.isOnboarded) {
      // Account exists but assessment not done — continue assessment funnel.
      next = const AssessmentScreen();
    } else {
      next = const LandingScreen();
    }

    // Restore dark icons for light home / landing canvas
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 650),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entryController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF000512),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: GestureDetector(
        onTap: _navigateToNext,
        child: Scaffold(
          backgroundColor: const Color(0xFF000512),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Clean, seamless deep blue gradient base (no circles, rings or banding)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.0, -0.05),
                    radius: 1.0,
                    colors: [
                      Color(0xFF0038B8), // vibrant royal blue center
                      Color(0xFF00227A),
                      Color(0xFF001452),
                      Color(0xFF000B32), // deep dark navy
                    ],
                    stops: [0.0, 0.40, 0.70, 1.0],
                  ),
                ),
                child: SizedBox.expand(),
              ),

              // 2. Real live-animation fish video (crossfaded in cleanly)
              if (_videoController != null)
                AnimatedOpacity(
                  opacity: _videoReady ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),

              // 3. Glowing Hakkiri Logo in Center
              Center(
                child: AnimatedBuilder(
                  animation: _entryController,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Image.asset(
                          'assets/images/splash_glowing_logo_hi.png',
                          width: 220,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
