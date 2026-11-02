import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/review_model.dart';

/// Recensioni degli utenti (tabelle `recensioni` e `segnalazioni_recensioni`,
/// script supabase_recensioni_setup.sql).
class ReviewService {
  ReviewService._();

  static SupabaseClient get _db => Supabase.instance.client;

  /// Tipi di scheda recensibili (valori della colonna `entity_type`).
  static const restaurants = 'ristoranti';
  static const bars = 'bar';
  static const hotels = 'hotel';
  static const itineraries = 'itinerari';

  static String? get currentUserId => _db.auth.currentUser?.id;

  /// Recensioni di una scheda, dalla più recente. Lista vuota se la tabella
  /// non esiste ancora o in caso di errore.
  static Future<List<ReviewModel>> fetch(
      String entityType, String entityId) async {
    try {
      final rows = await _db
          .from('recensioni')
          .select()
          .eq('entity_type', entityType)
          .eq('entity_id', entityId)
          .order('created_at', ascending: false);
      return (rows as List)
          .map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('ReviewService.fetch: errore $e');
      return [];
    }
  }

  /// Crea o aggiorna la recensione dell'utente collegato.
  static Future<void> save({
    required String entityType,
    required String entityId,
    required int stars,
    required String comment,
    String? existingId,
  }) async {
    final data = {'stelle': stars, 'commento': comment.trim()};
    if (existingId != null) {
      await _db.from('recensioni').update(data).eq('id', existingId);
    } else {
      await _db.from('recensioni').insert({
        ...data,
        'entity_type': entityType,
        'entity_id': entityId,
      });
    }
  }

  /// Elimina una recensione (la propria, oppure qualsiasi se admin).
  static Future<void> delete(String id) async {
    await _db.from('recensioni').delete().eq('id', id);
  }

  /// Segnala una recensione agli admin. Una seconda segnalazione della
  /// stessa persona viene ignorata.
  static Future<void> report(String reviewId, String reason) async {
    try {
      await _db.from('segnalazioni_recensioni').insert({
        'recensione_id': reviewId,
        'motivo': reason.trim(),
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow; // 23505 = già segnalata
    }
  }

  /// Solo admin: recensioni segnalate, con i motivi, dalla più segnalata.
  static Future<List<ReportedReview>> fetchReported() async {
    final rows = await _db
        .from('segnalazioni_recensioni')
        .select('motivo, recensioni(*)')
        .order('created_at', ascending: false);
    final byReview = <String, ReportedReview>{};
    for (final r in rows as List) {
      final row = Map<String, dynamic>.from(r as Map);
      final rev = row['recensioni'];
      if (rev is! Map) continue;
      final review = ReviewModel.fromJson(Map<String, dynamic>.from(rev));
      final item = byReview.putIfAbsent(
        review.id,
        () => ReportedReview(
          reviewId: review.id,
          entityType: rev['entity_type'].toString(),
          entityId: rev['entity_id'].toString(),
          review: review,
          reasons: [],
        ),
      );
      final reason = (row['motivo'] ?? '').toString().trim();
      item.reasons.add(reason);
    }
    return byReview.values.toList()
      ..sort((a, b) => b.reasons.length.compareTo(a.reasons.length));
  }

  /// Solo admin: la recensione va bene, si tolgono le sue segnalazioni.
  static Future<void> dismissReports(String reviewId) async {
    await _db
        .from('segnalazioni_recensioni')
        .delete()
        .eq('recensione_id', reviewId);
  }

  // ---------------------------------------------- Utenti bloccati
  // Chi blocca un autore non vede più le sue recensioni (solo su questo
  // dispositivo).

  static const _blockedKey = 'blocked_review_authors_v1';

  static Future<Set<String>> blockedAuthors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_blockedKey) ?? const []).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> blockAuthor(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_blockedKey) ?? [];
    if (!list.contains(userId)) {
      await prefs.setStringList(_blockedKey, [...list, userId]);
    }
  }
}
