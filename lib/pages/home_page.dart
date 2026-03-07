import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../models/user_mode.dart';
import '../models/event_model.dart';
import '../data/events_data.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/welcome_popup.dart';
import 'program_page.dart';
import 'mute_list_page.dart';

/// HomePage ridisegnata con UI moderna ed elegante
/// Header fisso + Mappa + Eventi + Footer fisso
class HomePage extends StatefulWidget {
  final String? initialEventId; // ID dell'evento da mostrare inizialmente

  const HomePage({super.key, this.initialEventId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  
  LatLng? _currentLocation;
  int _selectedIndex = 0;
  bool _showWelcomePopup = true; // Mostra popup di benvenuto
  String? _selectedEventId; // ID dell'evento selezionato per marker rosso
  EventModel? _selectedEventForSheet; // Evento per bottom sheet
  bool _isFabMenuOpen = false; // Menu FAB espanso
  bool _isNavigationMode = false; // Modalità navigazione attiva

  // Centro iniziale: Gubbio, Piazza Grande
  static const LatLng _centerGubbio = LatLng(43.35190, 12.57730);

  @override
  void initState() {
    super.initState();
    // Se c'è un evento iniziale, mostralo
    if (widget.initialEventId != null) {
      final events = get15MaggioEvents();
      final event = events.firstWhere(
        (e) => e.id == widget.initialEventId,
        orElse: () => events.first,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedEventId = event.id;
          _selectedEventForSheet = event;
          _showWelcomePopup = false; // Non mostrare il popup se viene da un evento
        });
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: event.coordinates,
              zoom: 17,
            ),
          ),
        );
      });
    }
  }

  // Percorso ufficiale dei Ceri
  final List<LatLng> _routeCoordinates = const [
    LatLng(43.35190, 12.57730), // Piazza Grande
    LatLng(43.35182, 12.57755),
    LatLng(43.35174, 12.57780),
    LatLng(43.35165, 12.57805),
    LatLng(43.35155, 12.57830),
    LatLng(43.35145, 12.57855),
    LatLng(43.35135, 12.57880),
    LatLng(43.35125, 12.57910),
    LatLng(43.35115, 12.57940),
    LatLng(43.35105, 12.57975),
    LatLng(43.35095, 12.58010),
    LatLng(43.35085, 12.58045),
    LatLng(43.35070, 12.58080),
    LatLng(43.35055, 12.58115),
    LatLng(43.35040, 12.58150),
    LatLng(43.35020, 12.58190),
    LatLng(43.35000, 12.58230),
    LatLng(43.34980, 12.58270),
    LatLng(43.34960, 12.58310),
    LatLng(43.34940, 12.58350),
    LatLng(43.34920, 12.58400),
    LatLng(43.34900, 12.58450),
    LatLng(43.34880, 12.58500),
    LatLng(43.34860, 12.58550),
    LatLng(43.34840, 12.58600),
    LatLng(43.34820, 12.58650),
    LatLng(43.34800, 12.58700),
    LatLng(43.34780, 12.58740),
    LatLng(43.34760, 12.58770),
    LatLng(43.34740, 12.58790),
    LatLng(43.34720, 12.58805),
    LatLng(43.34705, 12.58820), // Basilica Sant'Ubaldo
  ];

  Set<Polyline> get _polylines => {
        Polyline(
          polylineId: const PolylineId('ceri_route'),
          points: _routeCoordinates,
          color: const Color(0xFFB22222), // Rosso principale
          width: 5,
          geodesic: true,
        ),
      };

  Set<Marker> get _markers {
    final markers = <Marker>{};
    
    // Marker per eventi principali
    final events = get15MaggioEvents();
    for (final event in events) {
      // Marker rosso se selezionato, blu altrimenti
      final isSelected = _selectedEventId == event.id;
      markers.add(
        Marker(
          markerId: MarkerId(event.id),
          position: event.coordinates,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: event.title,
            snippet: event.time,
          ),
          onTap: () {
            setState(() {
              _selectedEventId = event.id;
              _selectedEventForSheet = event;
            });
          },
        ),
      );
    }

    // Marker blu per posizione utente
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(210), // Blu #2F80ED
          infoWindow: const InfoWindow(title: 'La tua posizione'),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final isCeraiolo = authService.userMode == UserMode.ceraiolo;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: const CustomHeader(),
      body: Stack(
        children: [
          // Contenuto principale
          _buildMainContent(),
          // Bottom sheet per evento selezionato
          if (_selectedEventForSheet != null && !_showWelcomePopup)
            _buildEventBottomSheet(_selectedEventForSheet!),
          // Popup di benvenuto
          if (_showWelcomePopup) _buildWelcomePopup(),
          // Menu espandibile posizione
          if (_isFabMenuOpen) _buildFabMenu(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) => _onBottomNavTap(index, isCeraiolo),
        showMute: isCeraiolo,
        onLocationMenuTap: () {
          setState(() {
            _isFabMenuOpen = !_isFabMenuOpen;
          });
        },
        isLocationMenuOpen: _isFabMenuOpen,
      ),
    );
  }

  /// Contenuto principale: Mappa + Eventi
  Widget _buildMainContent() {
    if (_selectedIndex == 2) {
      // Vista Mute (solo ceraioli)
      return MuteListPage(onNavigateToMuta: (coords, zoom, muta) {});
    } else {
      // Home - Mappa + Eventi
      return Column(
        children: [
          // Mappa (occupa circa 50% dello schermo)
          Expanded(
            flex: 5,
            child: _buildMap(),
          ),
          // Sezione Eventi
          Expanded(
            flex: 5,
            child: _buildEventsSection(),
          ),
        ],
      );
    }
  }

  /// Mappa normale
  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _centerGubbio,
        zoom: 15,
      ),
      polylines: _polylines,
      markers: _markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        // Auto-zoom sul percorso completo all'apertura
        _fitBoundsToRoute();
      },
    );
  }

  /// Adatta la camera per mostrare tutto il percorso
  void _fitBoundsToRoute() {
    if (_mapController == null || _routeCoordinates.isEmpty) return;

    // Calcola i bounds del percorso
    double minLat = _routeCoordinates.first.latitude;
    double maxLat = _routeCoordinates.first.latitude;
    double minLng = _routeCoordinates.first.longitude;
    double maxLng = _routeCoordinates.first.longitude;

    for (final coord in _routeCoordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Anima la camera per mostrare i bounds con padding
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  /// Sezione Eventi (Prossimo evento)
  Widget _buildEventsSection() {
    final nextEvent = getNextEvent();

    return Container(
      color: const Color(0xFFFAFAFA),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Prossimo evento
          if (nextEvent != null) ...[
            const Text(
              'Prossimo evento',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B6B6B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildNextEventCard(nextEvent),
          ],
        ],
      ),
    );
  }

  /// Card del prossimo evento (completa con immagine)
  Widget _buildNextEventCard(EventModel event) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Immagine evento
          // Container(
          //   height: 180,
          //   decoration: BoxDecoration(
          //     color: const Color(0xFFF5F5F5),
          //     borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          //   ),
          //   child: Center(
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Icon(
          //           Icons.image_outlined,
          //           size: 48,
          //           color: const Color(0xFFBDBDBD),
          //         ),
          //         const SizedBox(height: 8),
          //         Text(
          //           'Immagine evento',
          //           style: TextStyle(
          //             fontSize: 13,
          //             color: const Color(0xFF9E9E9E),
          //             fontWeight: FontWeight.w500,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // Contenuto
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scritta "Prossimo Evento"
                const Text(
                  'Prossimo Evento',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                // Titolo
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                // Data e orario
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF6B6B6B),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '15 Maggio',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B6B6B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Color(0xFF6B6B6B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event.time,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B6B6B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Descrizione
                Text(
                  event.description.isNotEmpty
                      ? event.description
                      : event.location,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B6B6B),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                // Pulsante "Vedi sulla mappa"
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Seleziona l'evento e centra la mappa
                      setState(() {
                        _selectedEventId = event.id;
                        _selectedEventForSheet = event;
                        _isNavigationMode = false;
                      });
                      
                      // Centra la mappa sull'evento con zoom
                      _mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: event.coordinates,
                            zoom: 17,
                          ),
                        ),
                      );

                      // Chiudi il popup di benvenuto se aperto
                      if (_showWelcomePopup) {
                        setState(() {
                          _showWelcomePopup = false;
                        });
                      }
                    },
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text(
                      'Vedi sulla mappa',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2F80ED),
                      side: const BorderSide(
                        color: Color(0xFF2F80ED),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Pulsante "Portami all'evento"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Seleziona l'evento e centra la mappa
                      setState(() {
                        _selectedEventId = event.id;
                        _selectedEventForSheet = event;
                        _isNavigationMode = false;
                      });
                      
                      // Centra la mappa sull'evento con zoom
                      _mapController?.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: event.coordinates,
                            zoom: 17,
                          ),
                        ),
                      );

                      // Chiudi il popup di benvenuto se aperto
                      if (_showWelcomePopup) {
                        setState(() {
                          _showWelcomePopup = false;
                        });
                      }

                      // Mostra il dialog di navigazione
                      _showNavigationDialog(event);
                    },
                    icon: const Icon(Icons.directions, size: 18),
                    label: const Text(
                      'Portami all\'evento',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB22222),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet per visualizzare dettagli evento selezionato sulla mappa
  Widget _buildEventBottomSheet(EventModel event) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle per chiudere
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Immagine evento (nascosta in modalità navigazione)
            if (!_isNavigationMode)
              Container(
                height: 180,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEAEAEA),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: const Color(0xFFBDBDBD),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Immagine evento',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (!_isNavigationMode) const SizedBox(height: 16),
            // Dettagli evento
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Data e orario
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Color(0xFF6B6B6B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '15 Maggio',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6B6B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Color(0xFF6B6B6B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        event.time,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6B6B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Descrizione breve
                  Text(
                    event.description.isNotEmpty
                        ? event.description
                        : event.location,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B6B6B),
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  // Bottone "Portami all'evento"
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Mostra dialog e attiva modalità navigazione
                        _showNavigationDialog(event);
                        setState(() {
                          _isNavigationMode = true;
                        });
                      },
                      icon: const Icon(Icons.directions, size: 20),
                      label: const Text(
                        'Portami all\'evento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB22222),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Bottone "Chiudi"
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedEventForSheet = null;
                          _selectedEventId = null;
                          _isNavigationMode = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF424242),
                        side: const BorderSide(
                          color: Color(0xFF424242),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Chiudi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Dialog per scegliere modalità di navigazione
  void _showNavigationDialog(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Portami all\'evento',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scegli la modalità di navigazione:',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B6B6B),
              ),
            ),
            const SizedBox(height: 16),
            // Pulsante A piedi
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openNavigation(event, 'walking');
                },
                icon: const Icon(Icons.directions_walk),
                label: const Text('A piedi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2F80ED),
                  side: const BorderSide(
                    color: Color(0xFF2F80ED),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Pulsante In auto
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openNavigation(event, 'driving');
                },
                icon: const Icon(Icons.directions_car),
                label: const Text('In auto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2F80ED),
                  side: const BorderSide(
                    color: Color(0xFF2F80ED),
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Messaggio informativo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFE69C),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF856404),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Durante la Festa dei Ceri molte strade sono chiuse perché fanno parte del percorso della corsa. I percorsi in auto potrebbero non essere disponibili.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF856404),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Annulla',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Apre la navigazione verso l'evento
  Future<void> _openNavigation(EventModel event, String mode) async {
    // Costruisci URL per Google Maps
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${event.coordinates.latitude},${event.coordinates.longitude}&travelmode=$mode';
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Mostra messaggio di conferma
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Apertura navigazione ${mode == 'walking' ? 'a piedi' : 'in auto'} verso ${event.title}',
              ),
              backgroundColor: const Color(0xFF2F80ED),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Se non può aprire Google Maps, mostra errore
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossibile aprire Google Maps'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Gestisci errori
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nell\'apertura della navigazione: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Menu espandibile posizione (a ventaglio)
  Widget _buildFabMenu() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFabMenuOpen = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Stack(
          children: [
            // Pulsante 1: Percorso (sinistra)
            Positioned(
              left: MediaQuery.of(context).size.width * 0.28,
              bottom: 120,
              child: _buildFabMenuItem(
                icon: Icons.route,
                label: 'Percorso',
                onTap: () {
                  setState(() {
                    _isFabMenuOpen = false;
                  });
                  _showRoutePath();
                },
                delay: 0,
              ),
            ),
            // Pulsante 2: Dove sono (centro)
            Positioned(
              left: MediaQuery.of(context).size.width * 0.5 - 35,
              bottom: 150,
              child: _buildFabMenuItem(
                icon: Icons.my_location,
                label: 'Dove sono',
                onTap: () {
                  setState(() {
                    _isFabMenuOpen = false;
                  });
                  _onLocateUser();
                },
                delay: 50,
              ),
            ),
            // Pulsante 3: Ristoranti (destra)
            Positioned(
              right: MediaQuery.of(context).size.width * 0.28,
              bottom: 120,
              child: _buildFabMenuItem(
                icon: Icons.restaurant,
                label: 'Ristoranti',
                onTap: () {
                  setState(() {
                    _isFabMenuOpen = false;
                  });
                  _showRestaurantsDialog();
                },
                delay: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Item del menu posizione (icona sopra, testo sotto)
  Widget _buildFabMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 200 + delay),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: const Color(0xFF2F80ED),
                size: 28,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostra il percorso completo sulla mappa
  void _showRoutePath() {
    _fitBoundsToRoute();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Percorso completo della Festa dei Ceri'),
        backgroundColor: Color(0xFF2F80ED),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Mostra dialog per ristoranti
  void _showRestaurantsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.restaurant,
              color: const Color(0xFF2F80ED),
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Ristoranti',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction,
              size: 60,
              color: Color(0xFFFFA726),
            ),
            SizedBox(height: 16),
            Text(
              'Funzione in fase di sviluppo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Presto potrai trovare i migliori ristoranti vicino agli eventi della Festa dei Ceri.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B6B6B),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF2F80ED),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Popup di benvenuto
  Widget _buildWelcomePopup() {
    return WelcomePopup(
      onClose: () {
        setState(() {
          _showWelcomePopup = false;
        });
      },
      onViewProgram: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProgramPage(),
          ),
        );
      },
      nextEvent: getNextEvent(),
    );
  }

  /// Gestione tap su bottom navigation
  void _onBottomNavTap(int index, bool isCeraiolo) {
    if (index == 1) {
      // Programma - apre pagina programma
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProgramPage(),
        ),
      ).then((_) {
        // Non cambia selectedIndex, rimane su Home
      });
    } else if (index == 0) {
      // Home - resetta tutto e torna alla Home principale
      setState(() {
        _selectedIndex = 0;
        _selectedEventForSheet = null;
        _selectedEventId = null;
        _isNavigationMode = false;
        _showWelcomePopup = false;
      });
      // Mostra il percorso completo
      _fitBoundsToRoute();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  /// Localizza l'utente sulla mappa
  Future<void> _onLocateUser() async {
    final location = await _locationService.getCurrentLocation();

    if (!mounted) return;

    if (location != null) {
      setState(() {
        _currentLocation = location;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: 17,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posizione trovata!'),
          backgroundColor: Color(0xFF2F80ED), // Blu
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile ottenere la posizione'),
          backgroundColor: Color(0xFFB22222),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
