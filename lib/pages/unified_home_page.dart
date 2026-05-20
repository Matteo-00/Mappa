import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/unified_header.dart';
import '../widgets/unified_footer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/location_menu.dart';
import '../widgets/festa_ceri_loading_screen.dart';
import '../services/location_service.dart';
import '../models/event_model.dart';
import '../data/events_data.dart';
import 'events_list_page.dart';
import 'restaurants_page.dart';
import 'program_page.dart';
import 'festa_ceri_info_page.dart';
import 'event_detail_page.dart';

/// Home page unificata che gestisce entrambe le modalità
/// Visit Gubbio e Festa dei Ceri
class UnifiedHomePage extends StatefulWidget { 
  const UnifiedHomePage({super.key});

  @override
  State<UnifiedHomePage> createState() => _UnifiedHomePageState();
}

class _UnifiedHomePageState extends State<UnifiedHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  
  LatLng? _currentLocation;
  int _selectedNavIndex = 0;
  bool _isLocationMenuOpen = false;
  
  String _currentSection = 'map'; // map, eventi, ristoranti
  
  // Centro iniziale: Gubbio, Piazza Grande
  static const LatLng _centerGubbio = LatLng(43.35190, 12.57730);
  
  Set<Marker> _markers = {};
  Set<Polyline> _ceriRoute = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  Future<void> _getCurrentLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location != null && mounted) {
      setState(() {
        _currentLocation = location;
      });
    }
  }
  
  void _onMenuItemSelected(String item) async {
    final themeProvider = context.read<ThemeProvider>();
    
    switch (item) {
      case 'eventi':
        setState(() {
          _currentSection = 'eventi';
          _selectedNavIndex = 1;
        });
        break;
        
      case 'ristoranti':
        setState(() {
          _currentSection = 'ristoranti';
        });
        break;
        
      case 'festa_ceri':
        // Mostra loading screen per 2 secondi
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => FestaCeriLoadingScreen(
            onComplete: () {
              Navigator.pop(context);
            },
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 2000));
        
        // Cambia modalità
        await themeProvider.switchToFestaDeiCeri();
        
        if (mounted) {
          setState(() {
            _currentSection = 'map';
            _selectedNavIndex = 0;
          });
          _loadCeriRoute();
        }
        break;
        
      case 'programma':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProgramPage()),
        );
        break;
        
      case 'informazioni':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FestaCeriInfoPage()),
        );
        break;
        
      case 'visit_gubbio':
        await themeProvider.switchToVisitGubbio();
        if (mounted) {
          setState(() {
            _currentSection = 'map';
            _selectedNavIndex = 0;
          });
        }
        break;
    }
  }
  
  void _onNavigationTap(int index) {
    final themeProvider = context.read<ThemeProvider>();
    
    setState(() {
      _selectedNavIndex = index;
    });
    
    if (index == 0) {
      // Home - torna alla mappa
      setState(() {
        _currentSection = 'map';
      });
    } else if (index == 1) {
      // Eventi (Visit Gubbio) o Programma (Festa dei Ceri)
      if (themeProvider.isVisitGubbio) {
        setState(() {
          _currentSection = 'eventi';
        });
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProgramPage()),
        );
      }
    }
  }
  
  void _toggleLocationMenu() {
    setState(() {
      _isLocationMenuOpen = !_isLocationMenuOpen;
    });
  }
  
  void _onGubbioMapsTap() {
    final themeProvider = context.read<ThemeProvider>();
    
    setState(() {
      _isLocationMenuOpen = false;
      _currentSection = 'map';
    });
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_centerGubbio, 15),
    );
  }
  
  void _onWhereAmITap() {
    setState(() {
      _isLocationMenuOpen = false;
    });
    
    if (_currentLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 17),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Posizione non disponibile'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _loadCeriRoute() {
    // Carica il percorso dei Ceri e i marker degli eventi
    final events = get15MaggioEvents();
    final markers = <Marker>{};
    
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
    
    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Theme(
          data: themeProvider.currentTheme,
          child: Scaffold(
            key: _scaffoldKey,
            drawer: AppDrawer(
              onMenuItemSelected: _onMenuItemSelected,
            ),
            appBar: UnifiedHeader(
              onMenuTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            body: Stack(
              children: [
                // Contenuto principale
                _buildMainContent(themeProvider),
                
                // Menu posizione (quando aperto)
                if (_isLocationMenuOpen)
                  LocationMenu(
                    onGubbioMapsTap: _onGubbioMapsTap,
                    onWhereAmITap: _onWhereAmITap,
                  ),
              ],
            ),
            bottomNavigationBar: UnifiedFooter(
              selectedIndex: _selectedNavIndex,
              onNavigationTap: _onNavigationTap,
              onLocationMenuTap: _toggleLocationMenu,
              isLocationMenuOpen: _isLocationMenuOpen,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMainContent(ThemeProvider themeProvider) {
    switch (_currentSection) {
      case 'eventi':
        return EventsListPage(
          onEventTap: (event) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventDetailPage(event: event),
              ),
            );
          },
        );
        
      case 'ristoranti':
        return const RestaurantsPage();
        
      case 'map':
      default:
        return _buildMapView(themeProvider);
    }
  }
  
  Widget _buildMapView(ThemeProvider themeProvider) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _centerGubbio,
        zoom: 15,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        if (themeProvider.isFestaDeiCeri) {
          _loadCeriRoute();
        }
      },
      markers: _markers,
      polylines: _ceriRoute,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
    );
  }
}
