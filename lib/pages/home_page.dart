import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
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
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  
  LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  int _selectedIndex = 0;
  bool _showWelcomePopup = true; // Mostra popup di benvenuto

  // Centro iniziale: Gubbio, Piazza Grande
  static const LatLng _centerGubbio = LatLng(43.35190, 12.57730);

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
    
    // Marker rossi per eventi principali
    final events = get15MaggioEvents();
    for (final event in events) {
      markers.add(
        Marker(
          markerId: MarkerId(event.id),
          position: event.coordinates,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: event.title,
            snippet: event.time,
          ),
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
          // Popup di benvenuto
          if (_showWelcomePopup) _buildWelcomePopup(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) => _onBottomNavTap(index, isCeraiolo),
        showMute: isCeraiolo,
      ),
    );
  }

  /// Contenuto principale: Mappa + Eventi
  Widget _buildMainContent() {
    if (_selectedIndex == 1) {
      // Vista "Dove sono" - solo mappa full screen
      return _buildFullScreenMap();
    } else if (_selectedIndex == 3) {
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

  /// Mappa a schermo intero
  Widget _buildFullScreenMap() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _currentLocation ?? _centerGubbio,
            zoom: _currentLocation != null ? 17 : 15,
          ),
          polylines: _polylines,
          markers: _markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
        if (_isLoadingLocation)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB22222)),
              ),
            ),
          ),
      ],
    );
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
      },
    );
  }

  /// Sezione Eventi (Prossimo evento + Oggi alla Festa)
  Widget _buildEventsSection() {
    final nextEvent = getNextEvent();
    final todayEvents = get15MaggioEvents()
        .where((e) => e.isToday())
        .take(3)
        .toList();

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
            const SizedBox(height: 32),
          ],
          // Oggi alla Festa
          const Text(
            'Oggi alla Festa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...todayEvents.map((event) => _buildEventCard(event)),
        ],
      ),
    );
  }

  /// Card del prossimo evento
  Widget _buildNextEventCard(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2F80ED), // Blu invece di rosso
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80ED), // Blu invece di rosso
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.time,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Centra la mappa sull'evento
                _mapController?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: event.coordinates,
                      zoom: 16,
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2F80ED), // Blu invece di rosso
                side: const BorderSide(
                  color: Color(0xFF2F80ED), // Blu invece di rosso
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Apri sulla mappa',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card evento normale
  Widget _buildEventCard(EventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Immagine segnaposto
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.festival_rounded,
              color: const Color(0xFFB22222).withOpacity(0.3),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          // Info evento
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F80ED), // Blu invece di rosso
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      // Dove sono - attiva geolocalizzazione
      _onLocateUser();
    } else if (index == 2) {
      // Programma - apre pagina programma
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProgramPage(),
        ),
      ).then((_) {
        setState(() {
          _selectedIndex = 0; // Torna a Home
        });
      });
    }
  }

  /// Localizza l'utente sulla mappa
  Future<void> _onLocateUser() async {
    setState(() => _isLoadingLocation = true);

    final location = await _locationService.getCurrentLocation();

    if (!mounted) return;

    setState(() => _isLoadingLocation = false);

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
