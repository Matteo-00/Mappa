import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// HomePage con GoogleMap, Drawer laterale e percorso evidenziato
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Controller della mappa
  GoogleMapController? _mapController;

  // Centro iniziale della mappa
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(43.35190, 12.57730),
    zoom: 15,
  );

  // Coordinate del percorso da evidenziare
  final List<LatLng> _routeCoordinates = const [
    LatLng(43.35190, 12.57730),
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
    LatLng(43.34705, 12.58820),
  ];

  // Set di Polyline per la mappa
  Set<Polyline> get _polylines => {
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routeCoordinates,
          color: Colors.red,
          width: 5,
          geodesic: true,
        ),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar moderna
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Mappa App'),
        elevation: 0,
      ),
      // Drawer laterale
      drawer: _buildDrawer(),
      // Body con GoogleMap
      body: SafeArea(
        child: GoogleMap(
          initialCameraPosition: _initialPosition,
          polylines: _polylines,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
        ),
      ),
      // FloatingActionButton per centrare sulla route
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnRoute,
        tooltip: 'Centra sul percorso',
        child: const Icon(Icons.my_location),
      ),
    );
  }

  /// Costruisce il Drawer laterale
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // DrawerHeader moderno con colore primario
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.map,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mappa App',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Menu Items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Percorso'),
            onTap: () {
              Navigator.pop(context);
              _centerOnRoute();
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Informazioni'),
            onTap: () {
              Navigator.pop(context);
              _showInfoDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Impostazioni'),
            onTap: () {
              Navigator.pop(context);
              _showSettingsDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Chiudi'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// Centra la mappa sul percorso usando LatLngBounds
  void _centerOnRoute() {
    if (_mapController == null || _routeCoordinates.isEmpty) return;

    // Calcola i bounds del percorso
    double minLat = _routeCoordinates.first.latitude;
    double maxLat = _routeCoordinates.first.latitude;
    double minLng = _routeCoordinates.first.longitude;
    double maxLng = _routeCoordinates.first.longitude;

    for (var point in _routeCoordinates) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Anima la camera verso i bounds
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  /// Mostra dialog informazioni
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informazioni'),
        content: const Text(
          'App di visualizzazione percorsi su mappa.\n\n'
          'Sviluppata con Flutter e Google Maps.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostra dialog impostazioni
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Impostazioni'),
        content: const Text('Funzionalità in arrivo...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
