import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../data/gubbio_boundary.dart';
import '../l10n/app_localizations.dart';
import '../models/luogo_model.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../services/language_service.dart';
import '../services/user_location_service.dart';
import '../theme/app_colors.dart';
import '../widgets/distance_label.dart';
import '../widgets/full_photo.dart';
import '../widgets/loading_screen.dart';
import '../widgets/place_filters.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/rating_icons.dart';
import 'admin/add_luogo_page.dart';
import 'admin/admin_widgets.dart';
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

  static const LatLng _centerGubbio = LatLng(43.35190, 12.57730);

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
    final languageCode = context.watch<LanguageService>().currentLanguageCode;
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
    _loadedLanguageCode = languageCode;
    final items = await ContentService.fetchLuoghi(
        tipo: _tipo, languageCode: languageCode);
    // La schermata di caricamento resta almeno il tempo minimo.
    if (_loading) await LoadingScreen.waitMinimum(loadingStart);
    if (!mounted) return;
    setState(() {
      _all = items;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorPrefix}: $e'),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Finché i dati non arrivano: schermata di caricamento a pagina intera.
    if (_loading) return LoadingScreen(onRetry: _load);
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final isAdmin = context.watch<AuthService>().isAdmin;
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          PremiumHeader(
            title: l10n.t(_tipo.navKey),
            trailing: isAdmin
                ? IconButton(
                    onPressed: _add,
                    tooltip: l10n.t('luogoAddTooltip'),
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.rossoGubbio, size: 28),
                  )
                : null,
          ),
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
                  onMapCreated: (controller) => _mapController = controller,
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
          _buildSearchBar(l10n),
          PlaceFilterBar(
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
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmptyState(l10n)
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) =>
                        _buildCard(_filtered[index], isAdmin),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
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
          setState(() => _searchQuery = value);
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: l10n.t(_tipo.searchKey),
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.rossoGubbio),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.tortora),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
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

  Widget _buildCard(LuogoModel luogo, bool isAdmin) {
    final canEdit = isAdmin && ContentService.isRemoteId(luogo.id);
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
        onTap: () => _openDetail(luogo),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Immagine / icona
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
                child: luogo.imageUrl != null
                    ? FullPhoto(
                        url: luogo.imageUrl!,
                        fallback: Icon(_tipo.icon,
                            size: 38, color: AppColors.rossoGubbio),
                      )
                    : Icon(_tipo.icon, size: 38, color: AppColors.rossoGubbio),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            luogo.name,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bluNotte,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (canEdit)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              EditIconButton(onPressed: () => _edit(luogo)),
                              const SizedBox(width: 6),
                              DeleteIconButton(
                                  onPressed: () => _delete(luogo)),
                            ],
                          ),
                      ],
                    ),
                    if (luogo.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        luogo.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (luogo.address.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(Icons.place_outlined,
                                size: 15, color: AppColors.tortora),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              luogo.address,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.bluNotte,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_tipo.hasRating && luogo.rating != null) ...[
                      const SizedBox(height: 8),
                      RatingSummary(
                          rating: luogo.rating!, kind: RatingKind.stelle),
                    ],
                    const SizedBox(height: 6),
                    DistanceLabel(target: luogo.coordinates),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
              color: AppColors.tortora.withOpacity(0.5),
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
