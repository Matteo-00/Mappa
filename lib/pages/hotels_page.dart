import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/hotel_model.dart';
import '../data/gubbio_boundary.dart';
import '../theme/app_colors.dart';
import '../services/user_location_service.dart';
import '../widgets/distance_label.dart';
import '../services/content_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'admin/admin_widgets.dart';
import 'admin/add_place_page.dart';
import 'hotel_detail_page.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/place_filters.dart';

/// Pagina hotel con mappa integrata e lista
class HotelsPage extends StatefulWidget {
  const HotelsPage({super.key});

  @override
  State<HotelsPage> createState() => _HotelsPageState();
}

class _HotelsPageState extends State<HotelsPage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  List<HotelModel> _allHotels = [];
  List<HotelModel> _filteredHotels = [];
  Set<Marker> _markers = {};
  
  LatLng? _currentLocation;
  String _searchQuery = '';
  String? _loadedLanguageCode;
  
  static const LatLng _centerGubbio = LatLng(43.35190, 12.57730);

  @override
  void initState() {
    super.initState();
    _loadHotels();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = context.watch<LanguageService>().currentLanguageCode;
    if (_loadedLanguageCode != null && _loadedLanguageCode != languageCode) {
      _loadHotels();
    }
  }

  @override
  void dispose() {
    UserLocationService.instance.removeListener(_onLocationChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadHotels() async {
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = languageCode;
    final hotels =
        await ContentService.fetchHotels(languageCode: languageCode);
    if (!mounted) return;
    setState(() {
      _allHotels = hotels;
    });
    _applyFilters();
  }
  
  /// Usa la posizione condivisa dell'app. Il controllo è silenzioso: l'invito
  /// ad abilitare la posizione compare sulle singole schede.
  Future<void> _getCurrentLocation() async {
    final service = UserLocationService.instance;
    service.addListener(_onLocationChanged);
    await service.refresh();
    _onLocationChanged();
  }

  void _onLocationChanged() {
    if (!mounted) return;
    final location = UserLocationService.instance.position;
    setState(() {
      _currentLocation = location;
    });
    _applyFilters();
  }
  
  /// Filtri e ordinamento (vicino a me, stelle, tag...).
  final PlaceFilterState _filters = PlaceFilterState();

  void _applyFilters() {
    final result = PlaceFilters.apply<HotelModel>(
      _allHotels,
      state: _filters,
      query: _searchQuery,
      name: (p) => p.name,
      description: (p) => p.description,
      tags: (p) => p.cuisineTypes,
      rating: (p) => p.rating,
      distance: (p) => _currentLocation == null
          ? null
          : p.calculateDistance(_currentLocation!),
    );
    setState(() {
      _filteredHotels = result;
    });
    _createMarkers();
  }

  void _createMarkers() {
    final markers = <Marker>{};
    
    for (final hotel in _filteredHotels) {
      markers.add(
        Marker(
          markerId: MarkerId(hotel.id),
          position: hotel.coordinates,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: hotel.name,
            snippet: 'Hotel',
            onTap: () => _openHotelDetail(hotel),
          ),
          onTap: () => _onMarkerTap(hotel),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  void _onMarkerTap(HotelModel hotel) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(hotel.coordinates, 17),
    );
  }
  
  void _openHotelDetail(HotelModel hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotelDetailPage(hotel: hotel),
      ),
    );
  }

  Future<void> _editHotel(HotelModel hotel) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlacePage(isBar: false, isHotel: true, editHotel: hotel),
      ),
    );
    if (updated == true) {
      await _loadHotels();
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
          PremiumHeader(title: l10n.hotelsNav),
          // Mappa
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 205,
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
          PlaceFilterBar(
            state: _filters,
            availableTags: PlaceFilters.tagsByFrequency(
                _allHotels.map((p) => p.cuisineTypes)),
            locationAvailable: _currentLocation != null,
            resultCount: _filteredHotels.length,
            onChanged: _applyFilters,
          ),
          // Lista hotel
          Expanded(
            child: _filteredHotels.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _filteredHotels.length,
                    itemBuilder: (context, index) {
                      return _buildHotelCard(_filteredHotels[index]);
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
          hintText: 'Cerca hotel per nome...',
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
  
  Future<void> _deleteHotel(HotelModel hotel) async {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final ok = await confirmDelete(context, hotel.name);
    if (!ok) return;
    try {
      await ContentService.deleteHotel(hotel.id);
      await _loadHotels();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.hotelDeleted),
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

  /// Card singolo hotel
  Widget _buildHotelCard(HotelModel hotel) {
    final canDelete = context.watch<AuthService>().isAdmin &&
        ContentService.isRemoteId(hotel.id);
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
        onTap: () => _openHotelDetail(hotel),
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
                child: hotel.imageUrl != null
                    ? Image.network(
                        hotel.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.hotel,
                          size: 38,
                          color: AppColors.rossoGubbio,
                        ),
                      )
                    : const Icon(
                        Icons.hotel,
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
                            hotel.name,
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
                                onPressed: () => _editHotel(hotel),
                              ),
                              const SizedBox(width: 6),
                              DeleteIconButton(
                                onPressed: () => _deleteHotel(hotel),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hotel.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (hotel.rating != null)
                      _buildMiniRating(hotel.rating!),
                    const SizedBox(height: 6),
                    DistanceLabel(target: hotel.coordinates),
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
            Icons.hotel,
            size: 76,
            color: AppColors.tortora.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessun hotel trovato',
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
