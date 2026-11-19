import '../widgets/error_snack.dart';
import 'package:flutter/material.dart';
import '../widgets/place_list_view.dart';
import 'map_page.dart' show MapKind;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/offline_mode_service.dart';
import '../models/hotel_model.dart';
import '../theme/app_colors.dart';
import '../services/user_location_service.dart';
import '../services/content_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'admin/admin_widgets.dart';
import 'admin/add_place_page.dart';
import 'hotel_detail_page.dart';
import '../widgets/place_filters.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../widgets/loading_screen.dart';
import '../widgets/rating_icons.dart';

/// Pagina hotel con mappa integrata e lista
class HotelsPage extends StatefulWidget {
  const HotelsPage({super.key});

  @override
  State<HotelsPage> createState() => _HotelsPageState();
}

class _HotelsPageState extends State<HotelsPage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  /// True finché i dati non sono arrivati dal database.
  bool _loading = true;
  List<HotelModel> _allHotels = [];
  List<HotelModel> _filteredHotels = [];
  Set<Marker> _markers = {};
  
  LatLng? _currentLocation;
  String _searchQuery = '';
  String? _loadedLanguageCode;
  

  AppLocalizations get _l10n => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  @override
  void initState() {
    super.initState();
    _loadHotels();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Si ricarica anche quando si torna online (modalità offline).
    final languageCode = context.watch<LanguageService>().currentLanguageCode +
        context.watch<OfflineModeService>().reloadKey;
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
    final loadingStart = DateTime.now();
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = languageCode + OfflineModeService.instance.reloadKey;
    final hotels =
        await ContentService.fetchHotels(languageCode: languageCode);
    // La crescia resta almeno un secondo, così non "lampeggia".
    if (_loading) await LoadingScreen.waitMinimum(loadingStart);
    if (!mounted) return;
    setState(() {
      _allHotels = hotels;
      _loading = false;
      _filters.dropMissingTag(_allHotels.map((p) => p.cuisineTypes));
    });
    _applyFilters();
    final stats = await ReviewService.fetchStats(ReviewService.hotels);
    if (!mounted) return;
    setState(() => _userStats = stats);
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

  /// Media delle recensioni degli utenti per ogni scheda.
  Map<String, ReviewStats> _userStats = {};

  void _applyFilters() {
    final result = PlaceFilters.apply<HotelModel>(
      _allHotels,
      state: _filters,
      query: _searchQuery,
      name: (p) => p.name,
      description: (p) => p.description,
      tags: (p) => p.cuisineTypes,
      rating: (p) => p.rating,
      userRating: (p) => _userStats[p.id]?.average,
      userCount: (p) => _userStats[p.id]?.count ?? 0,
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
            snippet: _l10n.t('kindHotel'),
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
    // Finché i dati non arrivano: schermata di caricamento a pagina intera.
    if (_loading) return LoadingScreen(onRetry: _loadHotels);
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final isAdmin = context.watch<AuthService>().isAdmin;
    return PlaceListView(
      title: l10n.hotelsNav,
      fallbackIcon: Icons.hotel_outlined,
      ratingKind: RatingKind.palazzo,
      markers: _markers,
      onMapCreated: (c) => _mapController = c,
      searchController: _searchController,
      searchHint: _l10n.t('searchHotelHint'),
      searchQuery: _searchQuery,
      onSearchChanged: (value) {
        setState(() => _searchQuery = value);
        _applyFilters();
      },
      filterBar: PlaceFilterBar(
            ratingKind: RatingKind.palazzo,
            state: _filters,
            availableTags: PlaceFilters.tagsByFrequency(
                _allHotels.map((p) => p.cuisineTypes)),
            locationAvailable: _currentLocation != null,
            resultCount: _filteredHotels.length,
            onChanged: _applyFilters,
            showUserRating: _userStats.isNotEmpty,
          ),
      locationAvailable: _currentLocation != null,
      emptyState: _buildEmptyState(),
      items: [
        for (final hotel in _filteredHotels)
          PlaceCardData(
            id: hotel.id,
            name: hotel.name,
            description: hotel.description,
            address: hotel.address,
            coordinates: hotel.coordinates,
            imageUrl: hotel.imageUrl,
            phone: hotel.phoneNumber,
            tags: hotel.cuisineTypes,
            rating: hotel.rating,
            userStats: _userStats[hotel.id],
            favoriteKind:
                ContentService.isRemoteId(hotel.id) ? MapKind.hotel : null,
            onTap: () => _openHotelDetail(hotel),
            onEdit: isAdmin && ContentService.isRemoteId(hotel.id)
                ? () => _editHotel(hotel)
                : null,
            onDelete: isAdmin && ContentService.isRemoteId(hotel.id)
                ? () => _deleteHotel(hotel)
                : null,
          ),
      ],
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
      showErrorSnackBar(context, e);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hotel,
            size: 76,
            color: AppColors.tortora.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _l10n.t('emptyHotel'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _l10n.t('tryChangeSearchShort'),
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
