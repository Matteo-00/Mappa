import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Stato di un evento
enum EventStatus {
  past, // Evento passato
  current, // Evento in corso
  upcoming, // Evento futuro
}

/// Modello per un evento della Festa dei Ceri
class EventModel {
  final String id;
  final String time; // Orario visualizzato (es: "05:30")
  final String title;
  final String description;
  final String location;
  final LatLng coordinates;
  final DateTime startTime; // Orario di inizio effettivo
  final DateTime endTime; // Orario di fine effettivo
  final String? imageUrl; // URL immagine evento (opzionale)
  final String category; // "15 Maggio", "19 Maggio", "2 Giugno"

  const EventModel({
    required this.id,
    required this.time,
    required this.title,
    required this.description,
    required this.location,
    required this.coordinates,
    required this.startTime,
    required this.endTime,
    this.imageUrl,
    this.category = '15 Maggio',
  });

  /// Determina lo stato dell'evento in base all'orario attuale
  EventStatus getStatus() {
    final now = DateTime.now();
    
    if (now.isAfter(endTime)) {
      return EventStatus.past;
    } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
      return EventStatus.current;
    } else {
      return EventStatus.upcoming;
    }
  }

  /// Verifica se l'evento è oggi
  bool isToday() {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }
}
