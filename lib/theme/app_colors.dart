import 'package:flutter/material.dart';

/// ============================================================
/// VISIT GUBBIO — Design System
/// Palette ufficiale (vedi assets/geo/colori.png)
/// ============================================================
class AppColors {
  AppColors._();

  /// Rosso Gubbio — azioni principali, CTA, icone attive
  static const Color rossoGubbio = Color(0xFFB13B2E);

  /// Blu Notte — testi principali, header, navigazione
  static const Color bluNotte = Color(0xFF162B3D);

  /// Tortora — elementi secondari, icone, sfondi sezioni
  static const Color tortora = Color(0xFFB8A48F);

  /// Avorio — sfondi generali, card, superfici
  static const Color avorio = Color(0xFFF7F4EF);

  /// Grigio Chiaro — bordi, divider, testi secondari
  static const Color grigioChiaro = Color(0xFFE5E1DB);

  /// Verde Salvia — natura, parchi, percorsi, highlight
  static const Color verdeSalvia = Color(0xFF7D8F7A);

  static const Color white = Color(0xFFFFFFFF);

  /// Testo secondario (grigio caldo)
  static const Color textMuted = Color(0xFF8C857D);

  /// Overlay scuro per le hero image
  static const LinearGradient heroOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x00000000),
      Color(0x33000000),
      Color(0xCC000000),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  /// Gradiente di fallback (tramonto caldo su Gubbio) se manca la foto hero
  static const LinearGradient heroFallback = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2C1810),
      Color(0xFF7A3B1E),
      Color(0xFFC96B2E),
      Color(0xFFE8A24A),
    ],
    stops: [0.0, 0.4, 0.7, 1.0],
  );
}
