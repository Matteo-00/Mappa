import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/modern_header.dart';
import '../widgets/app_drawer.dart';
import '../widgets/visit_gubbio_welcome_dialog.dart';
import '../services/auth_service.dart';
import '../data/gubbio_boundary.dart';
import 'user_profile_page.dart';

/// HomePage moderna stile Google Maps
/// Mappa fullscreen di Gubbio con header moderno e bottom navigation
class ModernHomePage extends StatefulWidget {
  const ModernHomePage({super.key});

  @override
  State<ModernHomePage> createState() => _ModernHomePageState();
}

class _ModernHomePageState extends State<ModernHomePage> {
  GoogleMapController? _mapController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasShownWelcome = false;
  bool _isTrackingLocation = false; // Stato tracking GPS
  Set<Marker> _markers = {}; // Markers per posizione utente
  MapType _currentMapType = MapType.normal; // Tipo di mappa (Standard/Satellite)

  // Coordinate di Gubbio, Italia
  static const LatLng _gubbioCenter = LatLng(43.3504, 12.5755);
  
  // Poligono perimetro COMUNALE di Gubbio (confine amministrativo OSM)
  static const List<LatLng> _gubbioMunicipalBoundary = gubbioMunicipalBoundary;

  @override
  void initState() {
    super.initState();
    
    // Inizializza marker centro Gubbio
    _markers = {
      const Marker(
        markerId: MarkerId('gubbio_center'),
        position: _gubbioCenter,
        infoWindow: InfoWindow(
          title: 'Gubbio',
          snippet: 'Centro Storico',
        ),
      ),
    };
    
    // Mostra popup di benvenuto dopo il primo frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownWelcome && mounted) {
        _showWelcomeDialog();
        _hasShownWelcome = true;
      }
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }
  
  void _showWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const VisitGubbioWelcomeDialog(),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  String _getUserInitials() {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    
    if (user != null && user.nome.isNotEmpty && user.cognome.isNotEmpty) {
      return '${user.nome[0]}${user.cognome[0]}'.toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Mappa fullscreen
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _gubbioCenter,
              zoom: 11.5, // Zoom out per mostrare tutto il perimetro comunale
            ),
            mapType: _currentMapType,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            markers: _markers,
            polygons: {
              // Perimetro comunale di Gubbio (rosso, tratteggiato)
              Polygon(
                polygonId: const PolygonId('gubbio_municipal_boundary'),
                points: _gubbioMunicipalBoundary,
                strokeWidth: 4,
                strokeColor: Colors.red,
                fillColor: Colors.red.withOpacity(0.05),
                geodesic: true,
                // Nota: Google Maps Flutter web non supporta nativamente pattern tratteggiati (dashed)
                // Usiamo uno stroke più spesso per renderlo ben visibile
              ),
            },
          ),

          // Header semi-trasparente
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ModernHeader(
              onMenuTap: _openDrawer,
              userInitials: _getUserInitials(),
            ),
          ),

          // Search bar stile Google Maps
          Positioned(
            top: 70, // Sotto l'header
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),

          // Bottone Map Type in basso a sinistra
          Positioned(
            bottom: 80, // Sopra la bottom navigation
            left: 16,
            child: _buildMapTypeButton(),
          ),

          // Bottone GPS in basso a destra
          Positioned(
            bottom: 80, // Sopra la bottom navigation
            right: 16,
            child: _buildGPSButton(),
          ),

          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavButton(
                icon: Icons.home,
                label: 'Home',
                isActive: true,
                onTap: () {
                  // Già nella home, opzionale: ricentra mappa
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_gubbioCenter, 14.5),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.grey[800],
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra di ricerca stile Google Maps
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cerca qui...',
          hintStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey[600],
            size: 24,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.mic,
              color: Colors.grey[600],
              size: 24,
            ),
            onPressed: () {
              // TODO: Implementare ricerca vocale
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ricerca vocale non ancora implementata'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
        onSubmitted: (value) {
          // TODO: Implementare ricerca luogo
          if (value.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ricerca per: $value'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  /// Bottone Map Type selector stile Google Maps
  Widget _buildMapTypeButton() {
    return FloatingActionButton(
      onPressed: _showMapTypeDialog,
      backgroundColor: Colors.white,
      elevation: 4,
      child: const Icon(
        Icons.layers,
        color: Colors.blue,
        size: 28,
      ),
    );
  }

  /// Mostra dialog per selezionare il tipo di mappa
  void _showMapTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo di Mappa',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                _buildMapTypeOption(
                  'Standard',
                  MapType.normal,
                  Icons.map,
                ),
                const SizedBox(height: 12),
                _buildMapTypeOption(
                  'Satellite',
                  MapType.satellite,
                  Icons.satellite_alt,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Widget per opzione tipo mappa
  Widget _buildMapTypeOption(String title, MapType mapType, IconData icon) {
    final isSelected = _currentMapType == mapType;
    
    return InkWell(
      onTap: () {
        setState(() {
          _currentMapType = mapType;
        });
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.blue : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  /// Bottone GPS stile Google Maps
  Widget _buildGPSButton() {
    return FloatingActionButton(
      onPressed: _handleGPSButtonTap,
      backgroundColor: Colors.white,
      elevation: 4,
      child: Icon(
        _isTrackingLocation ? Icons.explore : Icons.navigation,
        color: Colors.blue,
        size: 28,
      ),
    );
  }

  /// Gestisce il click del bottone GPS
  Future<void> _handleGPSButtonTap() async {
    if (_isTrackingLocation) {
      // Modalità bussola: torna alla vista iniziale
      _resetToInitialView();
    } else {
      // Modalità freccia: attiva tracking posizione
      await _startLocationTracking();
    }
  }

  /// Attiva il tracking della posizione utente
  Future<void> _startLocationTracking() async {
    // Nota: Per Flutter web, la geolocation potrebbe richiedere permessi browser
    // e potrebbe non funzionare su localhost senza HTTPS
    
    // Simuliamo il tracking per ora (in produzione usare location_service.dart)
    // Per un'app reale, qui dovresti:
    // 1. Richiedere permessi posizione
    // 2. Ottenere la posizione corrente
    // 3. Centrare la mappa sulla posizione
    // 4. Aggiungere un marker blu per l'utente
    
    setState(() {
      _isTrackingLocation = true;
      
      // Per demo: aggiungiamo un marker fittizio vicino a Gubbio
      // In produzione, usare la posizione GPS reale
      const userPosition = LatLng(43.3520, 12.5770);
      
      _markers = {
        ..._markers,
        Marker(
          markerId: const MarkerId('user_location'),
          position: userPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'La tua posizione',
          ),
        ),
      };
    });

    // Centra la mappa sulla posizione utente con zoom maggiore
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(const LatLng(43.3520, 12.5770), 16.0),
    );
  }

  /// Resetta la mappa alla vista iniziale
  void _resetToInitialView() {
    setState(() {
      _isTrackingLocation = false;
      
      // Rimuovi il marker della posizione utente
      _markers = {
        const Marker(
          markerId: MarkerId('gubbio_center'),
          position: _gubbioCenter,
          infoWindow: InfoWindow(
            title: 'Gubbio',
            snippet: 'Centro Storico',
          ),
        ),
      };
    });

    // Torna alla vista iniziale con tutto il perimetro comunale
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_gubbioCenter, 11.5),
    );
  }
}
