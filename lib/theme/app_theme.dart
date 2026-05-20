import 'package:flutter/material.dart';

/// Enumerazione per le modalità dell'app
enum AppMode {
  visitGubbio,
  festaDeiCeri,
}

/// Classe per gestire i temi dell'applicazione
class AppTheme {
  // ============================================================
  // VISIT GUBBIO - Palette Medievale Moderna
  // ============================================================
  
  // Colori principali
  static const Color vgStoneGray = Color(0xFF6E6A67);
  static const Color vgWarmStone = Color(0xFF8E857F);
  
  // Background
  static const Color vgAncientParchment = Color(0xFFF4EFE8);
  static const Color vgWarmBeige = Color(0xFFE7DED2);
  
  // Accenti
  static const Color vgBronze = Color(0xFFB08D57);
  static const Color vgDarkSlate = Color(0xFF2F2F2F);
  static const Color vgOliveGreen = Color(0xFF6F7D5C);
  
  // Gradienti morbidi
  static const LinearGradient vgHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF4EFE8),
      Color(0xFFE7DED2),
    ],
  );
  
  static const LinearGradient vgCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF4EFE8),
    ],
  );

  // ============================================================
  // FESTA DEI CERI - Palette Tradizionale
  // ============================================================
  
  // Colore principale
  static const Color fcDeepRed = Color(0xFF8B0000);
  static const Color fcBrightRed = Color(0xFFB22222);
  
  // Colori dei tre Ceri
  static const Color fcYellow = Color(0xFFFFD700);
  static const Color fcBlue = Color(0xFF1E3A8A);
  static const Color fcBlack = Color(0xFF1A1A1A);
  
  // Background
  static const Color fcLightBackground = Color(0xFFFFF9F0);
  static const Color fcWhite = Color(0xFFFFFFFF);
  
  // Gradiente rosso
  static const LinearGradient fcHeaderGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF8B0000),
      Color(0xFFB22222),
    ],
  );

  // ============================================================
  // Temi Material
  // ============================================================
  
  /// Tema per modalità VISIT GUBBIO
  static ThemeData getVisitGubbioTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: vgAncientParchment,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: vgBronze,
        brightness: Brightness.light,
        primary: vgBronze,
        secondary: vgStoneGray,
        surface: vgWarmBeige,
        background: vgAncientParchment,
        error: Color(0xFFB71C1C),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: vgAncientParchment,
        foregroundColor: vgDarkSlate,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        shadowColor: vgStoneGray.withOpacity(0.1),
      ),
      
      textTheme: const TextTheme(
        // Titoli eleganti serif
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: vgDarkSlate,
          fontFamily: 'serif',
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: vgBronze,
          fontFamily: 'serif',
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: vgDarkSlate,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: vgStoneGray,
        ),
        // Testo corpo moderno
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: vgDarkSlate,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: vgStoneGray,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: vgBronze,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: vgStoneGray.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vgBronze,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: vgStoneGray.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: vgStoneGray.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: vgStoneGray.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: vgBronze, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      
      dividerColor: vgStoneGray.withOpacity(0.2),
    );
  }
  
  /// Tema per modalità FESTA DEI CERI
  static ThemeData getFestaDeiCeriTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: fcLightBackground,
      
      colorScheme: ColorScheme.fromSeed(
        seedColor: fcDeepRed,
        brightness: Brightness.light,
        primary: fcDeepRed,
        secondary: fcBrightRed,
        surface: fcWhite,
        background: fcLightBackground,
        error: Color(0xFFB71C1C),
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: fcWhite,
        foregroundColor: fcDeepRed,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: fcDeepRed,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: fcDeepRed,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: fcBlack,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: fcBlack,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: fcBlack,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Color(0xFF6B6B6B),
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: fcDeepRed,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: fcWhite,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: fcDeepRed,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fcWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: fcDeepRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      
      dividerColor: Colors.grey.withOpacity(0.2),
    );
  }
  
  /// Ottieni colori header basati sulla modalità
  static Color getHeaderBackground(AppMode mode) {
    return mode == AppMode.visitGubbio ? vgAncientParchment : fcWhite;
  }
  
  static Color getHeaderText(AppMode mode) {
    return mode == AppMode.visitGubbio ? vgDarkSlate : fcDeepRed;
  }
  
  static Color getHeaderIcon(AppMode mode) {
    return mode == AppMode.visitGubbio ? vgBronze : fcDeepRed;
  }
  
  /// Ottieni colori footer basati sulla modalità
  static Color getFooterBackground(AppMode mode) {
    return mode == AppMode.visitGubbio ? vgWarmBeige : fcWhite;
  }
  
  static Color getFooterSelected(AppMode mode) {
    return mode == AppMode.visitGubbio ? vgBronze : fcDeepRed;
  }
  
  static Color getFooterUnselected(AppMode mode) {
    return mode == AppMode.visitGubbio ? vgStoneGray : const Color(0xFF6B6B6B);
  }
}
