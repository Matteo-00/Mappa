import 'package:flutter/material.dart';
import '../widgets/place_list_view.dart';
import 'map_page.dart' show MapKind;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/offline_mode_service.dart';
import '../models/bar_model.dart';
import '../theme/app_colors.dart';
import '../services/user_location_service.dart';
import '../services/content_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'admin/admin_widgets.dart';
import 'admin/add_place_page.dart';
import '../widgets/place_filters.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../widgets/loading_screen.dart';
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
    // Si ricarica anche quando si torna online (modalità offline).
    final languageCode = context.watch<LanguageService>().currentLanguageCode +
        context.watch<OfflineModeService>().reloadKey;
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
    _loadedLanguageCode = languageCode + OfflineModeService.instance.reloadKey;
    final bars = await ContentService.fetchBars(languageCode: languageCode);
    // La crescia resta almeno un secondo, così non "lampeggia".
    if (_loading) await LoadingScreen.waitMinimum(loadingStart);
    if (!mounted) return;
    setState(() {
      _allBars = bars;
      _loading = false;
      _filters.dropMissingTag(_allBars.map((p) => p.cuisineTypes));
    });
    _applyFilters();
    final stats = await ReviewService.fetchStats(ReviewService.bars);
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
    final result = PlaceFilters.apply<BarModel>(
      _allBars,
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
    final isAdmin = context.watch<AuthService>().isAdmin;
    return PlaceListView(
      title: l10n.barsNav,
      fallbackIcon: Icons.local_cafe_outlined,
      ratingKind: RatingKind.amaro,
      markers: _markers,
      onMapCreated: (c) => _mapController = c,
      searchController: _searchController,
      searchHint: _l10n.t('searchBarHint'),
      searchQuery: _searchQuery,
      onSearchChanged: (value) {
        setState(() => _searchQuery = value);
        _applyFilters();
      },
      filterBar: PlaceFilterBar(
            ratingKind: RatingKind.amaro,
            state: _filters,
            availableTags: PlaceFilters.tagsByFrequency(
                _allBars.map((p) => p.cuisineTypes)),
            locationAvailable: _currentLocation != null,
            resultCount: _filteredBars.length,
            onChanged: _applyFilters,
            showUserRating: _userStats.isNotEmpty,
          ),
      locationAvailable: _currentLocation != null,
      emptyState: _buildEmptyState(),
      items: [
        for (final bar in _filteredBars)
          PlaceCardData(
            id: bar.id,
            name: bar.name,
            description: bar.description,
            address: bar.address,
            coordinates: bar.coordinates,
            imageUrl: bar.imageUrl,
            phone: bar.phoneNumber,
            tags: bar.cuisineTypes,
            rating: bar.rating,
            userStats: _userStats[bar.id],
            favoriteKind:
                ContentService.isRemoteId(bar.id) ? MapKind.bar : null,
            onTap: () => _openBarDetail(bar),
            onEdit: isAdmin && ContentService.isRemoteId(bar.id)
                ? () => _editBar(bar)
                : null,
            onDelete: isAdmin && ContentService.isRemoteId(bar.id)
                ? () => _deleteBar(bar)
                : null,
          ),
      ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_cafe_outlined,
            size: 76,
            color: AppColors.tortora.withValues(alpha: 0.5),
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

}
