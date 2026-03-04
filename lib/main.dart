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
        title: '15 Maggio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC00000), // Rosso brand
            brightness: Brightness.light,
            primary: const Color(0xFFC00000),
            surface: Colors.white,
            background: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: false,
          ),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Colors.black,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFFC00000),
            unselectedItemColor: Colors.grey,
            elevation: 8,
            type: BottomNavigationBarType.fixed,
          ),
        ),
        home: const LoginPage(),
      ),
    );
  }
}
