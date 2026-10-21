import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import 'rating_icons.dart';

/// Indicatore di caricamento dell'app: la crescia che gira su se stessa,
/// mostrato mentre si aspettano i dati dal database.
///
/// Tempi ispirati ai classici limiti di risposta delle interfacce:
/// - resta a schermo almeno [minDuration] (vedi [waitMinimum]), così non
///   "lampeggia" quando i dati arrivano subito;
/// - dopo [slowAfter] avvisa che la connessione è lenta (testo + notifica);
/// - dopo [verySlowAfter] consiglia di cambiare rete e, se c'è [onRetry],
///   offre il pulsante "Riprova".
class CresciaLoader extends StatefulWidget {
  static const Duration minDuration = Duration(seconds: 1);
  static const Duration slowAfter = Duration(seconds: 10);
  static const Duration verySlowAfter = Duration(seconds: 25);

  /// Da chiamare prima di togliere la crescia: aspetta il tempo che manca
  /// perché resti a schermo almeno [minDuration] da [start].
  static Future<void> waitMinimum(DateTime start) async {
    final rest = minDuration - DateTime.now().difference(start);
    if (rest > Duration.zero) await Future<void>.delayed(rest);
  }

  /// Altezza della crescia (la larghezza segue le proporzioni dell'immagine).
  final double size;

  /// Ricarica i dati (pulsante "Riprova" quando l'attesa è molto lunga).
  final VoidCallback? onRetry;

  const CresciaLoader({super.key, this.size = 56, this.onRetry});

  @override
  State<CresciaLoader> createState() => _CresciaLoaderState();
}

enum _Wait { normal, slow, verySlow }

class _CresciaLoaderState extends State<CresciaLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

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
      ..add(Timer(CresciaLoader.slowAfter, () => _setWait(_Wait.slow)))
      ..add(Timer(CresciaLoader.verySlowAfter, () => _setWait(_Wait.verySlow)));
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

  /// Notifica in basso, oltre al testo sotto la crescia.
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

    return Center(
      child: Semantics(
        label: message ?? 'Caricamento',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Box quadrato, così ruotando la crescia (più larga che alta)
              // non spinge il resto del layout.
              SizedBox.square(
                dimension: widget.size * CresciaIcon.aspectRatio,
                child: Center(
                  child: RotationTransition(
                    turns: _controller,
                    child: CresciaIcon(size: widget.size),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: message == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
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
      ),
    );
  }
}
