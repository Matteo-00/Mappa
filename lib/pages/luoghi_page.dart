import '../widgets/error_snack.dart';
import 'package:flutter/material.dart';
import '../widgets/place_list_view.dart';
import 'admin/admin_widgets.dart' show confirmDelete;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/offline_mode_service.dart';

import '../l10n/app_localizations.dart';
import '../models/luogo_model.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../services/language_service.dart';
import '../services/user_location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/loading_screen.dart';
import '../widgets/place_filters.dart';
import '../widgets/rating_icons.dart';
import 'admin/add_luogo_page.dart';
import 'luogo_detail_page.dart';

/// Elenco di un tipo di luogo (chiese, musei, negozi o parcheggi) con mappa
/// integrata, ricerca e filtri: stessa logica di bar, ristoranti e hotel, ma
/// senza valutazione (tranne i negozi, che hanno le stelle).
class LuoghiPage extends StatefulWidget {
  final LuogoTipo tipo;

  const LuoghiPage({super.key, required this.tipo});

  @override
  State<LuoghiPage> createState() => _LuoghiPageState();
}

class _LuoghiPageState extends State<LuoghiPage> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();

  /// True finché i dati non sono arrivati dal database.
  bool _loading = true;
  List<LuogoModel> _all = [];
  List<LuogoModel> _filtered = [];
  Set<Marker> _markers = {};

  LatLng? _currentLocation;
  String _searchQuery = '';
  String? _loadedLanguageCode;


  LuogoTipo get _tipo => widget.tipo;

  AppLocalizations get _l => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  @override
  void initState() {
    super.initState();
    _load();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Si ricarica anche quando si torna online (modalità offline).
    final languageCode = context.watch<LanguageService>().currentLanguageCode +
        context.watch<OfflineModeService>().reloadKey;
    if (_loadedLanguageCode != null && _loadedLanguageCode != languageCode) {
      _load();
    }
  }

  @override
  void dispose() {
    UserLocationService.instance.removeListener(_onLocationChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loadingStart = DateTime.now();
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = languageCode + OfflineModeService.instance.reloadKey;
    final items = await ContentService.fetchLuoghi(
        tipo: _tipo, languageCode: languageCode);
    // La schermata di caricamento resta almeno il tempo minimo.
    if (_loading) await LoadingScreen.waitMinimum(loadingStart);
    if (!mounted) return;
    setState(() {
      _all = items;
      _loading = false;
      _filters.dropMissingTag(_all.map((p) => p.tags));
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
    setState(() => _currentLocation = UserLocationService.instance.position);
    _applyFilters();
  }

  /// Filtri e ordinamento (vicino a me, tag...).
  final PlaceFilterState _filters = PlaceFilterState();

  void _applyFilters() {
    final result = PlaceFilters.apply<LuogoModel>(
      _all,
      state: _filters,
      query: _searchQuery,
      name: (p) => p.name,
      description: (p) => p.description,
      tags: (p) => p.tags,
      rating: (p) => p.rating,
      distance: (p) => _currentLocation == null
          ? null
          : p.calculateDistance(_currentLocation!),
    );
    setState(() => _filtered = result);
    _createMarkers();
  }

  void _createMarkers() {
    final markers = <Marker>{};
    for (final luogo in _filtered) {
      markers.add(
        Marker(
          markerId: MarkerId(luogo.id),
          position: luogo.coordinates,
          icon: BitmapDescriptor.defaultMarkerWithHue(_tipo.hue),
          infoWindow: InfoWindow(
            title: luogo.name,
            snippet: _l.t(_tipo.kindKey),
            onTap: () => _openDetail(luogo),
          ),
          onTap: () => _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(luogo.coordinates, 17),
          ),
        ),
      );
    }
    setState(() => _markers = markers);
  }

  void _openDetail(LuogoModel luogo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LuogoDetailPage(luogo: luogo)),
    );
  }

  Future<void> _add() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddLuogoPage(tipo: _tipo)),
    );
    if (added == true) await _load();
  }

  Future<void> _edit(LuogoModel luogo) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddLuogoPage(tipo: _tipo, editLuogo: luogo),
      ),
    );
    if (updated == true) await _load();
  }

  Future<void> _delete(LuogoModel luogo) async {
    final l10n = _l;
    final ok = await confirmDelete(context, luogo.name);
    if (!ok) return;
    try {
      await ContentService.deleteLuogo(luogo.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.t(_tipo.deletedKey)),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Finché i dati non arrivano: schermata di caricamento a pagina intera.
    if (_loading) return LoadingScreen(onRetry: _load);
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final isAdmin = context.watch<AuthService>().isAdmin;
    return PlaceListView(
      title: l10n.t(_tipo.navKey),
      fallbackIcon: _tipo.icon,
      ratingKind: RatingKind.stelle,
      showRating: _tipo.hasRating,
      compactCards: _tipo.isUsefulInfo,
      headerAction: isAdmin
          ? IconButton(
              onPressed: _add,
              tooltip: l10n.t('luogoAddTooltip'),
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.rossoGubbio, size: 28),
            )
          : null,
      markers: _markers,
      onMapCreated: (c) => _mapController = c,
      searchController: _searchController,
      searchHint: l10n.t(_tipo.searchKey),
      searchQuery: _searchQuery,
      onSearchChanged: (value) {
        setState(() => _searchQuery = value);
        _applyFilters();
      },
      filterBar: PlaceFilterBar(
            ratingKind: RatingKind.stelle,
            showRating: _tipo.hasRating,
            state: _filters,
            availableTags: _tipo.hasContacts
                ? PlaceFilters.tagsByFrequency(_all.map((p) => p.tags))
                : const [],
            locationAvailable: _currentLocation != null,
            resultCount: _filtered.length,
            onChanged: _applyFilters,
          ),
      locationAvailable: _currentLocation != null,
      emptyState: _buildEmptyState(l10n),
      items: [
        for (final luogo in _filtered)
          PlaceCardData(
            id: luogo.id,
            name: luogo.name,
            description: luogo.description,
            address: luogo.address,
            coordinates: luogo.coordinates,
            imageUrl: luogo.imageUrl,
            phone: _tipo.hasContacts ? luogo.phoneNumber : null,
            tags: _tipo.hasContacts ? luogo.tags : const [],
            rating: luogo.rating,
            favoriteKind:
                ContentService.isRemoteId(luogo.id) ? _tipo.db : null,
            onTap: () => _openDetail(luogo),
            onEdit: isAdmin && ContentService.isRemoteId(luogo.id)
                ? () => _edit(luogo)
                : null,
            onDelete: isAdmin && ContentService.isRemoteId(luogo.id)
                ? () => _delete(luogo)
                : null,
          ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tipo.icon,
              size: 76,
              color: AppColors.tortora.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.t(_tipo.emptyKey),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.bluNotte,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.t('tryChangeSearchShort'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
