import 'package:flutter/material.dart';

/// Una tappa di un itinerario.
class ItinerarioTappa {
  final String nome;
  final String descrizione;
  final String durata; // es. "45 min"

  const ItinerarioTappa({
    required this.nome,
    required this.descrizione,
    required this.durata,
  });

  factory ItinerarioTappa.fromJson(Map<String, dynamic> json) {
    return ItinerarioTappa(
      nome: (json['nome'] ?? '') as String,
      descrizione: (json['descrizione'] ?? '') as String,
      durata: (json['durata'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'descrizione': descrizione,
      'durata': durata,
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
    };
  }
}
