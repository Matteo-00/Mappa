import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils/route_observer.dart';

/// Video di sfondo della home a tutto schermo.
///
/// - **Riempie tutto lo schermo senza deformarsi** (`BoxFit.cover`): a
///   seconda delle proporzioni del telefono vengono tagliati solo i bordi.
///   Se nel file l'immagine ha bande nere ai lati ([contentAspect]) si
///   mostra solo la parte con l'immagine, così le bande non si vedono.
///   Viene riprodotto alla risoluzione originale.
/// - Parte da solo e va **una sola volta**: alla fine si ferma sull'ultimo
///   fotogramma ([finished] diventa true) e l'immagine si riduce con
///   un'animazione finché tutto il palazzo ([finalFocus]) non sta nella parte
///   di schermo visibile ([visibleFraction]). Per rivederlo si cambia [replay].
///   Il volume segue [muted] (di default muto).
/// - Finché non è pronto (o se non si riesce a riprodurlo) mostra [fallback].
/// - Si mette in pausa quando l'app va in background o quando sopra la home
///   si apre un'altra pagina, e riparte al ritorno: niente consumo inutile.
class HomeVideoBackground extends StatefulWidget {
  /// Percorso del video negli asset. Per cambiare video basta sostituire il
  /// file (e, se cambia nome, questa riga).
  static const String asset = 'assets/videohome/clip_visit_gubbio.mp4';

  /// Proporzioni (larghezza / altezza) dell'immagine vera dentro al file,
  /// centrata. La clip attuale (volo del drone sul Palazzo dei Consoli) è un
  /// video verticale 1080×1920 senza bande: si usa tutto il fotogramma.
  /// Per un video con bande nere ai lati qui vanno le proporzioni della sola
  /// parte con l'immagine (es. 9 / 16 dentro un file 16:9).
  static const double contentAspect = 9 / 16;

  /// Parte del Palazzo dei Consoli che a video finito deve stare sopra il
  /// pannello, in frazioni (0-1) dell'ultimo fotogramma: dai merli al portale.
  /// Nell'ultimo fotogramma la facciata riempie tutta la larghezza, così resta
  /// a tutto schermo senza bande ai lati. Se cambia il video va aggiornato.
  static const Rect finalFocus = Rect.fromLTRB(0.03, 0.04, 1.0, 0.58);

  /// Margine in pixel attorno al palazzo a video finito.
  static const double focusMargin = 12;

  final ValueListenable<bool> muted;
  final Widget fallback;

  /// Diventa true quando il video è arrivato in fondo (e si è fermato sull'ultimo
  /// fotogramma), torna false quando riparte.
  final ValueNotifier<bool>? finished;

  /// Ogni volta che questo numero cambia il video riparte dall'inizio.
  final ValueListenable<int>? replay;

  /// Parte dello schermo, a partire dall'alto, non coperta da altri elementi
  /// (0-1): a video finito il palazzo viene inquadrato qui dentro.
  final double visibleFraction;

  const HomeVideoBackground({
    super.key,
    required this.muted,
    required this.fallback,
    this.finished,
    this.replay,
    this.visibleFraction = 1,
  });

  @override
  State<HomeVideoBackground> createState() => _HomeVideoBackgroundState();
}

