import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/smooth_page_transitions.dart';
import 'core/services/analytics_service.dart';
import 'core/services/coach_tts_service.dart';
import 'core/services/crashlytics_service.dart';
import 'core/services/google_auth_service.dart';
import 'core/services/hakkiri_api_service.dart';
import 'core/services/iap_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/supabase_service.dart';
import 'providers/app_state_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase app first so Crashlytics & Analytics are active from launch
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    await CrashlyticsService.instance.init();
    await AnalyticsService.instance.init();
  } catch (e, st) {
    debugPrint('Firebase initialization failed: $e\n$st');
  }

  // Restore JWT before any screen builds so splash never races an empty session.
  await HakkiriApiService.instance.loadSession();

  // Initialize Supabase with remote credentials or safe offline demo fallback
  await SupabaseService.instance.initialize();
  await GoogleAuthService.bootstrap();
  await CoachTtsService.instance.init();
  // FCM device token at cold start (syncs to API when logged in).
  await PushNotificationService.instance.init();
  // Play / App Store billing — loads monthly & yearly product prices.
  await IapService.instance.init();

  runApp(const HakkiriApp());
}

class HakkiriApp extends StatelessWidget {
  const HakkiriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: MaterialApp(
        title: 'Hakkiri',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [
          AnalyticsService.instance.observer,
        ],
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.royalBlue,
          colorScheme: const ColorScheme.light(
            primary: AppColors.royalBlue,
            secondary: AppColors.chartLavender,
            surface: AppColors.surfaceWhite,
            error: AppColors.coralRed,
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.light().textTheme,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark, // Dark icons on Android
              statusBarBrightness: Brightness.light,    // Dark icons on iOS
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            contentTextStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          ),
          // Smooth fade + slide transition for every screen navigation.
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: SmoothPageTransitionsBuilder(),
              TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
              TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
              TargetPlatform.windows: SmoothPageTransitionsBuilder(),
              TargetPlatform.linux: SmoothPageTransitionsBuilder(),
            },
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
