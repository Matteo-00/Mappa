import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/itinerario_model.dart';
import '../../services/content_service.dart';
import '../../services/language_service.dart';
import 'add_itinerario_page.dart';

/// Apre il form di modifica di un itinerario (titoli, descrizioni, posizione,
/// tappe, approfondimenti, collegamenti alla Storia: tutto) e, se l'admin ha
/// salvato, restituisce l'itinerario aggiornato nella lingua corrente.
/// Restituisce `null` se non è stato salvato nulla.
///
/// Il form lavora sempre sul **testo originale in italiano**, anche se l'app è
/// in un'altra lingua: altrimenti salvando si sovrascriverebbe l'italiano con
/// una traduzione. [stopIndex] porta direttamente alla tappa indicata.
Future<ItinerarioModel?> editItinerarioFlow(
  BuildContext context,
  ItinerarioModel itinerario, {
  int? stopIndex,
}) async {
  final original =
      await ContentService.fetchItinerarioById(itinerario.id) ?? itinerario;
  if (!context.mounted) return null;

  final saved = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => AddItinerarioPage(
        editItinerario: original,
        initialStopIndex: stopIndex,
      ),
    ),
  );
  if (saved != true || !context.mounted) return null;

  final lang = context.read<LanguageService>().currentLanguageCode;
  return ContentService.fetchItinerarioById(itinerario.id, languageCode: lang);
}
