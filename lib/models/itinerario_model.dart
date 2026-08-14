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
  final List<ItinerarioTappa> tappe;

  const ItinerarioModel({
    required this.id,
    required this.titolo,
    required this.sottotitolo,
    required this.descrizione,
    required this.durata,
    required this.difficolta,
    required this.tema,
    required this.icona,
    required this.immagineLabel,
    required this.tappe,
  });
}
