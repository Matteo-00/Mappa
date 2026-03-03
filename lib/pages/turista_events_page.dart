import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/events_data.dart';
import '../widgets/event_card.dart';
import '../services/location_service.dart';

/// Pagina che mostra la struttura della giornata per i turisti
class TuristaEventsPage extends StatefulWidget {
  const TuristaEventsPage({super.key});

  @override
  State<TuristaEventsPage> createState() => _TuristaEventsPageState();
}

class _TuristaEventsPageState extends State<TuristaEventsPage> {
  final LocationService _locationService = LocationService();
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() => _currentLocation = location);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('La Giornata'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Come viene strutturata\nla giornata',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[900],
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '15 Maggio — Festa dei Ceri',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Segui il programma della giornata, esplora i luoghi '
                  'e vivi l\'emozione della tradizione.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Lista eventi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              itemCount: eventsData.length,
              itemBuilder: (context, index) {
                final event = eventsData[index];
                return EventCard(
                  event: event,
                  onShowOnMap: () => _showOnMap(event.coordinates),
                  onGetDirections: () => _getDirections(event.coordinates),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Mostra la posizione sulla mappa
  void _showOnMap(LatLng coordinates) {
    Navigator.pop(context);
    // La mappa si aggiorna automaticamente con i marker
  }

  /// Avvia navigazione verso l'evento
  Future<void> _getDirections(LatLng destination) async {
    // Se non abbiamo la posizione, proviamo a ottenerla
    if (_currentLocation == null) {
      _currentLocation = await _locationService.getCurrentLocation();
    }

    if (_currentLocation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile ottenere la posizione'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&travelmode=walking',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire la navigazione'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