class _HomeVideoBackgroundState extends State<HomeVideoBackground>
    with WidgetsBindingObserver, RouteAware, SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  bool _ready = false;

  /// True quando il video è finito: resta fermo sull'ultimo fotogramma.
  bool _ended = false;

  /// False quando un'altra pagina è aperta sopra la home.
  bool _pageVisible = true;
  PageRoute<dynamic>? _subscribedRoute;

  /// 0 = video a tutto schermo, 1 = palazzo inquadrato per intero.
  late final AnimationController _fitController;
  late final Animation<double> _fit;

  @override
  void initState() {
    super.initState();
    _fitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      reverseDuration: const Duration(milliseconds: 500),
    );
    _fit = CurvedAnimation(
      parent: _fitController,
      curve: Curves.easeInOutCubic,
    );
    WidgetsBinding.instance.addObserver(this);
    widget.muted.addListener(_applyVolume);
    widget.replay?.addListener(_replay);
    _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(
      HomeVideoBackground.asset,
      // Non interrompe la musica che l'utente sta già ascoltando.
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(widget.muted.value ? 0 : 1);
      if (!mounted) return;
      controller.addListener(_onVideoTick);
      setState(() => _ready = true);
      _syncPlayback();
    } catch (e) {
      // Video non riproducibile: resta lo sfondo di riserva.
      debugPrint('HomeVideoBackground: video non disponibile ($e)');
    }
  }

  /// Si accorge quando il video è arrivato in fondo e lo lascia fermo
  /// sull'ultimo fotogramma.
  void _onVideoTick() {
    final c = _controller;
    if (c == null || _ended) return;
    final v = c.value;
    if (v.duration > Duration.zero &&
        !v.isPlaying &&
        v.position >= v.duration - const Duration(milliseconds: 150)) {
      _ended = true;
      widget.finished?.value = true;
      _fitController.forward();
    }
  }

  /// Rivede il video dall'inizio (pulsante "play" della home).
  Future<void> _replay() async {
    final c = _controller;
    if (c == null || !_ready) return;
    _ended = false;
    widget.finished?.value = false;
    _fitController.reverse();
    await c.seekTo(Duration.zero);
    _syncPlayback();
  }

  void _applyVolume() {
    _controller?.setVolume(widget.muted.value ? 0 : 1);
  }

  /// Riproduce solo se la home è visibile e l'app è in primo piano.
  void _syncPlayback() {
    final c = _controller;
    if (c == null || !_ready) return;
    // Finito: resta fermo sull'ultimo fotogramma finché non si preme "play".
    if (_ended) return;
    final appActive =
        WidgetsBinding.instance.lifecycleState == null ||
            WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (_pageVisible && appActive) {
      c.play();
    } else {
      c.pause();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _subscribedRoute) {
      if (_subscribedRoute != null) appRouteObserver.unsubscribe(this);
      _subscribedRoute = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _syncPlayback();

  // Un'altra pagina si apre sopra la home.
  @override
  void didPushNext() {
    _pageVisible = false;
    _syncPlayback();
  }

  // Si torna alla home.
  @override
  void didPopNext() {
    _pageVisible = true;
    _syncPlayback();
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    widget.muted.removeListener(_applyVolume);
    widget.replay?.removeListener(_replay);
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    _fitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final size = controller?.value.size ?? Size.zero;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.fallback,
        if (_ready && controller != null && size.width > 0 && size.height > 0)
          // Dissolvenza dal fondale al video quando è pronto.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            builder: (context, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) =>
                    _framedVideo(controller, size, constraints.biggest),
              ),
            ),
          ),
      ],
    );
  }

  /// Il video posizionato sullo schermo: durante la riproduzione riempie tutto
  /// (come `BoxFit.cover`), a fine corsa si sposta sull'inquadratura finale.
  Widget _framedVideo(
    VideoPlayerController controller,
    Size videoSize,
    Size screen,
  ) {
    final fileAspect = videoSize.width / videoSize.height;
    final aspect = HomeVideoBackground.contentAspect < fileAspect
        ? HomeVideoBackground.contentAspect
        : fileAspect;
    final w = screen.width;
    final h = screen.height;

    // Inizio: tutto schermo, centrato. "Height" è l'altezza dell'immagine.
    final startHeight = h > w / aspect ? h : w / aspect;
    final startLeft = (w - startHeight * aspect) / 2;
    final startTop = (h - startHeight) / 2;

    // Fine: il palazzo deve stare interamente nell'area visibile.
    const focus = HomeVideoBackground.finalFocus;
    const margin = HomeVideoBackground.focusMargin;
    final visible = h * widget.visibleFraction;
    final fillHeight = visible > w / aspect ? visible : w / aspect;
    final maxByWidth = (w - 2 * margin) / (focus.width * aspect);
    final maxByHeight = (visible - 2 * margin) / focus.height;
    final maxHeight = maxByWidth < maxByHeight ? maxByWidth : maxByHeight;
    final endHeight = fillHeight < maxHeight ? fillHeight : maxHeight;
    final endWidth = endHeight * aspect;

    double within(double value, double space) {
      final limit = space;
      return limit < 0
          ? value.clamp(limit, 0.0).toDouble()
          : value.clamp(0.0, limit).toDouble();
    }

    final endLeft = within(
      (w - (focus.left + focus.right) * endWidth) / 2,
      w - endWidth,
    );
    final endTop = within(
      visible - margin - focus.bottom * endHeight,
      visible - endHeight,
    );

    final content = FittedBox(
      fit: BoxFit.fill,
      child: _visibleArea(controller, videoSize),
    );

    return AnimatedBuilder(
      animation: _fit,
      child: content,
      builder: (context, child) {
        final t = _fit.value;
        final height = lerpDouble(startHeight, endHeight, t)!;
        return Stack(
          children: [
            Positioned(
              left: lerpDouble(startLeft, endLeft, t)!,
              top: lerpDouble(startTop, endTop, t)!,
              width: height * aspect,
              height: height,
              child: child!,
            ),
          ],
        );
      },
    );
  }

  /// Il video alla sua dimensione originale, ritagliato alla sola parte con
  /// l'immagine ([HomeVideoBackground.contentAspect]): le bande nere ai lati
  /// restano fuori.
  Widget _visibleArea(VideoPlayerController controller, Size size) {
    final video = SizedBox(
      width: size.width,
      height: size.height,
      child: VideoPlayer(controller),
    );
    final aspect = HomeVideoBackground.contentAspect;
    if (aspect >= size.width / size.height) return video;

    // Mezzo pixel in meno per lato, per non lasciare filetti scuri ai bordi.
    final contentWidth = size.height * aspect - 1;
    return SizedBox(
      width: contentWidth,
      height: size.height,
      child: ClipRect(
        child: OverflowBox(
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: video,
        ),
      ),
    );
  }
}
