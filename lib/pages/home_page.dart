import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../models/user_mode.dart';
import '../models/muta_model.dart';
import '../data/events_data.dart';
import '../data/mute_data.dart';
import '../widgets/map_action_button.dart';
import 'turista_events_page.dart';
import 'mute_list_page.dart';
import 'login_page.dart';

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
  LatLng? _selectedDestination;
  String? _selectedDestinationName;
  bool _isLoadingLocation = false;
  double _currentZoom = 15.0; // Traccia il livello di zoom corrente

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

    // Marker posizione utente
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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

    return Scaffold(
      drawer: _buildDrawer(userMode),
      body: Stack(
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
              // Aggiorna il livello di zoom corrente
              if (_currentZoom != position.zoom) {
                setState(() {
                  _currentZoom = position.zoom;
                });
              }
            },
            onTap: (_) {
              // Nasconde la distanza quando si clicca sulla mappa
              if (_selectedDestination != null) {
                setState(() {
                  _selectedDestination = null;
                  _selectedDestinationName = null;
                });
              }
            },
          ),

          // Barra superiore con titolo e menu
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Festa dei Ceri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userMode?.displayName ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottoni azione sulla mappa (in basso a sinistra)
          Positioned(
            bottom: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MapActionButton(
                  icon: Icons.my_location,
                  label: 'Dove sono',
                  onPressed: _onLocateUser,
                ),
                if (_currentLocation != null) ...[
                  const SizedBox(height: 8),
                  MapActionButton(
                    icon: Icons.straighten,
                    label: 'Calcola distanza',
                    onPressed: _onCalculateDistance,
                  ),
                ],
                if (_selectedDestination != null) ...[
                  const SizedBox(height: 8),
                  MapActionButton(
                    icon: Icons.directions_walk,
                    label: 'Indicazioni',
                    onPressed: _onGetDirections,
                  ),
                ],
              ],
            ),
          ),

          // Info distanza (se presente)
          if (_selectedDestination != null && _currentLocation != null)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Distanza',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _locationService.formatDistance(
                        _locationService.calculateDistance(
                          _currentLocation!,
                          _selectedDestination!,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    if (_selectedDestinationName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'a $_selectedDestinationName',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Loading indicator per geolocalizzazione
          if (_isLoadingLocation)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawer(UserMode? userMode) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFB71C1C),
                  Colors.red[900]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.local_fire_department_outlined,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Festa dei Ceri',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  userMode?.displayName ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Menu specifico per modalità
          if (userMode == UserMode.turista) ...[
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Come viene strutturata la giornata'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TuristaEventsPage()),
                );
              },
            ),
            const Divider(),
          ],

          if (userMode == UserMode.ceraiolo) ...[
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Mute'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MuteListPage(
                      onNavigateToMuta: _navigateToMuta,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
          ],

          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Mappa'),
            onTap: () => Navigator.pop(context),
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Informazioni'),
            onTap: () {
              Navigator.pop(context);
              _showInfoDialog();
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              context.read<AuthService>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
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
            zoom: 16,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile ottenere la posizione'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Calcola la distanza dall'utente a una destinazione
  void _onCalculateDistance() {
    // Mostra dialog per selezionare destinazione
    showDialog(
      context: context,
      builder: (context) {
        final userMode = context.read<AuthService>().userMode;
        final List<dynamic> destinations =
            userMode == UserMode.ceraiolo ? muteData : eventsData;

        return AlertDialog(
          title: const Text('Seleziona destinazione'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final dest = destinations[index];
                final name = dest is MutaModel ? dest.name : dest.title;
                final location = dest is MutaModel ? dest.zone : dest.location;

                return ListTile(
                  title: Text(name),
                  subtitle: Text(location),
                  onTap: () {
                    setState(() {
                      _selectedDestination = dest.coordinates;
                      _selectedDestinationName = name;
                    });

                    // Anima la mappa per mostrare utente e destinazione
                    _animateToShowBoth();

                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
          ],
        );
      },
    );
  }

  /// Avvia navigazione pedonale verso la destinazione
  Future<void> _onGetDirections() async {
    if (_currentLocation == null || _selectedDestination == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_currentLocation!.latitude},${_currentLocation!.longitude}'
      '&destination=${_selectedDestination!.latitude},${_selectedDestination!.longitude}'
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

  /// Anima la camera per mostrare sia l'utente che la destinazione
  void _animateToShowBoth() {
    if (_currentLocation == null || _selectedDestination == null) return;

    final lat1 = _currentLocation!.latitude;
    final lng1 = _currentLocation!.longitude;
    final lat2 = _selectedDestination!.latitude;
    final lng2 = _selectedDestination!.longitude;

    final minLat = math.min(lat1, lat2);
    final maxLat = math.max(lat1, lat2);
    final minLng = math.min(lng1, lng2);
    final maxLng = math.max(lng1, lng2);

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  /// Mostra popup dettagliato con struttura barella e ceraioli
  void _showMutaDetailPopup(MutaModel muta) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titolo e Capo Muta
                Text(
                  muta.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB71C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      'Capo Muta: ${muta.capoMuta}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB71C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 6),
                    Text(
                      muta.zone,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Struttura barella
                _buildBarellaStructure(muta),
                
                const SizedBox(height: 20),
                
                // Pulsante chiudi
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Chiudi'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Costruisce la rappresentazione grafica della barella con gli 11 ceraioli
  Widget _buildBarellaStructure(MutaModel muta) {
    return Column(
      children: [
        // Titolo sezione
        Text(
          'Composizione Muta',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        
        // Capocorsa (davanti al centro)
        _buildCeraiolo(muta.capocorsa, 'Capocorsa', true),
        const SizedBox(height: 12),
        
        // Vista dall'alto della barella
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Prima riga
              _buildBarellaRow(
                sinistra: muta.esterniSinistra[0],
                destra: muta.esterniDestra[0],
                centro: null,
              ),
              const SizedBox(height: 4),
              
              // Seconda riga
              _buildBarellaRow(
                sinistra: muta.esterniSinistra[1],
                destra: muta.esterniDestra[1],
                centro: null,
              ),
              const SizedBox(height: 2),
              
              // Traversa centrale (più spessa)
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF212121),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 2),
              
              // Terza riga con primo interno
              _buildBarellaRow(
                sinistra: muta.esterniSinistra[2],
                destra: muta.esterniDestra[2],
                centro: muta.interniPosteriori[0],
              ),
              const SizedBox(height: 4),
              
              // Quarta riga con secondo interno
              _buildBarellaRow(
                sinistra: muta.esterniSinistra[3],
                destra: muta.esterniDestra[3],
                centro: muta.interniPosteriori[1],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Costruisce una riga della barella con esterni e interni
  Widget _buildBarellaRow({
    required String sinistra,
    required String destra,
    required String? centro,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Esterno sinistro
        _buildCeraiolo(sinistra, '', false),
        const SizedBox(width: 8),
        
        // Stanga sinistra
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF424242),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        
        // Centro (interno o spazio vuoto)
        SizedBox(
          width: 80,
          child: centro != null
              ? _buildCeraiolo(centro, 'Interno', false)
              : Container(),
        ),
        const SizedBox(width: 12),
        
        // Stanga destra
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF424242),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        
        // Esterno destro
        _buildCeraiolo(destra, '', false),
      ],
    );
  }

  /// Costruisce un widget per un singolo ceraiolo
  Widget _buildCeraiolo(String nome, String ruolo, bool isCapocorsa) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isCapocorsa ? const Color(0xFFB71C1C) : Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCapocorsa ? const Color(0xFF8B0000) : Colors.grey[400]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ruolo.isNotEmpty)
            Text(
              ruolo,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isCapocorsa ? Colors.white70 : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          Text(
            nome,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isCapocorsa ? Colors.white : Colors.grey[800],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Mostra info su una muta (modalità Ceraiolo)
  /// Mostra dialog informazioni
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Festa dei Ceri'),
        content: const Text(
          'App dedicata alla Festa dei Ceri di Gubbio.\n\n'
          'Supporta turisti e ceraioli durante il 15 maggio con mappe interattive, '
          'eventi e funzionalità di navigazione.\n\n'
          'Un\'esperienza elegante per valorizzare una tradizione millenaria.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
