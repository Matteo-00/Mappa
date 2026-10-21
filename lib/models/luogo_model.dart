import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../utils/geo.dart';

/// I tipi di luogo contenuti nella tabella `luoghi`.
enum LuogoTipo { chiesa, museo, negozio, parcheggio }

extension LuogoTipoInfo on LuogoTipo {
  /// Valore salvato nella colonna `tipo` (e identificativo del punto sulla
  /// mappa, vedi `MapKind`).
  String get db => name;

  static LuogoTipo? parse(String? value) {
    for (final t in LuogoTipo.values) {
      if (t.name == value) return t;
    }
    return null;
  }

  IconData get icon {
    switch (this) {
      case LuogoTipo.chiesa:
        return Icons.church_outlined;
      case LuogoTipo.museo:
        return Icons.museum_outlined;
      case LuogoTipo.negozio:
        return Icons.storefront_outlined;
      case LuogoTipo.parcheggio:
        return Icons.local_parking_rounded;
    }
  }

  /// Colore dei punti sulla mappa (e nella legenda).
  Color get color {
    switch (this) {
      case LuogoTipo.chiesa:
        return const Color(0xFF3F51B5);
      case LuogoTipo.museo:
        return const Color(0xFF00897B);
      case LuogoTipo.negozio:
        return const Color(0xFFC2185B);
      case LuogoTipo.parcheggio:
        return const Color(0xFF546E7A);
    }
  }

  /// Tonalità del marker di Google Maps, vicina a [color].
  double get hue {
    switch (this) {
      case LuogoTipo.chiesa:
        return BitmapDescriptor.hueBlue;
      case LuogoTipo.museo:
        return BitmapDescriptor.hueCyan;
      case LuogoTipo.negozio:
        return BitmapDescriptor.hueMagenta;
      case LuogoTipo.parcheggio:
        return BitmapDescriptor.hueAzure;
    }
  }

  /// Solo i negozi hanno la valutazione in stelle.
  bool get hasRating => this == LuogoTipo.negozio;

  /// Chiese e musei si collegano ai contenuti di "Storia di Gubbio".
  bool get hasStoria =>
      this == LuogoTipo.chiesa || this == LuogoTipo.museo;

  /// I parcheggi non hanno tag, telefono e sito web.
  bool get hasContacts => this != LuogoTipo.parcheggio;

  /// Chiavi di `AppLocalizations`.
  String get navKey => 'nav_$name'; // titolo pagina / voce di menu / chip mappa
  String get kindKey => 'kind_$name'; // nome al singolare (es. "Chiesa")
  String get searchKey => 'search_$name';
  String get emptyKey => 'empty_$name';
  String get deletedKey => 'deleted_$name';
}

/// Una chiesa, un museo, un negozio o un parcheggio.
class LuogoModel {
  final String id;
  final LuogoTipo tipo;
  final String name;
  final String description;
  final String address;
  final LatLng coordinates;
  final String? imageUrl;
  final String? phoneNumber;
  final String? website;
  final List<String> tags;

  /// Valutazione da 1 a 5 (solo negozi).
  final double? rating;

  /// Contenuti di "Storia di Gubbio" collegati (solo chiese e musei).
  final List<String> storiaIds;

  const LuogoModel({
    required this.id,
    required this.tipo,
    required this.name,
    required this.description,
    required this.address,
    required this.coordinates,
    this.imageUrl,
    this.phoneNumber,
    this.website,
    this.tags = const [],
    this.rating,
    this.storiaIds = const [],
  });

  factory LuogoModel.fromJson(Map<String, dynamic> json) {
    return LuogoModel(
      id: json['id'].toString(),
      tipo: LuogoTipoInfo.parse(json['tipo'] as String?) ?? LuogoTipo.chiesa,
      name: (json['nome'] ?? '') as String,
      description: (json['descrizione'] ?? '') as String,
      address: (json['indirizzo'] ?? '') as String,
      coordinates: LatLng(
        (json['latitudine'] as num?)?.toDouble() ?? 43.3519,
        (json['longitudine'] as num?)?.toDouble() ?? 12.5773,
      ),
      imageUrl: json['image_url'] as String?,
      phoneNumber: json['telefono'] as String?,
      website: json['sito_web'] as String?,
      tags:
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      rating: (json['rating'] as num?)?.toDouble(),
      storiaIds: (json['storia_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Serializza per l'inserimento su Supabase.
  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo.db,
      'nome': name,
      'descrizione': description,
      'indirizzo': address,
      'latitudine': coordinates.latitude,
      'longitudine': coordinates.longitude,
      'image_url': imageUrl,
      'telefono': phoneNumber,
      'sito_web': website,
      'tags': tags,
      'rating': rating,
      'storia_ids': storiaIds,
    };
  }

  /// Distanza in metri, in linea d'aria, da una posizione.
  double calculateDistance(LatLng from) => distanceMeters(from, coordinates);
}
