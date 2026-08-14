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
  final String? phoneNumber;
  final String? website;

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
    this.phoneNumber,
    this.website,
  });

  /// Crea un evento dai dati di Supabase
  factory EventModel.fromJson(Map<String, dynamic> json) {
    final start = DateTime.parse(json['data_inizio'] as String).toLocal();
    final end = DateTime.parse(json['data_fine'] as String).toLocal();
    final hh = start.hour.toString().padLeft(2, '0');
    final mm = start.minute.toString().padLeft(2, '0');
    return EventModel(
      id: json['id'].toString(),
      time: '$hh:$mm',
      title: (json['titolo'] ?? '') as String,
      description: (json['descrizione'] ?? '') as String,
      location: (json['luogo'] ?? '') as String,
      coordinates: LatLng(
        (json['latitudine'] as num?)?.toDouble() ?? 43.3519,
        (json['longitudine'] as num?)?.toDouble() ?? 12.5773,
      ),
      startTime: start,
      endTime: end,
      imageUrl: json['image_url'] as String?,
      category: (json['categoria'] ?? 'Eventi') as String,
      phoneNumber: json['telefono'] as String?,
      website: json['sito_web'] as String?,
    );
  }

  /// Serializza per l'inserimento su Supabase
  Map<String, dynamic> toJson() {
    return {
      'titolo': title,
      'descrizione': description,
      'luogo': location,
      'latitudine': coordinates.latitude,
      'longitudine': coordinates.longitude,
      'image_url': imageUrl,
      'telefono': phoneNumber,
      'sito_web': website,
      'data_inizio': startTime.toUtc().toIso8601String(),
      'data_fine': endTime.toUtc().toIso8601String(),
      'categoria': category,
    };
  }

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
