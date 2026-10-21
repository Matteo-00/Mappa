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
/// - Parte da solo, in loop. Il volume segue [muted] (di default muto).
/// - Finché non è pronto (o se non si riesce a riprodurlo) mostra [fallback].
/// - Si mette in pausa quando l'app va in background o quando sopra la home
///   si apre un'altra pagina, e riparte al ritorno: niente consumo inutile.
class HomeVideoBackground extends StatefulWidget {
  /// Percorso del video negli asset. Per cambiare video basta sostituire il
  /// file (e, se cambia nome, questa riga).
  static const String asset = 'assets/videohome/clip_visit_gubbio.mp4';

  /// Proporzioni (larghezza / altezza) dell'immagine vera dentro al file,
  /// centrata. La clip attuale è un video verticale 9:16 salvato in un file
  /// 1920×1080 con bande nere ai lati: si usa solo la fascia centrale.
  /// Per un video senza bande basta metterci le proporzioni del file (es.
  /// 16 / 9): si usa tutto il fotogramma.
  static const double contentAspect = 9 / 16;

  final ValueListenable<bool> muted;
  final Widget fallback;

  const HomeVideoBackground({
    super.key,
    required this.muted,
    required this.fallback,
  });

  @override
  State<HomeVideoBackground> createState() => _HomeVideoBackgroundState();
}

class _HomeVideoBackgroundState extends State<HomeVideoBackground>
    with WidgetsBindingObserver, RouteAware {
  VideoPlayerController? _controller;
  bool _ready = false;

  /// False quando un'altra pagina è aperta sopra la home.
  bool _pageVisible = true;
  PageRoute<dynamic>? _subscribedRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.muted.addListener(_applyVolume);
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
      await controller.setLooping(true);
      await controller.setVolume(widget.muted.value ? 0 : 1);
      if (!mounted) return;
      setState(() => _ready = true);
      _syncPlayback();
    } catch (e) {
      // Video non riproducibile: resta lo sfondo di riserva.
      debugPrint('HomeVideoBackground: video non disponibile ($e)');
    }
  }

  void _applyVolume() {
    _controller?.setVolume(widget.muted.value ? 0 : 1);
  }

  /// Riproduce solo se la home è visibile e l'app è in primo piano.
  void _syncPlayback() {
    final c = _controller;
    if (c == null || !_ready) return;
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
    _controller?.dispose();
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
              child: FittedBox(
                // cover = riempie tutto lo schermo senza deformare il video.
                fit: BoxFit.cover,
                child: _visibleArea(controller, size),
              ),
            ),
          ),
      ],
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
