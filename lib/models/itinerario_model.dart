import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Una tappa di un itinerario.
///
/// Le tappe sono salvate come JSON dentro la colonna `tappe` dell'itinerario,
/// quindi i campi aggiunti dopo (coordinate, approfondimento, curiosità,
/// collegamenti alla Storia) non richiedono nessuna modifica al database: le
/// tappe già salvate restano valide, con quei campi vuoti.
class ItinerarioTappa {
  final String nome;
  final String descrizione;
  final String durata; // es. "45 min"

  /// Posizione della tappa sulla mappa (facoltativa).
  final double? latitudine;
  final double? longitudine;

  /// Testo lungo mostrato nella pagina "Approfondisci".
  final String approfondimento;

  /// Curiosità sulla tappa, mostrate in "Approfondisci".
  final String curiosita;

  /// Id dei contenuti di "Storia di Gubbio" collegati a questa tappa.
  final List<String> storiaIds;

  const ItinerarioTappa({
    required this.nome,
    required this.descrizione,
    required this.durata,
    this.latitudine,
    this.longitudine,
    this.approfondimento = '',
    this.curiosita = '',
    this.storiaIds = const [],
  });

  bool get hasCoordinates => latitudine != null && longitudine != null;

  LatLng? get position =>
      hasCoordinates ? LatLng(latitudine!, longitudine!) : null;

  /// True se c'è qualcosa in più da mostrare nella pagina "Approfondisci".
  bool get hasApprofondimento =>
      approfondimento.trim().isNotEmpty ||
      curiosita.trim().isNotEmpty ||
      storiaIds.isNotEmpty;

  factory ItinerarioTappa.fromJson(Map<String, dynamic> json) {
    return ItinerarioTappa(
      nome: (json['nome'] ?? '') as String,
      descrizione: (json['descrizione'] ?? '') as String,
      durata: (json['durata'] ?? '') as String,
      latitudine: (json['latitudine'] as num?)?.toDouble(),
      longitudine: (json['longitudine'] as num?)?.toDouble(),
      approfondimento: (json['approfondimento'] ?? '') as String,
      curiosita: (json['curiosita'] ?? '') as String,
      storiaIds: (json['storia_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descrizione': descrizione,
      'durata': durata,
      // I campi nuovi si salvano solo se compilati: JSON più pulito.
      if (hasCoordinates) 'latitudine': latitudine,
      if (hasCoordinates) 'longitudine': longitudine,
      if (approfondimento.trim().isNotEmpty) 'approfondimento': approfondimento,
      if (curiosita.trim().isNotEmpty) 'curiosita': curiosita,
      if (storiaIds.isNotEmpty) 'storia_ids': storiaIds,
    };
  }
}

/// Un itinerario consigliato per visitare Gubbio.
class ItinerarioModel {
  final String id;
  final String titolo;
  final String sottotitolo;
  final String descrizione;
  final String durata; // es. "Mezza giornata"
  final String difficolta; // es. "Facile"
  final String tema; // es. "Cultura e storia"
  final IconData icona;
  final String immagineLabel;
  final String? imageUrl;
  final List<ItinerarioTappa> tappe;

  /// Punto di partenza sulla mappa (opzionale: colonne `latitudine` /
  /// `longitudine`, vedi supabase_itinerari_posizione.sql).
  final double? latitudine;
  final double? longitudine;

  /// True se l'itinerario ha il punto di partenza impostato a mano.
  bool get hasStartCoordinates => latitudine != null && longitudine != null;

  /// Punto da usare sulla mappa: quello di partenza se impostato, altrimenti
  /// la prima tappa che ha le coordinate.
  LatLng? get mapPosition {
    if (hasStartCoordinates) return LatLng(latitudine!, longitudine!);
    for (final t in tappe) {
      if (t.hasCoordinates) return t.position;
    }
    return null;
  }

  bool get hasCoordinates => mapPosition != null;

  /// Tappe che hanno una posizione, nell'ordine del percorso.
  List<ItinerarioTappa> get tappeConPosizione =>
      tappe.where((t) => t.hasCoordinates).toList();

  /// Posizione (1-3) nella vetrina della home; null = non in vetrina.
  final int? vetrinaOrdine;

  const ItinerarioModel({
    required this.id,
    required this.titolo,
    required this.sottotitolo,
    required this.descrizione,
    required this.durata,
    required this.difficolta,
    required this.tema,
    this.icona = Icons.map_outlined,
    this.immagineLabel = '',
    this.imageUrl,
    required this.tappe,
    this.latitudine,
    this.longitudine,
    this.vetrinaOrdine,
  });

  /// Crea un itinerario dai dati di Supabase
  factory ItinerarioModel.fromJson(Map<String, dynamic> json) {
    final rawTappe = (json['tappe'] as List?) ?? const [];
    return ItinerarioModel(
      id: json['id'].toString(),
      titolo: (json['titolo'] ?? '') as String,
      sottotitolo: (json['sottotitolo'] ?? '') as String,
      descrizione: (json['descrizione'] ?? '') as String,
      durata: (json['durata'] ?? '') as String,
      difficolta: (json['difficolta'] ?? '') as String,
      tema: (json['tema'] ?? '') as String,
      immagineLabel: (json['titolo'] ?? '') as String,
      imageUrl: json['image_url'] as String?,
      latitudine: (json['latitudine'] as num?)?.toDouble(),
      longitudine: (json['longitudine'] as num?)?.toDouble(),
      vetrinaOrdine: (json['vetrina_ordine'] as num?)?.toInt(),
      tappe: rawTappe
          .map((e) => ItinerarioTappa.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  /// Serializza per l'inserimento su Supabase
  Map<String, dynamic> toJson() {
    return {
      'titolo': titolo,
      'sottotitolo': sottotitolo,
      'descrizione': descrizione,
      'durata': durata,
      'difficolta': difficolta,
      'tema': tema,
      'image_url': imageUrl,
      'tappe': tappe.map((t) => t.toJson()).toList(),
      // Inviate solo se impostate: così il salvataggio funziona anche prima
      // di aver aggiunto le colonne al database.
      if (hasStartCoordinates) 'latitudine': latitudine,
      if (hasStartCoordinates) 'longitudine': longitudine,
    };
  }
}
