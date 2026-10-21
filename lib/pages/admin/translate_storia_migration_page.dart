import 'package:flutter/material.dart';

import '../../services/content_service.dart';
import '../../services/translation_service.dart';
import '../../theme/app_colors.dart';

/// Pagina amministrativa UNA TANTUM per tradurre (EN/FR/DE) tutti i record
/// già presenti di `storia_epoche` e `storia_contenuti` tramite la Edge
/// Function `translate-content`.
///
/// Riutilizzabile anche in futuro: salta i record che hanno già tutte e
/// tre le traduzioni (EN/FR/DE), così può essere rilanciata in sicurezza
/// per tradurre solo i contenuti nuovi o mancanti.
class TranslateStoriaMigrationPage extends StatefulWidget {
  const TranslateStoriaMigrationPage({super.key});

  @override
  State<TranslateStoriaMigrationPage> createState() =>
      _TranslateStoriaMigrationPageState();
}

class _MigrationLogEntry {
  final String label;
  final String entityType;
  final String entityId;
  final bool ok;
  final String? error;
  const _MigrationLogEntry(
    this.label,
    this.entityType,
    this.entityId,
    this.ok, [
    this.error,
  ]);
}

class _TranslateStoriaMigrationPageState
    extends State<TranslateStoriaMigrationPage> {
  bool _running = false;
  int _total = 0;
  int _done = 0;
  final List<_MigrationLogEntry> _log = [];

  // Piccola pausa tra un contenuto e l'altro per non saturare il limite di
  // richieste/secondo del tier gratuito di Azure Translator.
  static const _delayBetweenItems = Duration(milliseconds: 250);

  Future<void> _translateOne(
    String label,
    String entityType,
    String entityId,
  ) async {
    final result = await TranslationService.translateEntity(
      entityType: entityType,
      entityId: entityId,
    );
    if (!mounted) return;
    setState(() {
      _done++;
      _log.add(_MigrationLogEntry(
        label,
        entityType,
        entityId,
        result.isOk,
        result.isOk ? null : result.message,
      ));
    });
    await Future.delayed(_delayBetweenItems);
  }

  Future<void> _runMigration() async {
    setState(() {
      _running = true;
      _total = 0;
      _done = 0;
      _log.clear();
    });

    try {
      final epoche = await ContentService.fetchStoriaEpoche();
      final contenuti = await ContentService.fetchStoriaContenuti();
      // Anche gli itinerari: le loro tappe (titolo, descrizione, approfondimento...)
      // vengono tradotte insieme.
      final itinerari = await ContentService.fetchItinerari();
      // E tutto il resto dell'app: ristoranti, bar, hotel, chiese, musei,
      // negozi, parcheggi ed eventi (anche per i campi tradotti più di recente,
      // come i tag).
      final ristoranti = await ContentService.fetchRestaurants();
      final bar = await ContentService.fetchBars();
      final hotel = await ContentService.fetchHotels();
      final luoghi = await ContentService.fetchLuoghi();
      final eventi = await ContentService.fetchEvents();

      setState(() => _total = epoche.length +
          contenuti.length +
          itinerari.length +
          ristoranti.length +
          bar.length +
          hotel.length +
          luoghi.length +
          eventi.length +
          1);

      for (final epoca in epoche) {
        if (!mounted) return;
        await _translateOne('Epoca: ${epoca.nome}', 'storia_epoche', epoca.id);
      }

      for (final c in contenuti) {
        if (!mounted) return;
        await _translateOne('Contenuto: ${c.title}', 'storia_contenuti', c.id);
      }

      for (final it in itinerari) {
        if (!mounted) return;
        await _translateOne('Itinerario: ${it.titolo}', 'itinerari', it.id);
      }

      // Testi della pagina Storia (titolo, sottotitolo, introduzione).
      if (!mounted) return;
      await _translateOne('Testi pagina Storia', 'storia_pagina',
          ContentService.storiaPaginaTranslationId);

      for (final r in ristoranti) {
        if (!mounted) return;
        await _translateOne('Ristorante: ${r.name}', 'ristoranti', r.id);
      }
      for (final b in bar) {
        if (!mounted) return;
        await _translateOne('Bar: ${b.name}', 'bar', b.id);
      }
      for (final h in hotel) {
        if (!mounted) return;
        await _translateOne('Hotel: ${h.name}', 'hotel', h.id);
      }
      for (final l in luoghi) {
        if (!mounted) return;
        await _translateOne('${l.tipo.name}: ${l.name}', 'luoghi', l.id);
      }
      for (final e in eventi) {
        if (!mounted) return;
        await _translateOne('Evento: ${e.title}', 'eventi', e.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _log.add(_MigrationLogEntry('Errore generale', '', '', false, e.toString()));
      });
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  /// Ritenta solo le voci fallite nell'ultima esecuzione, senza rifare le
  /// traduzioni già riuscite (utile quando Azure Translator risponde con un
  /// 429 per troppe richieste ravvicinate).
  Future<void> _retryFailed() async {
    final failed = _log.where((e) => !e.ok && e.entityId.isNotEmpty).toList();
    if (failed.isEmpty) return;

    setState(() {
      _running = true;
      _total = failed.length;
      _done = 0;
      _log.removeWhere((e) => !e.ok && e.entityId.isNotEmpty);
    });

    try {
      for (final entry in failed) {
        if (!mounted) return;
        await _translateOne(entry.label, entry.entityType, entry.entityId);
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final failedCount = _log.where((e) => !e.ok).length;

    return Scaffold(
      backgroundColor: AppColors.avorio,
      appBar: AppBar(
        title: const Text('Traduzione Storia di Gubbio (EN/FR/DE)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Traduce in inglese, francese e tedesco tutti i contenuti già '
              'presenti: storia, itinerari (comprese le tappe), ristoranti, bar, '
              'hotel, chiese, musei, negozi, parcheggi ed eventi, '
              'tramite la Edge Function "translate-content". Può essere '
              'rilanciata in sicurezza anche in futuro.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _running ? null : _runMigration,
              icon: const Icon(Icons.translate),
              label: Text(_running ? 'Traduzione in corso...' : 'Avvia traduzione'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rossoGubbio,
                foregroundColor: Colors.white,
              ),
            ),
            if (!_running && failedCount > 0) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _retryFailed,
                icon: const Icon(Icons.replay),
                label: Text('Riprova i $failedCount falliti'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rossoGubbio,
                  side: const BorderSide(color: AppColors.rossoGubbio),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_total > 0) ...[
              LinearProgressIndicator(value: _total == 0 ? 0 : _done / _total),
              const SizedBox(height: 8),
              Text('$_done / $_total completati · $failedCount falliti'),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: _log.length,
                itemBuilder: (context, i) {
                  final entry = _log[_log.length - 1 - i];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      entry.ok ? Icons.check_circle : Icons.error,
                      color: entry.ok ? Colors.green : Colors.red,
                    ),
                    title: Text(entry.label),
                    subtitle: entry.error != null ? Text(entry.error!) : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
