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
  final bool ok;
  final String? error;
  const _MigrationLogEntry(this.label, this.ok, [this.error]);
}

class _TranslateStoriaMigrationPageState
    extends State<TranslateStoriaMigrationPage> {
  bool _running = false;
  int _total = 0;
  int _done = 0;
  final List<_MigrationLogEntry> _log = [];

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

      setState(() => _total = epoche.length + contenuti.length);

      for (final epoca in epoche) {
        final result = await TranslationService.translateEntity(
          entityType: 'storia_epoche',
          entityId: epoca.id,
        );
        if (!mounted) return;
        setState(() {
          _done++;
          _log.add(_MigrationLogEntry(
            'Epoca: ${epoca.nome}',
            result.isOk,
            result.isOk ? null : result.message,
          ));
        });
      }

      for (final c in contenuti) {
        final result = await TranslationService.translateEntity(
          entityType: 'storia_contenuti',
          entityId: c.id,
        );
        if (!mounted) return;
        setState(() {
          _done++;
          _log.add(_MigrationLogEntry(
            'Contenuto: ${c.title}',
            result.isOk,
            result.isOk ? null : result.message,
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _log.add(_MigrationLogEntry('Errore generale', false, e.toString()));
      });
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
              'Traduce in inglese, francese e tedesco tutti i record già '
              'presenti nelle tabelle storia_epoche e storia_contenuti, '
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
