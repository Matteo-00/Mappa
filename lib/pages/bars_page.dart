import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bar_model.dart';
import '../data/bars_data.dart';
import '../theme/app_colors.dart';
import '../services/location_service.dart';
import '../widgets/premium_scaffold.dart';

/// Pagina bar con mappa integrata e lista (stesso stile dei ristoranti)
class BarsPage extends StatefulWidget {
  const BarsPage({super.key});

  @override
  State<BarsPage> createState() => _BarsPageState();
}

class _BarsPageState extends State<BarsPage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();

  List<BarModel> _allBars = [];
  List<BarModel> _filteredBars = [];
  Set<Marker> _markers = {};

  LatLng? _currentLocation;
  String _searchQuery = '';

  static const LatLng _centerGubbio = LatLng(43.35190, 12.57730);

  @override
  void initState() {
    super.initState();
    _loadBars();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadBars() {
    _allBars = getGubbioBars();
    _applyFilters();
  }

  Future<void> _getCurrentLocation() async {
    final location = await _locationService.getCurrentLocation();
    if (location != null) {
      setState(() {
        _currentLocation = location;
      });
      _sortByDistance();
    }
  }

  void _applyFilters() {
    List<BarModel> filtered = List.from(_allBars);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((bar) {
        return bar.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredBars = filtered;
    });

    _sortByDistance();
    _createMarkers();
  }

  void _sortByDistance() {
    if (_currentLocation != null) {
      _filteredBars.sort((a, b) {
        final distA = a.calculateDistance(_currentLocation!);
        final distB = b.calculateDistance(_currentLocation!);
        return distA.compareTo(distB);
      });
    }
  }

  void _createMarkers() {
    final markers = <Marker>{};

    for (final bar in _filteredBars) {
      markers.add(
        Marker(
          markerId: MarkerId(bar.id),
          position: bar.coordinates,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
          infoWindow: InfoWindow(
            title: bar.name,
            snippet: bar.priceRange,
          ),
          onTap: () => _onMarkerTap(bar),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _onMarkerTap(BarModel bar) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(bar.coordinates, 17),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          const PremiumHeader(title: 'Bar'),
          // Mappa
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 240,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: _centerGubbio,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                ),
              ),
            ),
          ),
          // Barra di ricerca
          _buildSearchBar(),
          // Lista bar
          Expanded(
            child: _filteredBars.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _filteredBars.length,
                    itemBuilder: (context, index) {
                      return _buildBarCard(_filteredBars[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Barra di ricerca
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Cerca bar per nome...',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.rossoGubbio),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.tortora),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  /// Card singolo bar
  Widget _buildBarCard(BarModel bar) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _onMarkerTap(bar),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icona
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.tortora.withOpacity(0.45),
                      AppColors.avorio,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.local_cafe_outlined,
                  size: 38,
                  color: AppColors.rossoGubbio,
                ),
              ),

              const SizedBox(width: 16),

              // Informazioni
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bar.name,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bluNotte,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (bar.rating != null) ...[
                          const Icon(Icons.star_rounded,
                              size: 16, color: AppColors.rossoGubbio),
                          const SizedBox(width: 2),
                          Text(
                            bar.rating!.toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.rossoGubbio,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bar.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (_currentLocation != null) ...[
                          const Icon(Icons.place_outlined,
                              size: 14, color: AppColors.rossoGubbio),
                          const SizedBox(width: 4),
                          Text(
                            bar.formatDistance(_currentLocation!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.rossoGubbio,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          bar.priceRange,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Stato vuoto
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_cafe_outlined,
            size: 76,
            color: AppColors.tortora.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessun bar trovato',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prova a modificare la ricerca',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
