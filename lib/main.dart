import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'services/language_service.dart';
import 'theme/app_colors.dart';
import 'pages/splash_intro_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kcoglivbakjyxszoruka.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtjb2dsaXZiYWtqeXhzem9ydWthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNDA0NTcsImV4cCI6MjA4ODYxNjQ1N30.ICFTE2V6Y62BjT2gagazjLvyW8RZIZUji_D575hC5sY',
  );

  runApp(const VisitGubbioApp());
}

/// Applicazione VISIT GUBBIO con sistema di temi dinamico
class VisitGubbioApp extends StatelessWidget {
  const VisitGubbioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
      ],
      child: MaterialApp(
        title: 'Visit Gubbio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.avorio,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.rossoGubbio,
            brightness: Brightness.light,
            primary: AppColors.rossoGubbio,
            secondary: AppColors.tortora,
            surface: AppColors.white,
            error: const Color(0xFFB71C1C),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.bluNotte,
            elevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.transparent,
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontFamily: 'serif',
              fontSize: 56,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
              height: 1.0,
              color: AppColors.bluNotte,
            ),
            headlineMedium: TextStyle(
              fontFamily: 'serif',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.bluNotte,
            ),
            titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte,
              letterSpacing: 0.1,
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.bluNotte,
            ),
            bodyLarge: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AppColors.bluNotte,
            ),
            bodyMedium: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          dividerColor: AppColors.grigioChiaro,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rossoGubbio,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
        home: const SplashIntroPage(),
      ),
    );
  }
}
