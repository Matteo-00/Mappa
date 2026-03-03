import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modello per un evento della Festa dei Ceri
class EventModel {
  final String id;
  final String time;
  final String title;
  final String description;
  final String location;
  final LatLng coordinates;

  const EventModel({
    required this.id,
    required this.time,
    required this.title,
    required this.description,
    required this.location,
    required this.coordinates,
  });
}
