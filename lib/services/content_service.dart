import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/bars_data.dart';
import '../data/itinerari_data.dart';
import '../data/restaurants_data.dart';
import '../data/events_data.dart';
import '../models/bar_model.dart';
import '../models/event_model.dart';
import '../models/itinerario_model.dart';
import '../models/restaurant_model.dart';

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

  // -------------------------------------------------- Ristoranti
  static Future<List<RestaurantModel>> fetchRestaurants() async {
    final locals = getGubbioRestaurants();
    try {
      final rows = await _db.from('ristoranti').select().order('created_at');
      final remote = (rows as List)
          .map((e) => RestaurantModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return [...locals, ...remote];
    } catch (_) {
      return locals;
    }
  }

  static Future<void> addRestaurant(RestaurantModel r) async {
    await _db.from('ristoranti').insert(r.toJson());
  }

  static Future<void> deleteRestaurant(String id) async {
    await _db.from('ristoranti').delete().eq('id', id);
  }

  // -------------------------------------------------- Bar
  static Future<List<BarModel>> fetchBars() async {
    final locals = getGubbioBars();
    try {
      final rows = await _db.from('bar').select().order('created_at');
      final remote = (rows as List)
          .map((e) => BarModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return [...locals, ...remote];
    } catch (_) {
      return locals;
    }
  }

  static Future<void> addBar(BarModel b) async {
    await _db.from('bar').insert(b.toJson());
  }

  static Future<void> deleteBar(String id) async {
    await _db.from('bar').delete().eq('id', id);
  }

  // -------------------------------------------------- Eventi
  static Future<List<EventModel>> fetchEvents() async {
    final locals = get15MaggioEvents();
    try {
      final rows = await _db.from('eventi').select().order('data_inizio');
      final remote = (rows as List)
          .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return [...locals, ...remote];
    } catch (_) {
      return locals;
    }
  }

  static Future<void> addEvent(EventModel e) async {
    await _db.from('eventi').insert(e.toJson());
  }

  static Future<void> deleteEvent(String id) async {
    await _db.from('eventi').delete().eq('id', id);
  }

  // -------------------------------------------------- Itinerari
  static Future<List<ItinerarioModel>> fetchItinerari() async {
    const locals = itinerariConsigliati;
    try {
      final rows = await _db.from('itinerari').select().order('created_at');
      final remote = (rows as List)
          .map((e) => ItinerarioModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return [...locals, ...remote];
    } catch (_) {
      return locals;
    }
  }

  static Future<void> addItinerario(ItinerarioModel it) async {
    await _db.from('itinerari').insert(it.toJson());
  }

  static Future<void> deleteItinerario(String id) async {
    await _db.from('itinerari').delete().eq('id', id);
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
