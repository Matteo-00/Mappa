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
/// Al centro il logo di Visit Gubbio in un cerchio (bordo marroncino) che
/// "respira", cioè si ingrandisce e rimpicciolisce appena; intorno ruotano in
/// senso orario cinque piccole icone tonde (bordo rosso) dei simboli di Gubbio:
/// San Francesco e il lupo, il teatro romano, il Palazzo dei Consoli, lo
/// stemma e l'albero di Natale più grande del mondo.
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
  /// Un giro completo delle icone.
  static const Duration _orbitPeriod = Duration(seconds: 18);

  /// Battiti del logo per ogni giro (6 su 18 s = un respiro ogni 3 s).
  static const int _pulsesPerOrbit = 6;

  /// Larghezza dell'area (logo + giro delle icone) in rapporto al logo, senza
  /// i margini: 2 * (0,9367 + 1/6).
  static const double _areaToLogo = 2.2068;

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
                    if (Navigator.of(context).canPop()) ...[
                      const BackCircleButton(),
                      const SizedBox(width: 8),
                    ],
                    const HomeButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Misura lo spazio disponibile e sceglie la dimensione del logo.
  Widget _buildAnimation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 360.0;
        // Sugli schermi stretti il logo si rimpicciolisce quel tanto che basta
        // per restare dentro (8 px di margine nell'area + 12 px per lato).
        final fitLogo = (available - 8 - 16) / _areaToLogo;
        return _buildOrbit(math.min(widget.logoSize, fitLogo));
      },
    );
  }

  /// Logo che pulsa + icone che girano in senso orario.
  Widget _buildOrbit(double logo) {
    final k = logo / 112; // fattore di scala di bordi, ombre e tratteggio
    final icon = logo / 3; // le icone sono 1/3 del logo
    final radius = logo / 2 + icon / 2 + logo * 0.27; // distanza dal centro
    final area = (radius + icon / 2) * 2 + 8;
    const icons = LoadingScreen._orbitIcons;

    return SizedBox(
      width: area,
      height: area,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value; // 0..1 = un giro completo
          // Respiro armonico: si ingrandisce e rimpicciolisce di pochissimo.
          final pulse = math.sin(2 * math.pi * _pulsesPerOrbit * t);
          final scale = 1 + 0.045 * pulse;
          final glow = 0.5 + 0.5 * pulse; // 0..1, segue il respiro

          return Stack(
            alignment: Alignment.center,
            children: [
              // Traccia sottile del percorso delle icone.
              CustomPaint(
                size: Size.square(area),
                painter: _OrbitPathPainter(radius: radius, scale: k),
              ),
              // Icone: l'angolo cresce nel tempo; con l'asse y verso il basso
              // questo significa senso ORARIO. Restano dritte (non ruotano).
              for (var i = 0; i < icons.length; i++)
                _orbitIcon(
                  asset: icons[i],
                  angle: -math.pi / 2 + 2 * math.pi * (t + i / icons.length),
                  radius: radius,
                  area: area,
                  size: icon,
                  scale: k,
                ),
              // Logo al centro che pulsa.
              Transform.scale(
                scale: scale,
                child: Container(
                  width: logo,
                  height: logo,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                        color: LoadingScreen.logoRingColor, width: 4 * k),
                    boxShadow: [
                      BoxShadow(
                        color: LoadingScreen.logoRingColor
                            .withOpacity(0.18 + 0.14 * glow),
                        blurRadius: (14 + 10 * glow) * k,
                        spreadRadius: (1 + 2 * glow) * k,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  // Un filo di ingrandimento: il logo ha molto bianco intorno.
                  child: Transform.scale(
                    scale: 1.12,
                    child: Image.asset(
                      LoadingScreen._logo,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orbitIcon({
    required String asset,
    required double angle,
    required double radius,
    required double area,
    required double size,
    required double scale,
  }) {
    final cx = area / 2 + radius * math.cos(angle);
    final cy = area / 2 + radius * math.sin(angle);
    return Positioned(
      left: cx - size / 2,
      top: cy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
              color: LoadingScreen.orbitRingColor, width: 2.2 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6 * scale,
              offset: Offset(0, 2 * scale),
            ),
          ],
        ),
        child: ClipOval(
          child: Padding(
            padding: EdgeInsets.all(size * 0.09),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cerchio tratteggiato e leggerissimo lungo il quale girano le icone.
class _OrbitPathPainter extends CustomPainter {
  final double radius;
  final double scale;
  _OrbitPathPainter({required this.radius, this.scale = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.tortora.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    final center = size.center(Offset.zero);
    const dashes = 72;
    const sweep = 2 * math.pi / dashes;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweep,
        sweep * 0.45,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPathPainter old) =>
      old.radius != radius || old.scale != scale;
}
