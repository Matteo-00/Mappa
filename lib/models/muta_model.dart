import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modello per una muta lungo il percorso dei Ceri
/// Contiene la struttura completa della barella con 11 ceraioli
class MutaModel {
  final String id;
  final String name;
  final String zone;
  final String info;
  final LatLng coordinates;
  
  // Struttura muta
  final String capoMuta;
  final String capocorsa; // 1 ceraiolo davanti tra le stanghe
  final List<String> esterniSinistra; // 4 ceraioli a sinistra
  final List<String> esterniDestra; // 4 ceraioli a destra
  final List<String> interniPosteriori; // 2 ceraioli dietro tra le stanghe

  const MutaModel({
    required this.id,
    required this.name,
    required this.zone,
    required this.info,
    required this.coordinates,
    required this.capoMuta,
    required this.capocorsa,
    required this.esterniSinistra,
    required this.esterniDestra,
    required this.interniPosteriori,
  });

  /// Restituisce tutti i ceraioli della muta (11 totali)
  List<String> getAllCeraioli() {
    return [
      capocorsa,
      ...esterniSinistra,
      ...esterniDestra,
      ...interniPosteriori,
    ];
  }

  /// Crea una copia della muta con nuovi valori
  MutaModel copyWith({
    String? id,
    String? name,
    String? zone,
    String? info,
    LatLng? coordinates,
    String? capoMuta,
    String? capocorsa,
    List<String>? esterniSinistra,
    List<String>? esterniDestra,
    List<String>? interniPosteriori,
  }) {
    return MutaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      zone: zone ?? this.zone,
      info: info ?? this.info,
      coordinates: coordinates ?? this.coordinates,
      capoMuta: capoMuta ?? this.capoMuta,
      capocorsa: capocorsa ?? this.capocorsa,
      esterniSinistra: esterniSinistra ?? this.esterniSinistra,
      esterniDestra: esterniDestra ?? this.esterniDestra,
      interniPosteriori: interniPosteriori ?? this.interniPosteriori,
    );
  }
}
