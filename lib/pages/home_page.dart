import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../models/user_mode.dart';
import '../models/muta_model.dart';
import '../models/barella_model.dart';
import '../data/events_data.dart';
import '../data/mute_data.dart';
import '../widgets/barella_visualization.dart';
import 'turista_events_page.dart';
import 'mute_list_page.dart';
import 'login_page.dart';
import 'user_profile_page.dart';

/// HomePage con GoogleMap al centro, percorso Ceri e funzionalità complete
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
  double _currentZoom = 15.0; // Traccia il livello di zoom corrente
  int _selectedIndex = 0; // Per il bottom navigation bar

  // Centro iniziale: Gubbio, Piazza Grande
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(43.35190, 12.57730),
    zoom: 15,
  );

  // Percorso ufficiale dei Ceri (da Piazza Grande a Basilica Sant'Ubaldo)
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
          color: const Color(0xFFB71C1C), // Rosso elegante
          width: 5,
          geodesic: true,
        ),
      };

  Set<Marker> get _markers {
    final markers = <Marker>{};
    final userMode = context.read<AuthService>().userMode;

    if (userMode == UserMode.ceraiolo) {
      // Modalità Ceraiolo: mostra le mute solo con zoom >= 17
      if (_currentZoom >= 17.0) {
        for (final muta in muteData) {
          markers.add(
            Marker(
              markerId: MarkerId(muta.id),
              position: muta.coordinates,
              // Blu scuro elegante (hue 210 = blu scuro)
              icon: BitmapDescriptor.defaultMarkerWithHue(210),
              onTap: () => _showMutaDetailPopup(muta),
            ),
          );
        }
      }
    } else {
      // Modalità Turista: mostra i luoghi degli eventi
      for (final event in eventsData) {
        markers.add(
          Marker(
            markerId: MarkerId(event.id),
            position: event.coordinates,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: event.title,
              snippet: event.location,
            ),
          ),
        );
      }
    }

    // Marker posizione utente blu
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(210), // Blu
          infoWindow: const InfoWindow(title: 'La tua posizione'),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userMode = authService.userMode;
    final isCeraiolo = userMode == UserMode.ceraiolo;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(isCeraiolo),
    );
  }

  /// AppBar con titolo "15 Maggio" e menu account
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        '15 Maggio',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFFC00000),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.account_circle,
            size: 32,
            color: Colors.black87,
          ),
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'profile') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UserProfilePage(),
                ),
              );
            } else if (value == 'logout') {
              _handleLogout();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.black87),
                  SizedBox(width: 12),
                  Text('Utente'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.black87),
                  SizedBox(width: 12),
                  Text('Logout'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Body principale con mappa
  Widget _buildBody() {
    return Stack(
      children: [
        // Mappa principale
        GoogleMap(
          initialCameraPosition: _initialPosition,
          polylines: _polylines,
          markers: _markers,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onCameraMove: (CameraPosition position) {
            if (_currentZoom != position.zoom) {
              setState(() {
                _currentZoom = position.zoom;
              });
            }
          },
          onTap: (_) {
            // Tap sulla mappa
          },
        ),

        // Loading indicator
        if (_isLoadingLocation)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC00000)),
              ),
            ),
          ),
      ],
    );
  }

  /// Bottom Navigation Bar
  Widget _buildBottomNavBar(bool isCeraiolo) {
    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.location_on),
        label: 'Dove sono',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.event),
        label: 'Giornata',
      ),
      if (isCeraiolo)
        const BottomNavigationBarItem(
          icon: Icon(Icons.groups),
          label: 'Mute',
        ),
    ];

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => _onBottomNavTap(index, isCeraiolo),
      items: items,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFFC00000),
      unselectedItemColor: Colors.grey,
      elevation: 8,
    );
  }

  /// Gestione tap su bottom navigation
  void _onBottomNavTap(int index, bool isCeraiolo) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0: // Home
        _onHomePressed();
        break;
      case 1: // Dove sono
        _onLocateUser();
        break;
      case 2: // Giornata
        _onGiornataPressed();
        break;
      case 3: // Mute (solo ceraioli)
        if (isCeraiolo) {
          _onMutePressed();
        }
        break;
    }
  }

  /// Torna alla vista iniziale della mappa
  void _onHomePressed() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(_initialPosition),
    );
  }

  /// Apre la schermata "Come è strutturata la giornata"
  void _onGiornataPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TuristaEventsPage(),
      ),
    ).then((_) {
      // Reset l'indice quando si torna
      setState(() {
        _selectedIndex = 0;
      });
    });
  }

  /// Apre la schermata mute
  void _onMutePressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MuteListPage(
          onNavigateToMuta: _navigateToMuta,
        ),
      ),
    ).then((_) {
      setState(() {
        _selectedIndex = 0;
      });
    });
  }

  /// Gestisce il logout
  void _handleLogout() {
    context.read<AuthService>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /// Naviga alla muta sulla mappa, centra, zooma e apre il popup
  void _navigateToMuta(LatLng coordinates, double zoom, MutaModel muta) {
    setState(() {
      _currentZoom = zoom;
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: coordinates,
          zoom: zoom,
        ),
      ),
    );

    // Aspetta che l'animazione finisca e poi apre il popup
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _showMutaDetailPopup(muta);
      }
    });
  }

  /// Localizza l'utente sulla mappa con marker blu
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
            zoom: 16,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile ottenere la posizione'),
          backgroundColor: Color(0xFFC00000),
        ),
      );
    }
  }

  /// Mostra popup dettagliato con struttura barella e ceraioli
  void _showMutaDetailPopup(MutaModel muta) {
    showDialog(
      context: context,
      builder: (context) => BarellaVisualization(barella: barellaEsempio),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
