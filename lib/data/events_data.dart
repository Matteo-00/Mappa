import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/event_model.dart';

/// Dati demo degli eventi della Festa dei Ceri
final List<EventModel> eventsData = [
  EventModel(
    id: '1',
    time: '08:00',
    title: 'Messa Solenne dei Ceraioli',
    description:
        'Celebrazione nella penombra del mattino, tra tradizione e silenzio carico di attesa.',
    location: 'Duomo di Gubbio',
    coordinates: LatLng(43.35190, 12.57730),
  ),
  EventModel(
    id: '2',
    time: '11:30',
    title: 'Alzata dei Ceri',
    description:
        'Il momento simbolico che accende l\'emozione collettiva. Il boato della piazza segna l\'inizio della giornata.',
    location: 'Piazza Grande',
    coordinates: LatLng(43.35182, 12.57755),
  ),
  EventModel(
    id: '3',
    time: '18:00',
    title: 'Corsa dei Ceri',
    description:
        'Il cuore pulsante della festa. Adrenalina, tradizione, orgoglio.',
    location: 'Percorso storico fino al Monte Ingino',
    coordinates: LatLng(43.35000, 12.58230),
  ),
];
