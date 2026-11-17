import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import 'premium_scaffold.dart';

/// Schermata di caricamento dell'app, mostrata mentre si aspettano i dati dal
/// database.
///
/// "Giostra 3D": al centro il logo di Visit Gubbio in un cerchio (bordo
/// marroncino) che fluttua sopra la sua ombra; intorno, su un'orbita
/// inclinata, girano le piccole icone tonde (bordo rosso) dei simboli di
/// Gubbio, passando davanti e dietro al logo.
///
/// Tempi:
/// - resta a schermo almeno [minDuration] (vedi [waitMinimum]), così non
///   "lampeggia" quando i dati arrivano subito;
/// - dopo [slowAfter] avvisa che la connessione è lenta (testo + notifica);
/// - dopo [verySlowAfter] consiglia di cambiare rete e, se c'è [onRetry],
///   offre il pulsante "Riprova".
class LoadingScreen extends StatefulWidget {
  // Resta a schermo almeno 1,7 secondi; gli avvisi di lentezza scattano dopo
  // 15 e 30 secondi.
  static const Duration minDuration = Duration(milliseconds: 1700);
  static const Duration slowAfter = Duration(seconds: 15);
  static const Duration verySlowAfter = Duration(seconds: 30);

  /// Colore del bordo del logo centrale (il marroncino della palette).
  static const Color logoRingColor = AppColors.tortora;

  /// Colore del bordo delle piccole icone che girano (come i pulsanti dell'app).
  static const Color orbitRingColor = AppColors.rossoGubbio;

  static const String _logo = 'assets/loading/logo.png';
  static const List<String> _orbitIcons = [
    'assets/loading/san_francesco.png',
    'assets/loading/anfiteatro.png',
    'assets/loading/palazzo.png',
    'assets/loading/piastrelle.png',
    'assets/loading/albero.png',
    'assets/loading/crescia.png',
    'assets/loading/balestra.png',
  ];

  /// Da chiamare prima di togliere la schermata: aspetta il tempo che manca
  /// perché resti a schermo almeno [minDuration] da [start].
  static Future<void> waitMinimum(DateTime start) async {
    final rest = minDuration - DateTime.now().difference(start);
    if (rest > Duration.zero) await Future<void>.delayed(rest);
  }

  /// Ricarica i dati (pulsante "Riprova" quando l'attesa è molto lunga).
  final VoidCallback? onRetry;

  /// true = pagina intera (sfondo proprio e pulsanti indietro / home);
  /// false = solo l'animazione centrata, da usare dentro una pagina che ha già
  /// la sua barra in alto.
  final bool fullPage;

  /// Diametro del logo centrale; le icone che girano sono 1/3 del logo.
  /// Sugli schermi stretti si rimpicciolisce da solo per restare dentro.
  final double logoSize;

