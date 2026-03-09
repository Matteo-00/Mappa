import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/restaurant_model.dart';
import '../data/restaurants_data.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';
import 'restaurant_detail_page.dart';

/// Pagina ristoranti con mappa integrata e lista
class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  final LocationService _locationService = LocationService();
  
  List<RestaurantModel> _allRestaurants = [];
  List<RestaurantModel> _filteredRestaurants = [];
  Set<Marker> _markers = {};
  
  LatLng? _currentLocation;
  String _searchQuery = '';
  
  static const LatLng _centerGubbio = LatLng(43.35190, 12.57730);

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadRestaurants() {
    _allRestaurants = getGubbioRestaurants();
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
    List<RestaurantModel> filtered = List.from(_allRestaurants);
    
    // Filtra per nome
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((restaurant) {
        return restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    setState(() {
      _filteredRestaurants = filtered;
    });
    
    _sortByDistance();
    _createMarkers();
  }
  
  void _sortByDistance() {
    if (_currentLocation != null) {
      _filteredRestaurants.sort((a, b) {
        final distA = a.calculateDistance(_currentLocation!);
        final distB = b.calculateDistance(_currentLocation!);
        return distA.compareTo(distB);
      });
    }
  }
  
  void _createMarkers() {
    final markers = <Marker>{};
    
    for (final restaurant in _filteredRestaurants) {
      markers.add(
        Marker(
          markerId: MarkerId(restaurant.id),
          position: restaurant.coordinates,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: restaurant.name,
            snippet: restaurant.priceRange,
            onTap: () => _openRestaurantDetail(restaurant),
          ),
          onTap: () => _onMarkerTap(restaurant),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  void _onMarkerTap(RestaurantModel restaurant) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(restaurant.coordinates, 17),
    );
  }
  
  void _openRestaurantDetail(RestaurantModel restaurant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RestaurantDetailPage(restaurant: restaurant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vgAncientParchment,
      body: Column(
        children: [
          // Mappa
          SizedBox(
            height: 300,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _centerGubbio,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
            ),
          ),
          
          // Barra di ricerca
          _buildSearchBar(),
          
          // Lista ristoranti
          Expanded(
            child: _filteredRestaurants.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredRestaurants.length,
                    itemBuilder: (context, index) {
                      return _buildRestaurantCard(_filteredRestaurants[index]);
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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vgStoneGray.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
          hintText: 'Cerca ristoranti per nome...',
          hintStyle: TextStyle(color: AppTheme.vgStoneGray.withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search, color: AppTheme.vgBronze),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.vgStoneGray),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
  
  /// Card singolo ristorante
  Widget _buildRestaurantCard(RestaurantModel restaurant) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vgStoneGray.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openRestaurantDetail(restaurant),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Immagine/icona
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [AppTheme.vgWarmStone, AppTheme.vgStoneGray],
                  ),
                ),
                child: Icon(
                  Icons.restaurant,
                  size: 40,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Informazioni
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome ristorante
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.vgDarkSlate,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Descrizione breve
                    Text(
                      restaurant.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.vgStoneGray,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Info aggiuntive
                    Row(
                      children: [
                        // Distanza
                        if (_currentLocation != null) ...[
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.vgBronze,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.formatDistance(_currentLocation!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.vgBronze,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        
                        // Prezzo
                        Text(
                          restaurant.priceRange,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.vgStoneGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Sconto
                        if (restaurant.hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.vgOliveGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '5% SCONTO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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
            Icons.restaurant_menu,
            size: 80,
            color: AppTheme.vgStoneGray.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun ristorante trovato',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.vgStoneGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prova a modificare la ricerca',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.vgStoneGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
