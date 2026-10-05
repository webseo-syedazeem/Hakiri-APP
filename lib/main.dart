import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/services/supabase_service.dart';
import 'providers/app_state_provider.dart';
import 'screens/landing_screen.dart';

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
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.background,
          primaryColor: AppColors.accentCyan,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentCyan,
            secondary: AppColors.accentBlue,
            surface: AppColors.surface,
            error: AppColors.accentRose,
          ),
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),
          useMaterial3: true,
        ),
        home: const LandingScreen(),
      ),
    );
  }
}
