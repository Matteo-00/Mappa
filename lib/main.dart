import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://jqvsfnkypvnjymrnubdv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxdnNmbmt5cHZuanltcm51YmR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NDc2NzIsImV4cCI6MjA4ODEyMzY3Mn0.l0QlcFdwZhrhgxollQ1F-n2bTmQTwhtGWilw_EBdZZo',
  );

  runApp(const MappaApp());
}

/// Applicazione principale con Material 3, tema moderno e gestione stato
class MappaApp extends StatelessWidget {
  const MappaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: '15 Maggio – Festa dei Ceri',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFFFFFFF), // Bianco dominante
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB22222), // Rosso principale #B22222
            brightness: Brightness.light,
            primary: const Color(0xFFB22222),
            secondary: const Color(0xFFC0392B), // Rosso hover
            surface: const Color(0xFFFFFFFF),
            background: const Color(0xFFFFFFFF),
            error: const Color(0xFFB22222),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFFFFFFF),
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: false,
            surfaceTintColor: Colors.transparent,
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Colors.black,
            ),
            displayMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB22222), // Rosso per titoli importanti
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            titleMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF6B6B6B), // Grigio testo secondario
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Color(0xFFFFFFFF),
            selectedItemColor: Color(0xFF2F80ED), // Blu icone #2F80ED
            unselectedItemColor: Color(0xFF6B6B6B), // Grigio
            elevation: 0,
            type: BottomNavigationBarType.fixed,
          ),
          iconTheme: const IconThemeData(
            color: Color(0xFF2F80ED), // Blu per icone #2F80ED
          ),
          dividerColor: const Color(0xFFEAEAEA), // Grigio separatori
          cardTheme: CardThemeData(
            color: const Color(0xFFFFFFFF),
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB22222),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        home: const LoginPage(),
      ),
    );
  }
}
