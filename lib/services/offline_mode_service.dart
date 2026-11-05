import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'language_service.dart';

/// Modalità offline.
///
/// Se il server non risponde entro [slowAfter] l'app chiede all'utente se
/// vuole continuare con i dati salvati sul telefono ([askToGoOffline]). In
/// modalità offline le liste si aprono subito con la copia salvata, in basso
/// compare la barra [OfflineBanner] e ogni [checkEvery] si controlla in
/// silenzio se il segnale è tornato: in quel caso la barra propone "Torna
/// online", che ricarica le pagine con i dati nuovi.
class OfflineModeService extends ChangeNotifier {
  OfflineModeService._();
  static final OfflineModeService instance = OfflineModeService._();

  /// Dopo quanto tempo senza risposta si propone la modalità offline.
  static const slowAfter = Duration(seconds: 10);
  static const checkEvery = Duration(seconds: 20);

  /// Navigatore dell'app (impostato in main.dart): serve per mostrare la
  /// finestra anche mentre una pagina sta caricando.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Lingua corrente, per i testi della finestra e della barra.
  LanguageService? language;

  bool _offline = false;
  bool _signalBack = false;
  DateTime? _dataSavedAt;
  int _generation = 0;
  Future<bool>? _pendingQuestion;
  Timer? _timer;

  bool get isOffline => _offline;

  /// In modalità offline: il server ha risposto di nuovo.
  bool get signalBack => _signalBack;

  /// Data della copia più vecchia usata in modalità offline.
  DateTime? get dataSavedAt => _dataSavedAt;

  /// Cambia quando si torna online: le pagine lo confrontano (insieme alla
  /// lingua) per sapere quando ricaricare i dati.
  String get reloadKey => _generation == 0 ? '' : '#$_generation';

  /// Annota la data della copia salvata che si sta mostrando.
  void usedCopyFrom(DateTime? savedAt) {
    if (savedAt == null) return;
    if (_dataSavedAt == null || savedAt.isBefore(_dataSavedAt!)) {
      _dataSavedAt = savedAt;
      notifyListeners();
    }
  }

  /// Chiede (una volta sola anche se più liste stanno caricando insieme) se
  /// passare alla modalità offline. true = modalità offline, false = riprova.
  Future<bool> askToGoOffline(DateTime? savedAt) {
    if (_offline) return Future.value(true);
    return _pendingQuestion ??= _ask(savedAt).whenComplete(() {
      _pendingQuestion = null;
    });
  }

  Future<bool> _ask(DateTime? savedAt) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return true; // nessuna schermata: si usano i dati salvati
    final l = AppLocalizations.of(language?.currentLanguageCode ?? 'it');
    final offline = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(Icons.signal_cellular_connected_no_internet_4_bar,
            color: AppColors.rossoGubbio, size: 34),
        title: Text(l.t('offTitle')),
        content: Text(
          savedAt == null
              ? l.t('offText')
              : '${l.t('offText')}\n\n${l.fmt('offSavedAt', {
                  'date': formatDate(savedAt)
                })}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l.t('offRetry')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.rossoGubbio),
            child: Text(l.t('offUseSaved')),
          ),
        ],
      ),
    );
    if (offline == true) _goOffline();
    return offline == true;
  }

  void _goOffline() {
    _offline = true;
    _signalBack = false;
    notifyListeners();
    _timer?.cancel();
    _timer = Timer.periodic(checkEvery, (_) => _checkSignal());
  }

  /// Controllo leggero: una riga di una tabella pubblica.
  Future<bool> _serverReachable() async {
    try {
      await Supabase.instance.client
          .from('eventi')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkSignal() async {
    if (!_offline || _signalBack) return;
    if (await _serverReachable()) {
      _signalBack = true;
      notifyListeners();
    }
  }

  /// "Torna online" / "Riprova online": se il server risponde si esce dalla
  /// modalità offline e le pagine ricaricano i dati. Ritorna false se il
  /// segnale non c'è ancora.
  Future<bool> goOnline() async {
    if (!_signalBack && !await _serverReachable()) return false;
    _timer?.cancel();
    _offline = false;
    _signalBack = false;
    _dataSavedAt = null;
    _generation++;
    notifyListeners();
    return true;
  }

  /// "4/11 alle 18:30" (formato breve, uguale in tutte le lingue).
  String formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.day}/${d.month} ${two(d.hour)}:${two(d.minute)}';
  }
}

/// Barra in basso visibile in modalità offline: spiega da quando sono i dati
/// e, quando il segnale torna, propone di tornare online.
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _busy = false;

  Future<void> _online(AppLocalizations l) async {
    setState(() => _busy = true);
    final ok = await OfflineModeService.instance.goOnline();
    if (!mounted) return;
    setState(() => _busy = false);
    final ctx = OfflineModeService.navigatorKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(SnackBar(
        content: Text(l.t(ok ? 'offBackOnline' : 'offStillOffline')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OfflineModeService.instance,
      builder: (context, _) {
        final s = OfflineModeService.instance;
        if (!s.isOffline) return const SizedBox.shrink();
        final l = AppLocalizations.of(
            s.language?.currentLanguageCode ?? 'it');
        final back = s.signalBack;
        final text = back
            ? l.t('offSignalBack')
            : s.dataSavedAt == null
                ? l.t('offBanner')
                : '${l.t('offBanner')} · ${l.fmt('offBannerDate', {
                    'date': s.formatDate(s.dataSavedAt!)
                  })}';
        return Material(
          color: back ? const Color(0xFF2E7D32) : AppColors.bluNotte,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(
                    back ? Icons.wifi_rounded : Icons.cloud_off_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _online(l),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            l.t(back ? 'offGoOnline' : 'offTryOnline'),
                            style:
                                const TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
