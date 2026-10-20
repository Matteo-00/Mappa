import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils/route_observer.dart';

/// Video di sfondo della home a tutto schermo.
///
/// - **Si adatta allo schermo senza deformarsi**: il video riempie sempre
///   tutta l'area (`BoxFit.cover`) e a seconda delle proporzioni del telefono
///   vengono tagliati solo i bordi. Viene riprodotto alla risoluzione
///   originale (nessun ridimensionamento forzato).
/// - Parte da solo, in loop. Il volume segue [muted] (di default muto).
/// - Finché non è pronto (o se non si riesce a riprodurlo) mostra [fallback].
/// - Si mette in pausa quando l'app va in background o quando sopra la home
///   si apre un'altra pagina, e riparte al ritorno: niente consumo inutile.
class HomeVideoBackground extends StatefulWidget {
  /// Percorso del video negli asset. Per cambiare video basta sostituire il
  /// file (e, se cambia nome, questa riga).
  static const String asset = 'assets/videohome/VIDEO-2026-10-18-10-07-38.mp4';

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
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
