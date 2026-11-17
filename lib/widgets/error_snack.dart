import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

/// Avviso in basso quando qualcosa va storto: un messaggio tradotto e
/// comprensibile ("Qualcosa non ha funzionato, riprova") invece del testo
/// tecnico. Il dettaglio tecnico resta disponibile con il tasto "Dettagli"
/// (utile a chi gestisce l'app) e nel log.
void showErrorSnackBar(BuildContext context, Object error) {
  debugPrint('Errore mostrato all\'utente: $error');
  final l = AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(l.t('errGeneric')),
      backgroundColor: const Color(0xFFB71C1C),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: l.t('errDetails'),
        textColor: Colors.white,
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l.t('errDetails')),
            content: SingleChildScrollView(
              child: SelectableText(error.toString(),
                  style: const TextStyle(fontSize: 13)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l.close),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
