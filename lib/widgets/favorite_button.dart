import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/favorites_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';

/// Cuore per aggiungere / togliere una scheda dai preferiti.
///
/// Aggiungendo ai preferiti il cuore fa un piccolo "pop", il telefono dà una
/// leggera vibrazione e un cuoricino rosso parte verso l'alto e svanisce.
class FavoriteButton extends StatefulWidget {
  final String kind;
  final String id;

  /// true = cerchio bianco (sopra le foto), false = cerchio scuro trasparente.
  final bool light;

  const FavoriteButton({
    super.key,
    required this.kind,
    required this.id,
    this.light = true,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  /// "Pop" del cuore: si ingrandisce un attimo e torna normale.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.38,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.38,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 60,
    ),
  ]).animate(_pop);

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _toggle(bool wasFavorite, AppLocalizations l) {
    FavoritesService.instance.toggle(widget.kind, widget.id);
    if (!wasFavorite) {
      HapticFeedback.lightImpact();
      _pop.forward(from: 0);
      _launchFlyingHeart();
    } else {
      HapticFeedback.selectionClick();
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.t(wasFavorite ? 'favRemoved' : 'favAdded')),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Cuoricino che parte dal pulsante verso l'alto. Sta nell'Overlay, così
  /// non viene tagliato dai bordi della scheda o della foto.
  void _launchFlyingHeart() {
    final box = context.findRenderObject() as RenderBox?;
    final overlay = Overlay.maybeOf(context);
    if (box == null || overlay == null || !box.attached) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FlyingHeart(start: center, onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesService.instance,
      builder: (context, _) {
        final fav = FavoritesService.instance.isFavorite(
          widget.kind,
          widget.id,
        );
        final l = AppLocalizations.of(
          context.read<LanguageService>().currentLanguageCode,
        );
        return Material(
          color: widget.light
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.black.withValues(alpha: 0.28),
          shape: const CircleBorder(),
          elevation: widget.light ? 3 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _toggle(fav, l),
            child: Tooltip(
              message: l.t(fav ? 'favRemove' : 'favAdd'),
              child: SizedBox(
                width: 42,
                height: 42,
                child: ScaleTransition(
                  scale: _scale,
                  child: Icon(
                    fav
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 23,
                    color: fav
                        ? AppColors.rossoGubbio
                        : (widget.light ? AppColors.bluNotte : Colors.white),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Il cuoricino che sale ondeggiando, si ingrandisce un po' e svanisce.
class _FlyingHeart extends StatefulWidget {
  final Offset start;
  final VoidCallback onDone;

  const _FlyingHeart({required this.start, required this.onDone});

  @override
  State<_FlyingHeart> createState() => _FlyingHeartState();
}

class _FlyingHeartState extends State<_FlyingHeart>
    with SingleTickerProviderStateMixin {
  static const double _size = 16;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_c.value);
          // Sale di 56 px con un leggero ondeggiamento a destra e sinistra.
          final dx = 7 * (t < 0.5 ? t * 2 : (1 - t) * 2) * (t < 0.5 ? 1 : -1);
          final dy = -56 * t;
          final scale = 0.6 + 0.7 * t;
          final opacity = _c.value < 0.55 ? 1.0 : (1 - _c.value) / 0.45;
          return Stack(
            children: [
              Positioned(
                left: widget.start.dx - _size / 2 + dx,
                top: widget.start.dy - _size / 2 - 6 + dy,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale,
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: _size,
                      color: AppColors.rossoGubbio,
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
}
