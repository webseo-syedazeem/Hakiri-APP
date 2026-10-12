import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/smooth_page_transitions.dart';
import 'core/services/google_auth_service.dart';
import 'core/services/hakkiri_api_service.dart';
import 'core/services/supabase_service.dart';
import 'providers/app_state_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore JWT before any screen builds so splash never races an empty session.
  await HakkiriApiService.instance.loadSession();

  // Initialize Supabase with remote credentials or safe offline demo fallback
  await SupabaseService.instance.initialize();
  await GoogleAuthService.bootstrap();

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
