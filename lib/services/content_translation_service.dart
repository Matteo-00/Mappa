import 'package:supabase_flutter/supabase_flutter.dart';

/// Legge le traduzioni salvate in `content_translations` e le applica ai
/// dati originali italiani, con fallback automatico: se per un campo non
/// esiste ancora una traduzione, resta il valore italiano originale.
///
/// Usato dai repository/service di lettura dei contenuti (ristoranti, bar,
/// eventi, itinerari, storia) prima di costruire i modelli Flutter, così
/// che tutta la logica di traduzione resta in un unico punto.
class ContentTranslationService {
  static SupabaseClient get _db => Supabase.instance.client;

  /// Recupera le traduzioni per un insieme di id di una stessa entità e
  /// lingua. Ritorna una mappa entityId -> contenuto tradotto (JSON).
  /// Per l'italiano ritorna sempre una mappa vuota (nessuna traduzione da
  /// applicare: si usano direttamente i dati originali).
  static Future<Map<String, Map<String, dynamic>>> fetchTranslations({
    required String entityType,
    required List<String> entityIds,
    required String languageCode,
  }) async {
    if (languageCode == 'it' || entityIds.isEmpty) return {};

    try {
      final rows = await _db
          .from('content_translations')
          .select()
          .eq('entity_type', entityType)
          .eq('language_code', languageCode)
          .inFilter('entity_id', entityIds);

      final map = <String, Map<String, dynamic>>{};
      for (final r in (rows as List)) {
        final row = Map<String, dynamic>.from(r as Map);
        final content = row['content'];
        final id = row['entity_id']?.toString();
        if (id != null && content is Map) {
          map[id] = Map<String, dynamic>.from(content);
        }
      }
      return map;
    } catch (_) {
      // Traduzione non disponibile: si continuerà a usare l'italiano.
      return {};
    }
  }

  /// Applica una traduzione (se presente) sopra i dati JSON originali,
  /// sostituendo solo i campi testuali tradotti e non vuoti. Tutti gli
  /// altri campi (id, immagini, coordinate, telefono, sito web, rating,
  /// ordinamento, ecc.) restano quelli della tabella originale.
  static Map<String, dynamic> applyTranslation(
    Map<String, dynamic> original,
    Map<String, dynamic>? translation,
  ) {
    if (translation == null || translation.isEmpty) return original;

    final merged = Map<String, dynamic>.from(original);
    for (final entry in translation.entries) {
      final value = entry.value;
      final isEmptyText = value is String && value.trim().isEmpty;
      final isEmptyList = value is List && value.isEmpty;
      if (value != null && !isEmptyText && !isEmptyList) {
        merged[entry.key] = value;
      }
    }
    return merged;
  }
}
