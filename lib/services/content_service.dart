import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/itinerari_data.dart';
import '../data/events_data.dart';
import '../models/bar_model.dart';
import '../models/event_model.dart';
import '../models/itinerario_model.dart';
import '../models/restaurant_model.dart';
import '../models/storia_model.dart';
import 'content_translation_service.dart';
import 'translation_service.dart';

/// Servizio per leggere e scrivere i contenuti (ristoranti, bar, eventi,
/// itinerari) su Supabase. In lettura unisce i dati locali di base con quelli
/// aggiunti dagli amministratori; in scrittura richiede i permessi admin
/// (gestiti dalle policy RLS su Supabase).
class ContentService {
  static SupabaseClient get _db => Supabase.instance.client;
  static const String imageBucket = 'immagini';

  /// True se l'id proviene da Supabase (UUID) e non dai dati locali di base.
  /// Solo gli elementi remoti possono essere eliminati.
  static bool isRemoteId(String id) => id.contains('-');

  /// Richiede la traduzione di un'entità dopo un insert/update italiano
  /// già andato a buon fine. Non deve MAI propagare eccezioni: il record
  /// italiano resta salvato anche se la traduzione fallisce o non risponde,
  /// e potrà essere ritentata in seguito (es. dal tool di migrazione).
  static Future<void> _translateSafely({
    required String entityType,
    required String entityId,
  }) async {
    try {
      await TranslationService.translateEntity(
        entityType: entityType,
        entityId: entityId,
      );
    } catch (_) {
      // Traduzione non disponibile ora: il contenuto italiano resta valido.
    }
  }

