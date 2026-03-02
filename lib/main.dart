import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MappaApp());
}

/// Applicazione principale con Material 3 e tema moderno
class MappaApp extends StatelessWidget {
  const MappaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mappa App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Material 3
        useMaterial3: true,
        // ColorScheme con seedColor rosso
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
      ),
      home: const HomePage(),
    );
  }
}
