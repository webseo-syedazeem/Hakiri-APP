import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/smooth_page_transitions.dart';
import 'core/services/supabase_service.dart';
import 'providers/app_state_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with remote credentials or safe offline demo fallback
  await SupabaseService.instance.initialize();

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
