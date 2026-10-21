import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/bar_model.dart';
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
import '../widgets/premium_scaffold.dart';
import '../widgets/place_filters.dart';
import '../widgets/loading_screen.dart';
import '../widgets/full_photo.dart';
import '../widgets/rating_icons.dart';
import 'bar_detail_page.dart';

/// Pagina bar con mappa integrata e lista (stesso stile dei ristoranti)
class BarsPage extends StatefulWidget {
  const BarsPage({super.key});

  @override
  State<BarsPage> createState() => _BarsPageState();
}

class _BarsPageState extends State<BarsPage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  /// True finché i dati non sono arrivati dal database.
  bool _loading = true;
  List<BarModel> _allBars = [];
  List<BarModel> _filteredBars = [];
  Set<Marker> _markers = {};

  LatLng? _currentLocation;
  String _searchQuery = '';
  String? _loadedLanguageCode;

  static const LatLng _centerGubbio = LatLng(43.35190, 12.57730);

  AppLocalizations get _l10n => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  @override
  void initState() {
    super.initState();
    _loadBars();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = context.watch<LanguageService>().currentLanguageCode;
    if (_loadedLanguageCode != null && _loadedLanguageCode != languageCode) {
      _loadBars();
    }
  }

  @override
  void dispose() {
    UserLocationService.instance.removeListener(_onLocationChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBars() async {
    final loadingStart = DateTime.now();
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = languageCode;
    final bars = await ContentService.fetchBars(languageCode: languageCode);
    // La crescia resta almeno un secondo, così non "lampeggia".
    if (_loading) await LoadingScreen.waitMinimum(loadingStart);
    if (!mounted) return;
    setState(() {
      _allBars = bars;
      _loading = false;
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
    final result = PlaceFilters.apply<BarModel>(
      _allBars,
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
      _filteredBars = result;
    });
    _createMarkers();
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
            snippet: _l10n.t('kindBar'),
            onTap: () => _openBarDetail(bar),
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

  void _openBarDetail(BarModel bar) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BarDetailPage(bar: bar)),
    );
  }

  Future<void> _editBar(BarModel bar) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddPlacePage(isBar: true, editBar: bar),
      ),
    );
    if (updated == true) {
      await _loadBars();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Finché i dati non arrivano: schermata di caricamento a pagina intera.
    if (_loading) return LoadingScreen(onRetry: _loadBars);
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          PremiumHeader(title: l10n.barsNav),
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
            ratingKind: RatingKind.amaro,
            state: _filters,
            availableTags: PlaceFilters.tagsByFrequency(
                _allBars.map((p) => p.cuisineTypes)),
            locationAvailable: _currentLocation != null,
            resultCount: _filteredBars.length,
            onChanged: _applyFilters,
          ),
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
          hintText: _l10n.t('searchBarHint'),
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

  Future<void> _deleteBar(BarModel bar) async {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final ok = await confirmDelete(context, bar.name);
    if (!ok) return;
    try {
      await ContentService.deleteBar(bar.id);
      await _loadBars();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.barDeleted),
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

  /// Card singolo bar
  Widget _buildBarCard(BarModel bar) {
    final canDelete = context.watch<AuthService>().isAdmin &&
        ContentService.isRemoteId(bar.id);
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
        onTap: () => _openBarDetail(bar),
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
                child: bar.imageUrl != null
                    ? FullPhoto(
                        url: bar.imageUrl!,
                        fallback: const Icon(
                          Icons.local_cafe_outlined,
                          size: 38,
                          color: AppColors.rossoGubbio,
                        ),
                      )
                    : const Icon(
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
                        if (canDelete)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              EditIconButton(
                                onPressed: () => _editBar(bar),
                              ),
                              const SizedBox(width: 6),
                              DeleteIconButton(
                                onPressed: () => _deleteBar(bar),
                              ),
                            ],
                          ),
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
                    const SizedBox(height: 8),
                    if (bar.rating != null) _buildMiniRating(bar.rating!),
                    const SizedBox(height: 6),
                    DistanceLabel(target: bar.coordinates),
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
          Text(
            _l10n.t('emptyBar'),
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

  Widget _buildMiniRating(double rating) => RatingSummary(rating: rating, kind: RatingKind.amaro);
}
