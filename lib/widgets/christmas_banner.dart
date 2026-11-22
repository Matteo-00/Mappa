import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

/// Banner "Gubbio a Natale" in cima agli eventi: un piccolo disegno a tratto
/// dorato (il Monte Ingino con l'Albero di Natale più grande del mondo fatto
/// di luci, la stella in cima e la città sotto con il Palazzo dei Consoli) e
/// l'invito ad aprire il sito ufficiale gubbionatale.it.
///
/// Si vede solo nel periodo natalizio (vedi [isSeason]).
class ChristmasBanner extends StatefulWidget {
  static const String url = 'https://www.gubbionatale.it/';

  const ChristmasBanner({super.key});

  /// Periodo in cui mostrare il banner: dal 1° novembre al 15 gennaio.
  static bool isSeason([DateTime? now]) {
    final d = now ?? DateTime.now();
    return d.month == 11 || d.month == 12 || (d.month == 1 && d.day <= 15);
  }

  @override
  State<ChristmasBanner> createState() => _ChristmasBannerState();
}

class _ChristmasBannerState extends State<ChristmasBanner>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF0B3D2E);
  static const Color _greenDark = Color(0xFF05241B);
  static const Color _gold = Color(0xFFDFBD81);

  /// Le luci dell'albero brillano piano (un ciclo ogni 4 secondi).
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  /// Apre gubbionatale.it nel browser. Non si controlla prima se "si può
  /// aprire" (su Android 11+ quel controllo può dire di no anche quando il
  /// browser c'è): si prova direttamente, e in caso di errore si riprova con
  /// la modalità predefinita del sistema.
  Future<void> _open() async {
    final uri = Uri.parse(ChristmasBanner.url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) await launchUrl(uri);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (e) {
        debugPrint('ChristmasBanner: impossibile aprire il sito ($e)');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(
      context.watch<LanguageService>().currentLanguageCode,
    );
    return Semantics(
      button: true,
      label: '${l.t('xmasTitle')}. ${l.t('xmasCta')}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _open,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_green, _greenDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: _greenDark.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // Disegno a destra
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _twinkle,
                      builder: (context, _) => CustomPaint(
                        painter: _GubbioNataleArt(_twinkle.value),
                      ),
                    ),
                  ),
                  // Testo a sinistra
                  ConstrainedBox(
                    // Altezza minima; se il testo è più grande (caratteri del
                    // telefono ingranditi) il banner cresce invece di tagliarsi.
                    constraints: const BoxConstraints(minHeight: 160),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 124, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.t('xmasOver'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                              color: _gold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.t('xmasTitle'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 20,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l.t('xmasSub'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.25,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.fromLTRB(12, 5, 8, 5),
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l.t('xmasCta'),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: _greenDark,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 15,
                                  color: _greenDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Disegno "a pennino": tutto a tratto sottile dorato su verde notte.
class _GubbioNataleArt extends CustomPainter {
  final double t; // 0..1, per far brillare le luci
  _GubbioNataleArt(this.t);

  static const Color _gold = Color(0xFFDFBD81);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Il disegno occupa la parte destra del banner.
    final left = w - 150;
    Offset p(double x, double y) => Offset(left + x, y);

    final line = Paint()
      ..color = _gold.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Stelline nel cielo
    final rnd = math.Random(11);
    final dot = Paint()..color = Colors.white;
    for (var i = 0; i < 26; i++) {
      final x = left - 20 + rnd.nextDouble() * 175;
      final y = 6 + rnd.nextDouble() * 50;
      final ph = rnd.nextDouble();
      final a = 0.25 + 0.5 * (0.5 + 0.5 * math.sin(2 * math.pi * (t + ph)));
      dot.color = Colors.white.withValues(alpha: a * 0.7);
      canvas.drawCircle(Offset(x, y), 0.5 + rnd.nextDouble() * 0.7, dot);
    }

    // Monte Ingino: un profilo morbido, riempito appena più scuro.
    final mountain = Path()
      ..moveTo(left - 30, h * 0.80)
      ..cubicTo(
        p(10, h * 0.55).dx,
        p(10, h * 0.55).dy,
        p(40, h * 0.24).dx,
        h * 0.24,
        p(78, h * 0.22).dx,
        h * 0.22,
      )
      ..cubicTo(
        p(110, h * 0.20).dx,
        h * 0.20,
        p(140, h * 0.40).dx,
        h * 0.40,
        w + 10,
        h * 0.52,
      )
      ..lineTo(w + 10, h)
      ..lineTo(left - 30, h)
      ..close();
    canvas.drawPath(
      mountain,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      Path()
        ..moveTo(left - 30, h * 0.80)
        ..cubicTo(
          p(10, h * 0.55).dx,
          p(10, h * 0.55).dy,
          p(40, h * 0.24).dx,
          h * 0.24,
          p(78, h * 0.22).dx,
          h * 0.22,
        )
        ..cubicTo(
          p(110, h * 0.20).dx,
          h * 0.20,
          p(140, h * 0.40).dx,
          h * 0.40,
          w + 10,
          h * 0.52,
        ),
      line,
    );

    // L'albero: luci dorate disposte a forma di abete, a tre "piani" di
    // rami (stessa grandezza e posizione di prima), con il tronco sotto.
    final top = p(76, h * 0.30);
    final light = Paint();
    void bulb(Offset o, double ph) {
      final a = 0.45 + 0.55 * (0.5 + 0.5 * math.sin(2 * math.pi * (t + ph)));
      light.color = const Color(0xFFFFE6A8).withValues(alpha: a);
      canvas.drawCircle(o, 1.6, light);
      light.color = const Color(0xFFFFD27A).withValues(alpha: a * 0.25);
      canvas.drawCircle(o, 3.6, light);
    }

    // Mezza larghezza di ogni fila: ogni "piano" riparte più stretto.
    const halves = [0.0, 9.0, 6.0, 19.0, 12.0, 25.0, 38.0];
    for (var r = 0; r < halves.length; r++) {
      final y = top.dy + (r + 1) * 9.0;
      final half = halves[r];
      final n = math.max(1, (2 * half / 8.5).round() + 1);
      for (var i = 0; i < n; i++) {
        final x = top.dx - half + (n == 1 ? half : 2 * half * i / (n - 1));
        bulb(Offset(x, y), (r * 0.37 + i * 0.21) % 1.0);
      }
    }
    // Tronco: quattro luci, 2 x 2
    for (var r = 0; r < 2; r++) {
      for (var i = 0; i < 2; i++) {
        bulb(
          Offset(top.dx - 3.5 + i * 7, top.dy + 69 + r * 6.5),
          (0.5 + r * 0.3 + i * 0.2) % 1.0,
        );
      }
    }

    // La stella cometa in cima, con un alone che pulsa
    final glow = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(2 * math.pi * t));
    canvas.drawCircle(
      top,
      9,
      Paint()..color = const Color(0xFFFFE6A8).withValues(alpha: 0.18 * glow),
    );
    _star(canvas, top, 5.2, Paint()..color = const Color(0xFFFFE6A8));
    canvas.drawLine(
      top + const Offset(4, -2),
      top + const Offset(26, -11),
      line..strokeWidth = 0.9,
    );

    // La città: tetti e il Palazzo dei Consoli, solo a tratto.
    line.strokeWidth = 1.1;
    final base = h - 2;
    // Punto del disegno: x dal bordo del disegno, y in altezza dalla base.
    Offset c(double x, double y) => Offset(left + x, base - y);
    final lit = Paint()
      ..color = const Color(0xFFFFE6A8).withValues(alpha: 0.85);
    final thin = Paint()
      ..color = _gold.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Casette a sinistra
    final town = Path()..moveTo(left - 30, base - 10);
    for (final (x, ww, hh) in [
      (-22.0, 16.0, 14.0),
      (-6.0, 14.0, 19.0),
      (8.0, 18.0, 13.0),
    ]) {
      town
        ..lineTo(c(x, hh).dx, c(x, hh).dy)
        ..lineTo(c(x + ww / 2, hh + 6).dx, c(x + ww / 2, hh + 6).dy)
        ..lineTo(c(x + ww, hh).dx, c(x + ww, hh).dy);
    }
    town.lineTo(c(26, 8).dx, c(26, 8).dy);
    canvas.drawPath(town, line);

    // Spostato un po' a sinistra rispetto all'albero.
    const dx = -30.0;
    Offset cp(double x, double y) => c(x + dx, y);
    // Palazzo dei Consoli: blocco alto con la merlatura quadrata, la
    // torretta campanaria sull'angolo sinistro, la fila di finestre ad arco
    // in alto, il portale ad arco con la scalinata a ventaglio.
    const x0 = 56.0, x1 = 98.0; // lati del palazzo
    const ph = 26.0; // altezza del corpo
    const tw = 8.0; // larghezza della torretta
    const tt = 36.0; // altezza della torretta
    final pal = Path()
      ..moveTo(cp(x0, 0).dx, cp(x0, 0).dy)
      ..lineTo(cp(x0, tt).dx, cp(x0, tt).dy)
      // due merli sulla torretta
      ..lineTo(cp(x0, tt + 2.5).dx, cp(x0, tt + 2.5).dy)
      ..lineTo(cp(x0 + 2.5, tt + 2.5).dx, cp(x0 + 2.5, tt + 2.5).dy)
      ..lineTo(cp(x0 + 2.5, tt).dx, cp(x0 + 2.5, tt).dy)
      ..lineTo(cp(x0 + tw - 2.5, tt).dx, cp(x0 + tw - 2.5, tt).dy)
      ..lineTo(cp(x0 + tw - 2.5, tt + 2.5).dx, cp(x0 + tw - 2.5, tt + 2.5).dy)
      ..lineTo(cp(x0 + tw, tt + 2.5).dx, cp(x0 + tw, tt + 2.5).dy)
      ..lineTo(cp(x0 + tw, ph).dx, cp(x0 + tw, ph).dy);
    // merlatura del corpo
    var mx = x0 + tw;
    while (mx < x1 - 0.1) {
      final m = math.min(3.0, x1 - mx);
      pal
        ..lineTo(cp(mx, ph + 3).dx, cp(mx, ph + 3).dy)
        ..lineTo(cp(mx + m, ph + 3).dx, cp(mx + m, ph + 3).dy)
        ..lineTo(cp(mx + m, ph).dx, cp(mx + m, ph).dy);
      mx += m;
      final g = math.min(2.6, x1 - mx);
      pal.lineTo(cp(mx + g, ph).dx, cp(mx + g, ph).dy);
      mx += g;
    }
    pal.lineTo(cp(x1, 0).dx, cp(x1, 0).dy);
    canvas.drawPath(pal, line);
    // lato della torretta che scende fino al tetto
    canvas.drawLine(cp(x0 + tw, ph), cp(x0 + tw, ph - 3), thin);
    // fascia di archetti sotto i merli
    canvas.drawLine(cp(x0 + tw, ph - 2.5), cp(x1, ph - 2.5), thin);

    // Cella campanaria della torretta (arco)
    Path arch(double x, double y, double ww, double hh) {
      final r = ww / 2;
      return Path()
        ..moveTo(cp(x, y).dx, cp(x, y).dy)
        ..lineTo(cp(x, y + hh - r).dx, cp(x, y + hh - r).dy)
        ..arcToPoint(
          cp(x + ww, y + hh - r),
          radius: Radius.circular(r),
          clockwise: true,
        )
        ..lineTo(cp(x + ww, y).dx, cp(x + ww, y).dy);
    }

    canvas.drawPath(arch(x0 + 2.4, tt - 9, 3.2, 6), thin);

    // Fila di finestre ad arco, accese
    for (var i = 0; i < 5; i++) {
      final wx = 68.0 + i * 5.8;
      canvas.drawPath(arch(wx, ph - 10, 3.2, 5.5)..close(), lit);
    }
    // Portale ad arco
    canvas.drawPath(arch(83, 4, 5.5, 9), line);
    // Scalinata a ventaglio verso destra
    canvas.drawLine(cp(88.5, 4), cp(93, 4), thin);
    canvas.drawLine(cp(93, 4), cp(98, 0), line);
    canvas.drawPath(
      Path()
        ..moveTo(cp(95, 0).dx, cp(95, 0).dy)
        ..quadraticBezierTo(
          cp(100, 1.5).dx,
          cp(100, 1.5).dy,
          cp(105, 0).dx,
          cp(105, 0).dy,
        ),
      thin,
    );
    // Archi in basso
    canvas.drawPath(arch(64, 0, 4, 7), thin);
    canvas.drawPath(arch(71, 0, 4, 7), thin);

    // Case a destra
    final town2 = Path()..moveTo(c(84, 8).dx, c(84, 8).dy);
    for (final (x, ww, hh) in [
      (86.0, 12.0, 12.0),
      (98.0, 12.0, 16.0),
      (110.0, 14.0, 15.0),
      (124.0, 14.0, 11.0),
      (138.0, 14.0, 14.0),
    ]) {
      town2
        ..lineTo(c(x, hh).dx, c(x, hh).dy)
        ..lineTo(c(x + ww / 2, hh + 6).dx, c(x + ww / 2, hh + 6).dy)
        ..lineTo(c(x + ww, hh).dx, c(x + ww, hh).dy);
    }
    town2.lineTo(w + 10, base - 12);
    canvas.drawPath(town2, line);

    // Qualche finestra accesa nelle case
    for (final (x, y) in [
      (0.0, 9.0),
      (14.0, 6.0),
      (115.0, 7.0),
      (143.0, 8.0),
    ]) {
      canvas.drawRect(Rect.fromLTWH(left + x, base - y, 2.2, 3.2), lit);
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final pt = c + Offset(math.cos(a), math.sin(a)) * rr;
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path..close(), paint);
  }

  @override
  bool shouldRepaint(covariant _GubbioNataleArt old) => old.t != t;
}
