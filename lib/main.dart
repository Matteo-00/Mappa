import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'pages/login_page.dart';

void main() {
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
        title: 'Festa dei Ceri',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Material 3
          useMaterial3: true,
          // ColorScheme con rosso elegante
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB71C1C), // Rosso profondo
            brightness: Brightness.light,
          ),
          // Tipografia moderna
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        home: const LoginPage(),
      ),
    );
  }
}
