import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/restaurant_model.dart';
import '../data/gubbio_boundary.dart';
import '../theme/app_colors.dart';
import '../services/location_service.dart';
import '../services/content_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'admin/admin_widgets.dart';
import 'admin/add_place_page.dart';
import 'restaurant_detail_page.dart';
import '../widgets/premium_scaffold.dart';

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
  String? _loadedLanguageCode;
  
  static const LatLng _centerGubbio = LatLng(43.35190, 12.57730);

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = context.watch<LanguageService>().currentLanguageCode;
    if (_loadedLanguageCode != null && _loadedLanguageCode != languageCode) {
      _loadRestaurants();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadRestaurants() async {
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = languageCode;
    final restaurants =
        await ContentService.fetchRestaurants(languageCode: languageCode);
    if (!mounted) return;
    setState(() {
      _allRestaurants = restaurants;
    });
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
    } else {
      // Senza posizione, ordina dal più stellato al meno stellato.
      _filteredRestaurants.sort((a, b) {
        final ratingA = a.rating ?? 0;
        final ratingB = b.rating ?? 0;
        return ratingB.compareTo(ratingA);
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
            snippet: 'Ristorante',
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

  Future<void> _editRestaurant(RestaurantModel restaurant) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlacePage(isBar: false, editRestaurant: restaurant),
      ),
    );
    if (updated == true) {
      await _loadRestaurants();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          PremiumHeader(title: l10n.restaurantsNav),
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
                  polygons: {
                    Polygon(
                      polygonId: const PolygonId('gubbio_municipal_boundary'),
                      points: gubbioMunicipalBoundary,
                      strokeWidth: 4,
                      strokeColor: Colors.red,
                      fillColor: Colors.red.withOpacity(0.05),
                      geodesic: true,
                    ),
                  },
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
          // Lista ristoranti
          Expanded(
            child: _filteredRestaurants.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
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
          hintText: 'Cerca ristoranti per nome...',
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
  
  Future<void> _deleteRestaurant(RestaurantModel restaurant) async {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final ok = await confirmDelete(context, restaurant.name);
    if (!ok) return;
    try {
      await ContentService.deleteRestaurant(restaurant.id);
      await _loadRestaurants();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.restaurantDeleted),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorPrefix}: $e'),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  /// Card singolo ristorante
  Widget _buildRestaurantCard(RestaurantModel restaurant) {
    final canDelete = context.watch<AuthService>().isAdmin &&
        ContentService.isRemoteId(restaurant.id);
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
        onTap: () => _openRestaurantDetail(restaurant),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Immagine/icona
              Container(
                width: 84,
                height: 84,
                clipBehavior: Clip.antiAlias,
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
                child: restaurant.imageUrl != null
                    ? Image.network(
                        restaurant.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.restaurant_menu,
                          size: 38,
                          color: AppColors.rossoGubbio,
                        ),
                      )
                    : const Icon(
                        Icons.restaurant_menu,
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
                            restaurant.name,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bluNotte,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (canDelete)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              EditIconButton(
                                onPressed: () => _editRestaurant(restaurant),
                              ),
                              const SizedBox(width: 6),
                              DeleteIconButton(
                                onPressed: () => _deleteRestaurant(restaurant),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (restaurant.rating != null)
                      _buildMiniRating(restaurant.rating!),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (_currentLocation != null) ...[
                          const Icon(Icons.place_outlined,
                              size: 14, color: AppColors.rossoGubbio),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.formatDistance(_currentLocation!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.rossoGubbio,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
  
  Widget _buildMiniRating(double rating) {
    final fullStars = rating.floor();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < fullStars ? Icons.star_rounded : Icons.star_outline_rounded,
            color: const Color(0xFFF2A93B),
            size: 15,
          );
        }),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
          ),
        ),
      ],
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
            size: 76,
            color: AppColors.tortora.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessun ristorante trovato',
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