  // -------------------------------------------------- Ristoranti
  // Solo dati reali inseriti dai master su Supabase (niente dati di prova).
  /// [languageCode]: 'it' legge i dati originali; per en/fr/de applica la
  /// traduzione da `content_translations`, con fallback all'italiano se manca.
  static Future<List<RestaurantModel>> fetchRestaurants({
    String languageCode = 'it',
  }) async {
    try {
      final rows = await _db.from('ristoranti').select().order('created_at');
      final originals = (rows as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final translations = await ContentTranslationService.fetchTranslations(
        entityType: 'ristoranti',
        entityIds: originals.map((e) => e['id'].toString()).toList(),
        languageCode: languageCode,
      );
      return originals
          .map((e) => RestaurantModel.fromJson(ContentTranslationService
              .applyTranslation(e, translations[e['id'].toString()])))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addRestaurant(RestaurantModel r) async {
    final inserted = await _db
        .from('ristoranti')
        .insert(r.toJson())
        .select()
        .single();
    await _translateSafely(
      entityType: 'ristoranti',
      entityId: inserted['id'].toString(),
    );
  }

  static Future<void> updateRestaurant(RestaurantModel r) async {
    await _db.from('ristoranti').update(r.toJson()).eq('id', r.id);
    await _translateSafely(entityType: 'ristoranti', entityId: r.id);
  }

  static Future<void> deleteRestaurant(String id) async {
    await _db.from('ristoranti').delete().eq('id', id);
  }

  // -------------------------------------------------- Bar
  // Solo dati reali inseriti dai master su Supabase (niente dati di prova).
  static Future<List<BarModel>> fetchBars({String languageCode = 'it'}) async {
    try {
      final rows = await _db.from('bar').select().order('created_at');
      final originals = (rows as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final translations = await ContentTranslationService.fetchTranslations(
        entityType: 'bar',
        entityIds: originals.map((e) => e['id'].toString()).toList(),
        languageCode: languageCode,
      );
      return originals
          .map((e) => BarModel.fromJson(ContentTranslationService
              .applyTranslation(e, translations[e['id'].toString()])))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addBar(BarModel b) async {
    final inserted =
        await _db.from('bar').insert(b.toJson()).select().single();
    await _translateSafely(
      entityType: 'bar',
      entityId: inserted['id'].toString(),
    );
  }

  static Future<void> updateBar(BarModel b) async {
    await _db.from('bar').update(b.toJson()).eq('id', b.id);
    await _translateSafely(entityType: 'bar', entityId: b.id);
  }

  static Future<void> deleteBar(String id) async {
    await _db.from('bar').delete().eq('id', id);
  }

  // -------------------------------------------------- Eventi
  static Future<List<EventModel>> fetchEvents({String languageCode = 'it'}) async {
    final locals = get15MaggioEvents();
    try {
      final rows = await _db.from('eventi').select().order('data_inizio');
      final originals = (rows as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final translations = await ContentTranslationService.fetchTranslations(
        entityType: 'eventi',
        entityIds: originals.map((e) => e['id'].toString()).toList(),
        languageCode: languageCode,
      );
      final remote = originals
          .map((e) => EventModel.fromJson(ContentTranslationService
              .applyTranslation(e, translations[e['id'].toString()])))
          .toList();
      // Nella sezione eventi generica mostriamo solo 2 eventi di esempio: il
      // programma completo della Festa dei Ceri resta nella sua pagina dedicata.
      return [...locals.take(2), ...remote];
    } catch (_) {
      return locals.take(2).toList();
    }
  }

  static Future<void> addEvent(EventModel e) async {
    final inserted =
        await _db.from('eventi').insert(e.toJson()).select().single();
    await _translateSafely(
      entityType: 'eventi',
      entityId: inserted['id'].toString(),
    );
  }

  static Future<void> updateEvent(EventModel e) async {
    await _db.from('eventi').update(e.toJson()).eq('id', e.id);
    await _translateSafely(entityType: 'eventi', entityId: e.id);
  }

  static Future<void> deleteEvent(String id) async {
    await _db.from('eventi').delete().eq('id', id);
  }

  // -------------------------------------------------- Itinerari
  static Future<List<ItinerarioModel>> fetchItinerari({
    String languageCode = 'it',
  }) async {
    const locals = itinerariConsigliati;
    try {
      final rows = await _db.from('itinerari').select().order('created_at');
      final originals = (rows as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final translations = await ContentTranslationService.fetchTranslations(
        entityType: 'itinerari',
        entityIds: originals.map((e) => e['id'].toString()).toList(),
        languageCode: languageCode,
      );
      final remote = originals
          .map((e) => ItinerarioModel.fromJson(ContentTranslationService
              .applyTranslation(e, translations[e['id'].toString()])))
          .toList();
      return [...locals, ...remote];
    } catch (_) {
      return locals;
    }
  }

  static Future<void> addItinerario(ItinerarioModel it) async {
    final inserted =
        await _db.from('itinerari').insert(it.toJson()).select().single();
    await _translateSafely(
      entityType: 'itinerari',
      entityId: inserted['id'].toString(),
    );
  }

  static Future<void> updateItinerario(ItinerarioModel it) async {
    await _db.from('itinerari').update(it.toJson()).eq('id', it.id);
    await _translateSafely(entityType: 'itinerari', entityId: it.id);
  }

  static Future<void> deleteItinerario(String id) async {
    await _db.from('itinerari').delete().eq('id', id);
  }

  // -------------------------------------------------- Storia di Gubbio
  static Future<List<StoriaEpoca>> fetchStoriaEpoche({
    String languageCode = 'it',
  }) async {
    try {
      final rows =
          await _db.from('storia_epoche').select().order('sort_order');
      final originals = (rows as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final translations = await ContentTranslationService.fetchTranslations(
        entityType: 'storia_epoche',
        entityIds: originals.map((e) => e['id'].toString()).toList(),
        languageCode: languageCode,
      );
      return originals
          .map((e) => StoriaEpoca.fromJson(ContentTranslationService
              .applyTranslation(e, translations[e['id'].toString()])))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<StoriaContenuto>> fetchStoriaContenuti({
    String languageCode = 'it',
  }) async {
    try {
      final rows =
          await _db.from('storia_contenuti').select().order('sort_order');
      final originals = (rows as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final translations = await ContentTranslationService.fetchTranslations(
        entityType: 'storia_contenuti',
        entityIds: originals.map((e) => e['id'].toString()).toList(),
        languageCode: languageCode,
      );
      return originals
          .map((e) => StoriaContenuto.fromJson(ContentTranslationService
              .applyTranslation(e, translations[e['id'].toString()])))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addStoriaContenuto(StoriaContenuto c) async {
    final inserted = await _db
        .from('storia_contenuti')
        .insert(c.toJson())
        .select()
        .single();
    await _translateSafely(
      entityType: 'storia_contenuti',
      entityId: inserted['id'].toString(),
    );
  }

  static Future<void> updateStoriaContenuto(StoriaContenuto c) async {
    await _db.from('storia_contenuti').update(c.toJson()).eq('id', c.id);
    await _translateSafely(entityType: 'storia_contenuti', entityId: c.id);
  }

  static Future<void> deleteStoriaContenuto(String id) async {
    await _db.from('storia_contenuti').delete().eq('id', id);
  }

  // -------------------------------------------------- Immagini
  /// Carica un'immagine sul bucket Storage e restituisce l'URL pubblico.
  static Future<String> uploadImage(
    Uint8List bytes, {
    required String folder,
    required String fileName,
  }) async {
    final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
    final path =
        '$folder/${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _db.storage.from(imageBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$ext',
            upsert: true,
          ),
        );
    return _db.storage.from(imageBucket).getPublicUrl(path);
  }
}
