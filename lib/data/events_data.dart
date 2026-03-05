import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/event_model.dart';

/// Dati completi degli eventi della Festa dei Ceri
/// 15 Maggio 2026 - Festa dei Ceri principale

/// Eventi del 15 Maggio (Ceri Grandi)
List<EventModel> get15MaggioEvents() {
  // Anno corrente (2026 secondo richiesta)
  final year = 2026;
  final month = 5; // Maggio
  final day = 15;

  return [
    EventModel(
      id: 'evt_1',
      time: '05:30',
      title: 'Tamburi svegliano i Capitani',
      description:
          'I tamburi risuonano per le vie di Gubbio, svegliando i Capitani dei Ceri nel cuore della notte.',
      location: 'Centro storico',
      coordinates: const LatLng(43.35190, 12.57730),
      startTime: DateTime(year, month, day, 5, 30),
      endTime: DateTime(year, month, day, 6, 0),
      category: '15 Maggio',
    ),
    EventModel(
      id: 'evt_2',
      time: '06:00',
      title: 'Campanone',
      description:
          'Il grande campanone della città suona per annunciare l\'inizio della festa.',
      location: 'Palazzo dei Consoli',
      coordinates: const LatLng(43.35200, 12.57750),
      startTime: DateTime(year, month, day, 6, 0),
      endTime: DateTime(year, month, day, 6, 30),
      category: '15 Maggio',
    ),
    EventModel(
      id: 'evt_3',
      time: '07:00',
      title: 'Al Cimitero',
      description:
          'Commemorazione dei ceraioli defunti al cimitero cittadino.',
      location: 'Cimitero di Gubbio',
      coordinates: const LatLng(43.35100, 12.57500),
      startTime: DateTime(year, month, day, 7, 0),
      endTime: DateTime(year, month, day, 8, 0),
      category: '15 Maggio',
    ),
    EventModel(
      id: 'evt_4',
      time: '08:00',
      title: 'Messa ceraioli',
      description:
          'Messa solenne dedicata ai ceraioli nella penombra del mattino.',
      location: 'Duomo di Gubbio',
      coordinates: const LatLng(43.35190, 12.57730),
      startTime: DateTime(year, month, day, 8, 0),
      endTime: DateTime(year, month, day, 9, 0),
      category: '15 Maggio',
    ),
    EventModel(
      id: 'evt_5',
      time: '09:00',
      title: 'Corteo dei Santi',
      description:
          'Processione solenne con le statue dei tre santi protettori di Gubbio.',
      location: 'Dal Duomo a Piazza Grande',
      coordinates: const LatLng(43.35195, 12.57740),
      startTime: DateTime(year, month, day, 9, 0),
      endTime: DateTime(year, month, day, 10, 30),
      category: '15 Maggio',
    ),
    EventModel(
      id: 'evt_6',
      time: '11:30',
      title: 'Alzata dei Ceri',
      description:
          'Il momento più atteso: l\'alzata dei tre Ceri in Piazza Grande. Il boato della folla accoglie i Ceri.',
      location: 'Piazza Grande',
      coordinates: const LatLng(43.35182, 12.57755),
      startTime: DateTime(year, month, day, 11, 30),
      endTime: DateTime(year, month, day, 13, 0),
      category: '15 Maggio',
    ),
    EventModel(
      id: 'evt_7',
      time: '17:00',
      title: 'Processione Sant\'Ubaldo',
      description:
          'Processione religiosa in onore di Sant\'Ubaldo, patrono di Gubbio.',
      location: 'Chiesa di Sant\'Ubaldo',
      coordinates: const LatLng(43.34705, 12.58820),
      startTime: DateTime(year, month, day, 17, 0),
      endTime: DateTime(year, month, day, 18, 0),
      category: '15 Maggio',
    ),
    EventModel(
      id: 'evt_8',
      time: '18:00',
      title: 'Corsa dei Ceri',
      description:
          'La spettacolare corsa dei tre Ceri dal centro storico fino alla Basilica di Sant\'Ubaldo. Adrenalina pura!',
      location: 'Da Piazza Grande a Basilica Sant\'Ubaldo',
      coordinates: const LatLng(43.35000, 12.58230),
      startTime: DateTime(year, month, day, 18, 0),
      endTime: DateTime(year, month, day, 20, 0),
      category: '15 Maggio',
    ),
  ];
}

/// Restituisce il prossimo evento in programma
EventModel? getNextEvent() {
  final events = get15MaggioEvents();
  final now = DateTime.now();
  
  for (final event in events) {
    if (event.startTime.isAfter(now)) {
      return event;
    }
  }
  
  return null; // Nessun evento futuro
}

/// Lista legacy per compatibilità
final List<EventModel> eventsData = get15MaggioEvents();
