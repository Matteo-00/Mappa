import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Riga di filtri che scorre in orizzontale e *fa capire* che ce ne sono altri:
/// quando c'è altro contenuto oltre il bordo mostra una sfumatura e una
/// freccia (toccabile) sul lato; la freccia sparisce quando si arriva in fondo.
///
/// Uso: `HorizontalScrollHint(builder: (controller) => ListView(controller: controller, scrollDirection: Axis.horizontal, ...))`
class HorizontalScrollHint extends StatefulWidget {
  final Widget Function(ScrollController controller) builder;

  /// Colore dello sfondo su cui poggia la riga, usato per la sfumatura.
  /// Se null (es. sopra una mappa) niente sfumatura: solo la freccia.
  final Color? fadeColor;

  /// Di quanto scorre toccando la freccia.
  final double step;

  const HorizontalScrollHint({
    super.key,
    required this.builder,
    this.fadeColor = AppColors.avorio,
    this.step = 180,
  });

  @override
  State<HorizontalScrollHint> createState() => _HorizontalScrollHintState();
}

class _HorizontalScrollHintState extends State<HorizontalScrollHint> {
  final ScrollController _controller = ScrollController();
  bool _canGoForward = false;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted || !_controller.hasClients) return;
    final pos = _controller.position;
    final forward = pos.maxScrollExtent - pos.pixels > 8;
    final back = pos.pixels > 8;
    if (forward != _canGoForward || back != _canGoBack) {
      setState(() {
        _canGoForward = forward;
        _canGoBack = back;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    _controller.animateTo(
      (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      // Si aggiorna anche quando cambiano le dimensioni (es. cambia la lingua).
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _update());
        return false;
      },
      child: Stack(
        children: [
          widget.builder(_controller),
          if (_canGoBack) _edge(left: true),
          if (_canGoForward) _edge(left: false),
        ],
      ),
    );
  }

  /// Sfumatura + freccia toccabile su un lato della riga.
  Widget _edge({required bool left}) {
    final fade = widget.fadeColor;
    return Positioned(
      top: 0,
      bottom: 0,
      left: left ? 0 : null,
      right: left ? null : 0,
      child: Stack(
        alignment: left ? Alignment.centerLeft : Alignment.centerRight,
        children: [
          if (fade != null)
            IgnorePointer(
              child: Container(
                width: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: left
                        ? [fade, fade.withOpacity(0)]
                        : [fade.withOpacity(0), fade],
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: left ? 2 : 0, right: left ? 0 : 2),
            child: GestureDetector(
              onTap: () => _scrollBy(left ? -widget.step : widget.step),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  size: 22,
                  color: AppColors.rossoGubbio,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista verticale con **barra laterale sempre visibile** e, quando c'è altro
/// contenuto sotto, una sfumatura con una freccia verso il basso: chi ha uno
/// schermo piccolo capisce che le voci non sono finite.
class VerticalScrollHint extends StatefulWidget {
  final Widget Function(ScrollController controller) builder;
  final Color fadeColor;

  const VerticalScrollHint({
    super.key,
    required this.builder,
    this.fadeColor = Colors.white,
  });

  @override
  State<VerticalScrollHint> createState() => _VerticalScrollHintState();
}

class _VerticalScrollHintState extends State<VerticalScrollHint> {
  final ScrollController _controller = ScrollController();
  bool _canGoDown = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted || !_controller.hasClients) return;
    final pos = _controller.position;
    final down = pos.maxScrollExtent - pos.pixels > 8;
    if (down != _canGoDown) setState(() => _canGoDown = down);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _update());
        return false;
      },
      child: Stack(
        children: [
          Scrollbar(
            controller: _controller,
            thumbVisibility: true,
            thickness: 4,
            radius: const Radius.circular(4),
            child: widget.builder(_controller),
          ),
          if (_canGoDown)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 46,
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.fadeColor.withOpacity(0),
                        widget.fadeColor,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.rossoGubbio,
                    size: 26,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Riga di chip (filtri) scorrevole in orizzontale con i suggerimenti di
/// scorrimento ([HorizontalScrollHint]) già inclusi.
class HintedChipRow extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;
  final Color? fadeColor;

  const HintedChipRow({
    super.key,
    required this.height,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.fadeColor = AppColors.avorio,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: HorizontalScrollHint(
        fadeColor: fadeColor,
        builder: (controller) => ListView(
          controller: controller,
          scrollDirection: Axis.horizontal,
          padding: padding,
          children: children,
        ),
      ),
    );
  }
}
