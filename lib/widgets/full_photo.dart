import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Foto mostrata **intera** dentro un riquadro di qualsiasi forma (es. le
/// miniature delle liste): la foto completa in primo piano con
/// `BoxFit.contain`, quindi senza tagli, e dietro la stessa immagine sfocata
/// che riempie gli spazi vuoti. Stesso effetto della foto nelle pagine di
/// dettaglio.
class FullPhoto extends StatelessWidget {
  final String url;

  /// Mostrato se l'immagine non si carica.
  final Widget fallback;

  /// Intensità della sfocatura dello sfondo.
  final double blur;

  const FullPhoto({
    super.key,
    required this.url,
    required this.fallback,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Sfondo: la stessa foto in cover, sfocata (leggermente ingrandita
        // per non far vedere i bordi chiari della sfocatura).
        ClipRect(
          child: Transform.scale(
            scale: 1.15,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        // Foto intera e nitida (o il fallback, fuori dalla sfocatura).
        Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => fallback,
        ),
      ],
    );
  }
}
