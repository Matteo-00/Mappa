import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Esito della chiamata a `translate-content`.
enum TranslationOutcome { success, partial, unauthorized, error }

class TranslationResult {
  final TranslationOutcome outcome;
  final String? message;

  const TranslationResult(this.outcome, [this.message]);

  bool get isOk => outcome == TranslationOutcome.success;
}

/// Servizio centrale per richiedere la traduzione automatica (EN/FR/DE) di
/// un contenuto italiano appena creato o modificato da un admin.
///
/// Chiama sempre la stessa Edge Function Supabase `translate-content`, che
/// si occupa di generare e salvare le traduzioni in `content_translations`.
/// Non deve mai essere duplicata logica di traduzione nelle singole
/// schermate: tutte devono passare da qui.
class TranslationService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Richiede la traduzione di un'entità appena salvata/aggiornata in
  /// italiano. Non lancia eccezioni: se la traduzione fallisce, il contenuto
  /// italiano resta comunque salvato e la traduzione potrà essere ritentata.
  static Future<TranslationResult> translateEntity({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'translate-content',
        body: {
          'entity_type': entityType,
          'entity_id': entityId,
        },
      );

      final status = res.status;
      final data = res.data;

      if (status == 401 || status == 403) {
        return const TranslationResult(
          TranslationOutcome.unauthorized,
          'Utente non autorizzato a richiedere la traduzione',
        );
      }

      if (status == 200) {
        return const TranslationResult(TranslationOutcome.success);
      }

      if (status == 207) {
        return TranslationResult(
          TranslationOutcome.partial,
          'Traduzione parzialmente riuscita: ${data?['results']}',
        );
      }

      return TranslationResult(
        TranslationOutcome.error,
        data?['error']?.toString() ?? 'Errore sconosciuto (status $status)',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TranslationService.translateEntity error: $e');
      }
      return TranslationResult(
        TranslationOutcome.error,
        'Traduzione temporaneamente non disponibile: $e',
      );
    }
  }
}
