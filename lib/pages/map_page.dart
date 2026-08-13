import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import '../models/restaurant_model.dart';
import '../models/bar_model.dart';
import '../data/restaurants_data.dart';
import '../data/bars_data.dart';
import '../services/location_service.dart';
import 'restaurant_detail_page.dart';

/// Pagina Mappa a tutto schermo di Gubbio con punti di interesse filtrabili.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  bool _isTrackingLocation = false;
  MapType _currentMapType = MapType.normal;

  bool _showRestaurants = true;
  bool _showBars = true;

  List<RestaurantModel> _restaurants = [];
  List<BarModel> _bars = [];
  Set<Marker> _markers = {};
  LatLng? _userLocation;

  static const LatLng _gubbioCenter = LatLng(43.3504, 12.5755);

  // Poligono perimetro COMUNALE di Gubbio (include tutte le frazioni)
  static final List<LatLng> _gubbioMunicipalBoundary = [
    const LatLng(43.4100, 12.5200),
    const LatLng(43.4150, 12.5450),
    const LatLng(43.4180, 12.5650),
    const LatLng(43.4150, 12.5900),
    const LatLng(43.4100, 12.6150),
    const LatLng(43.4000, 12.6400),
    const LatLng(43.3850, 12.6550),
    const LatLng(43.3650, 12.6650),
    const LatLng(43.3450, 12.6700),
    const LatLng(43.3250, 12.6650),
    const LatLng(43.3050, 12.6550),
    const LatLng(43.2850, 12.6350),
    const LatLng(43.2700, 12.6150),
    const LatLng(43.2650, 12.5900),
    const LatLng(43.2650, 12.5650),
    const LatLng(43.2700, 12.5400),
    const LatLng(43.2750, 12.5200),
    const LatLng(43.2850, 12.5000),
    const LatLng(43.3000, 12.4850),
    const LatLng(43.3200, 12.4800),
    const LatLng(43.3450, 12.4850),
    const LatLng(43.3650, 12.4950),
    const LatLng(43.3850, 12.5050),
    const LatLng(43.4000, 12.5100),
    const LatLng(43.4100, 12.5200),
  ];

  @override
  void initState() {
    super.initState();
    _restaurants = getGubbioRestaurants();
    _bars = getGubbioBars();
    _rebuildMarkers();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _rebuildMarkers() {
    final markers = <Marker>{};

    if (_showRestaurants) {
      for (final r in _restaurants) {
        markers.add(
          Marker(
            markerId: MarkerId('rest_${r.id}'),
            position: r.coordinates,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
              title: r.name,
              snippet: '${r.priceRange} · Ristorante',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RestaurantDetailPage(restaurant: r),
                ),
              ),
            ),
          ),
        );
      }
    }

    if (_showBars) {
      for (final b in _bars) {
        markers.add(
          Marker(
            markerId: MarkerId('bar_${b.id}'),
            position: b.coordinates,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRose),
            infoWindow: InfoWindow(
              title: b.name,
              snippet: '${b.priceRange} · Bar',
            ),
          ),
        );
      }
    }

    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'La tua posizione'),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _gubbioCenter,
              zoom: 14,
            ),
            mapType: _currentMapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            markers: _markers,
            polygons: {
              Polygon(
                polygonId: const PolygonId('gubbio_municipal_boundary'),
                points: _gubbioMunicipalBoundary,
                strokeWidth: 3,
                strokeColor: AppColors.rossoGubbio.withOpacity(0.7),
                fillColor: AppColors.rossoGubbio.withOpacity(0.04),
                geodesic: true,
              ),
            },
          ),

          // Home button
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: const HomeButton(),
              ),
            ),
          ),

          // Titolo pillola
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Mappa di Gubbio',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bluNotte,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filtri categorie
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 74),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _filterChip(
                        label: 'Ristoranti',
                        icon: Icons.restaurant_menu,
                        selected: _showRestaurants,
                        onTap: () {
                          setState(() => _showRestaurants = !_showRestaurants);
                          _rebuildMarkers();
                        },
                      ),
                      const SizedBox(width: 10),
                      _filterChip(
                        label: 'Bar',
                        icon: Icons.local_cafe_outlined,
                        selected: _showBars,
                        onTap: () {
                          setState(() => _showBars = !_showBars);
                          _rebuildMarkers();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Legenda
          Positioned(
            left: 16,
            bottom: 170,
            child: _legendCard(),
          ),

          // Map type
          Positioned(
            bottom: 100,
            left: 16,
            child: _circleButton(
              icon: Icons.layers_outlined,
              color: AppColors.rossoGubbio,
              onTap: _showMapTypeDialog,
            ),
          ),

          // GPS
          Positioned(
            bottom: 100,
            right: 16,
            child: _circleButton(
              icon: _isTrackingLocation ? Icons.explore : Icons.navigation,
              color: AppColors.rossoGubbio,
              onTap: _handleGPSButtonTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.rossoGubbio : Colors.white,
      borderRadius: BorderRadius.circular(30),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AppColors.rossoGubbio,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.bluNotte,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendRow(const Color(0xFFF5A623), 'Ristoranti'),
          const SizedBox(height: 6),
          _legendRow(const Color(0xFFE91E63), 'Bar'),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.place, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.bluNotte,
          ),
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: color, size: 26),
        ),
      ),
    );
  }

  void _showMapTypeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo di Mappa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bluNotte,
                  ),
                ),
                const SizedBox(height: 18),
                _buildMapTypeOption(
                    'Standard', MapType.normal, Icons.map_outlined),
                const SizedBox(height: 12),
                _buildMapTypeOption('Satellite', MapType.satellite,
                    Icons.satellite_alt_outlined),
                const SizedBox(height: 12),
                _buildMapTypeOption(
                    'Ibrida', MapType.hybrid, Icons.terrain_outlined),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapTypeOption(String title, MapType mapType, IconData icon) {
    final isSelected = _currentMapType == mapType;
    return InkWell(
      onTap: () {
        setState(() => _currentMapType = mapType);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.rossoGubbio.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.rossoGubbio : AppColors.grigioChiaro,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppColors.rossoGubbio : AppColors.tortora,
                size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.rossoGubbio : AppColors.bluNotte,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppColors.rossoGubbio, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGPSButtonTap() async {
    if (_isTrackingLocation) {
      _resetToInitialView();
    } else {
      await _startLocationTracking();
    }
  }

  Future<void> _startLocationTracking() async {
    final location = await _locationService.getCurrentLocation();
    final target = location ?? const LatLng(43.3520, 12.5770);

    setState(() {
      _isTrackingLocation = true;
      _userLocation = target;
    });
    _rebuildMarkers();

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(target, 16.0),
    );
  }

  void _resetToInitialView() {
    setState(() {
      _isTrackingLocation = false;
      _userLocation = null;
    });
    _rebuildMarkers();

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_gubbioCenter, 14),
    );
  }
}
