import 'package:flutter/material.dart';

/// Una sezione di contenuto all'interno di un capitolo storico.
/// Può avere un sottotitolo, un testo e, opzionalmente, uno spazio
/// riservato a un'immagine (placeholder) da inserire in futuro.
class StoriaSezione {
  final String? sottotitolo;
  final String testo;
  final bool conImmagine;
  final String? immagineLabel;

  const StoriaSezione({
    this.sottotitolo,
    required this.testo,
    this.conImmagine = false,
    this.immagineLabel,
  });
}

/// Un capitolo della storia di Gubbio (un'epoca / una tappa del viaggio).
class StoriaCapitolo {
  final String id;
  final String numero; // es. "01"
  final String epoca; // es. "III – I secolo a.C."
  final String epocaBreve; // etichetta per la timeline, es. "Umbri"
  final String titolo;
  final String sottotitolo;
  final String introduzione;
  final IconData icona;
  final String immagineHeroLabel;
  final List<StoriaSezione> sezioni;
  final String? curiosita;
  final String? cosaVedeOggi;

  const StoriaCapitolo({
    required this.id,
    required this.numero,
    required this.epoca,
    required this.epocaBreve,
    required this.titolo,
    required this.sottotitolo,
    required this.introduzione,
    required this.icona,
    required this.immagineHeroLabel,
    required this.sezioni,
    this.curiosita,
    this.cosaVedeOggi,
  });
}