  const LoadingScreen({
    super.key,
    this.onRetry,
    this.fullPage = true,
    this.logoSize = 162,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

enum _Wait { normal, slow, verySlow }

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  /// Durata del ciclo dell'animazione (2 giri delle icone, 6 respiri).
  static const Duration _orbitPeriod = Duration(seconds: 18);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _orbitPeriod)..repeat();

  _Wait _wait = _Wait.normal;
  final List<Timer> _timers = [];
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _snackBar;

  @override
  void initState() {
    super.initState();
    _startTimers();
  }

  void _startTimers() {
    _timers
      ..add(Timer(LoadingScreen.slowAfter, () => _setWait(_Wait.slow)))
      ..add(Timer(LoadingScreen.verySlowAfter, () => _setWait(_Wait.verySlow)));
  }

  AppLocalizations get _l10n => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  void _setWait(_Wait wait) {
    if (!mounted) return;
    setState(() => _wait = wait);
    _notify(wait == _Wait.slow
        ? _l10n.t('loadingSlow')
        : _l10n.t('loadingVerySlow'));
  }

  /// Notifica in basso, oltre al testo sotto l'animazione.
  void _notify(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    _snackBar?.close();
    _snackBar = messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: widget.onRetry != null && _wait == _Wait.verySlow
            ? SnackBarAction(label: _l10n.t('loadingRetry'), onPressed: _retry)
            : null,
      ),
    );
  }

  void _retry() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _snackBar?.close();
    _snackBar = null;
    setState(() => _wait = _Wait.normal);
    _startTimers();
    widget.onRetry?.call();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    // I dati sono arrivati: l'avviso di lentezza non serve più.
    _snackBar?.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = switch (_wait) {
      _Wait.normal => null,
      _Wait.slow => _l10n.t('loadingSlow'),
      _Wait.verySlow => _l10n.t('loadingVerySlow'),
    };

    final content = Center(
      child: Semantics(
        label: message ?? 'Caricamento',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnimation(),
            const SizedBox(height: 18),
            Text(
              _l10n.t('loadingText'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.rossoGubbio,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: message == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(32, 22, 32, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (_wait == _Wait.verySlow &&
                              widget.onRetry != null) ...[
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(_l10n.t('loadingRetry')),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.rossoGubbio,
                                side: const BorderSide(
                                    color: AppColors.rossoGubbio),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );

    if (!widget.fullPage) return content;

    // Pagina intera: sfondo proprio e, in alto, indietro + home per non restare
    // bloccati se l'attesa è lunga.
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const NavButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Misura lo spazio disponibile e sceglie la dimensione dell'animazione.
  Widget _buildAnimation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        // L'animazione è disegnata su 320x320 e poi scalata: con il logo da
        // 162 occupa ~345 px, sugli schermi stretti si rimpicciolisce.
        final side = math.min(widget.logoSize * 320 / 150, available - 24);
        return SizedBox(
          width: side,
          height: side,
          child: FittedBox(
            child: SizedBox(
              width: 320,
              height: 320,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => _buildCarousel(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// "Giostra 3D": le icone girano su un'orbita inclinata passando davanti e
  /// dietro al logo, che fluttua sopra la sua ombra. Le icone dietro sono più
  /// piccole e sbiadite: così si vede la profondità.
  Widget _buildCarousel() {
    final s = _controller.value * _orbitPeriod.inMilliseconds / 1000;
    const icons = LoadingScreen._orbitIcons;
    final items = <(double, Widget)>[];
    for (var i = 0; i < icons.length; i++) {
      // Un giro ogni 9 secondi.
      final a = 2 * math.pi * (s / 9 + i / icons.length);
      final depth = math.sin(a); // -1 dietro, +1 davanti
      final scale = 0.72 + 0.34 * (depth + 1) / 2;
      items.add((
        depth,
        Positioned(
          left: 160 + 148 * math.cos(a) - 29 * scale,
          top: 182 + 56 * depth - 29 * scale,
          child: Opacity(
            opacity: 0.55 + 0.45 * (depth + 1) / 2,
            child: _orbitIcon(icons[i], 58 * scale),
          ),
        ),
      ));
    }
    items.sort((a, b) => a.$1.compareTo(b.$1));
    // Il logo sale e scende piano (un respiro ogni 3 secondi).
    final float = 6 * math.sin(2 * math.pi * s / 3);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Ombra a terra del logo: più chiara quando il logo sale.
        Positioned(
          left: 110,
          top: 200,
          child: Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: 0.16 - 0.05 * (float / 6)),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        // Orbita inclinata.
        Positioned(
          left: 12,
          top: 126,
          child: Container(
            width: 296,
            height: 112,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.all(Radius.elliptical(148, 56)),
              border: Border.all(
                  color: AppColors.tortora.withValues(alpha: 0.45),
                  width: 1.4),
            ),
          ),
        ),
        for (final it in items.where((e) => e.$1 < 0)) it.$2,
        Positioned(
          left: 85,
          top: 40 + float,
          child: _logo(150),
        ),
        for (final it in items.where((e) => e.$1 >= 0)) it.$2,
      ],
    );
  }

  Widget _logo(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: LoadingScreen.logoRingColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: LoadingScreen.logoRingColor.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      // Un filo di ingrandimento: il logo ha molto bianco intorno.
      child: Transform.scale(
        scale: 1.12,
        child: Image.asset(LoadingScreen._logo,
            fit: BoxFit.cover, filterQuality: FilterQuality.medium),
      ),
    );
  }

  Widget _orbitIcon(String asset, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: LoadingScreen.orbitRingColor, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.09),
          child: Image.asset(asset,
              fit: BoxFit.contain, filterQuality: FilterQuality.medium),
        ),
      ),
    );
  }
}
