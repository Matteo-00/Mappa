import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../widgets/distance_label.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/scroll_hints.dart';
import '../models/restaurant_model.dart';
import '../models/bar_model.dart';
import '../models/hotel_model.dart';
import '../models/event_model.dart';
import '../models/itinerario_model.dart';
import '../data/gubbio_boundary.dart';
import '../services/location_service.dart';
import '../services/content_service.dart';
import '../services/language_service.dart';
import 'restaurant_detail_page.dart';
import 'bar_detail_page.dart';
import 'hotel_detail_page.dart';
import 'event_detail_page.dart';
import 'itinerario_detail_page.dart';

/// Tipi di punto mostrati sulla mappa.
class MapKind {
  MapKind._();
  static const restaurant = 'restaurant';
  static const bar = 'bar';
  static const hotel = 'hotel';
  static const event = 'event';
  static const itinerary = 'itinerary';

  /// Prefisso usato negli identificativi dei marker.
  static String prefix(String kind) {
    switch (kind) {
      case restaurant:
        return 'rest';
      case bar:
        return 'bar';
      case hotel:
        return 'hotel';
      case event:
        return 'event';
      default:
        return 'itin';
    }
  }
}

/// Punto da mostrare già selezionato e ingrandito all'apertura della mappa
/// (usato dal pulsante "Mostra sulla mappa" delle pagine di dettaglio).
class MapFocus {
  final String kind; // uno di [MapKind]
  final String id;
  final LatLng position;

  const MapFocus({required this.kind, required this.id, required this.position});

  String get key => '${MapKind.prefix(kind)}_$id';
}

/// Un punto selezionabile sulla mappa (ristorante, bar, hotel, evento, itinerario).
class _MapPlace {
  final String key;
  final String kind;
  final String name;
  final String kindLabel;
  final IconData icon;
  final Color color;
  final double hue;
  final LatLng position;
  final String address;
  final VoidCallback Function(BuildContext) detailOpener;

  const _MapPlace({
    required this.key,
    required this.kind,
    required this.name,
    required this.kindLabel,
    required this.icon,
    required this.color,
    required this.hue,
    required this.position,
    required this.address,
    required this.detailOpener,
  });
}

/// Pagina Mappa a tutto schermo di Gubbio con punti di interesse filtrabili.
///
/// Se viene passato [focus], la mappa si apre ingrandita su quel punto, già
/// selezionato (con le indicazioni a piedi / in auto).
class MapPage extends StatefulWidget {
  final MapFocus? focus;

  const MapPage({super.key, this.focus});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  AppLocalizations get _l => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  bool _isTrackingLocation = false;
  MapType _currentMapType = MapType.normal;

  bool _showRestaurants = true;
  bool _showBars = true;
  bool _showHotels = true;
  bool _showEvents = true;
  bool _showItinerari = true;

  /// Punto attualmente selezionato (mostra la scheda con le indicazioni).
  _MapPlace? _selected;

  static const Color _restaurantColor = Color(0xFFF5A623);
  static const Color _barColor = Color(0xFFE91E63);
  static const Color _hotelColor = Color(0xFF7B3FE4);
  static const Color _eventColor = Color(0xFF2E9E5B);
  static const Color _itineraryColor = Color(0xFFD9A400);

  List<RestaurantModel> _restaurants = [];
  List<BarModel> _bars = [];
  List<HotelModel> _hotels = [];
  List<EventModel> _events = [];
  List<ItinerarioModel> _itinerari = [];
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  String? _loadedLanguageCode;

  bool _dataLoaded = false;
  bool _focusApplied = false;

  static const LatLng _gubbioCenter = LatLng(43.3504, 12.5755);

  // Poligono perimetro COMUNALE di Gubbio (confine amministrativo OSM)
  static const List<LatLng> _gubbioMunicipalBoundary = gubbioMunicipalBoundary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = context.watch<LanguageService>().currentLanguageCode;
    if (_loadedLanguageCode != null && _loadedLanguageCode != languageCode) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = languageCode;
    final restaurants =
        await ContentService.fetchRestaurants(languageCode: languageCode);
    final bars = await ContentService.fetchBars(languageCode: languageCode);
    final hotels = await ContentService.fetchHotels(languageCode: languageCode);
    final events = await ContentService.fetchEvents(languageCode: languageCode);
    final itinerari =
        await ContentService.fetchItinerari(languageCode: languageCode);
    if (!mounted) return;
    setState(() {
      _restaurants = restaurants;
      _bars = bars;
      _hotels = hotels;
      _events = events;
      _itinerari = itinerari;
      _selected = null;
      _dataLoaded = true;
    });
    _rebuildMarkers();
    _applyFocus();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _applyFocus();
  }

  /// Tutti i punti, indipendentemente dai filtri.
  List<_MapPlace> _allPlaces() {
    final places = <_MapPlace>[];
    final now = DateTime.now();
    final focusKey = widget.focus?.key;

    for (final r in _restaurants) {
      places.add(_MapPlace(
        key: 'rest_${r.id}',
        kind: MapKind.restaurant,
        name: r.name,
        kindLabel: _l.t('kindRestaurant'),
        icon: Icons.restaurant_menu,
        color: _restaurantColor,
        hue: BitmapDescriptor.hueOrange,
        position: r.coordinates,
        address: r.address,
        detailOpener: (ctx) => () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => RestaurantDetailPage(restaurant: r)),
            ),
      ));
    }

    for (final b in _bars) {
      places.add(_MapPlace(
        key: 'bar_${b.id}',
        kind: MapKind.bar,
        name: b.name,
        kindLabel: _l.t('kindBar'),
        icon: Icons.local_cafe_outlined,
        color: _barColor,
        hue: BitmapDescriptor.hueRose,
        position: b.coordinates,
        address: b.address,
        detailOpener: (ctx) => () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => BarDetailPage(bar: b)),
            ),
      ));
    }

    for (final h in _hotels) {
      places.add(_MapPlace(
        key: 'hotel_${h.id}',
        kind: MapKind.hotel,
        name: h.name,
        kindLabel: _l.t('kindHotel'),
        icon: Icons.hotel_outlined,
        color: _hotelColor,
        hue: BitmapDescriptor.hueViolet,
        position: h.coordinates,
        address: h.address,
        detailOpener: (ctx) => () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => HotelDetailPage(hotel: h)),
            ),
      ));
    }

    for (final e in _events) {
      final key = 'event_${e.id}';
      // Sulla mappa solo gli eventi di OGGI (più quello eventualmente aperto
      // da "Mostra sulla mappa", anche se di un altro giorno).
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final isToday =
          e.startTime.isBefore(endOfDay) && e.endTime.isAfter(startOfDay);
      if (!isToday && key != focusKey) continue;
      places.add(_MapPlace(
        key: key,
        kind: MapKind.event,
        name: e.title,
        kindLabel: _l.t('kindEvent'),
        icon: Icons.event,
        color: _eventColor,
        hue: BitmapDescriptor.hueGreen,
        position: e.coordinates,
        address: e.location.trim().isEmpty ? e.time : '${e.time} · ${e.location}',
        detailOpener: (ctx) => () => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => EventDetailPage(event: e)),
            ),
      ));
    }

    for (final it in _itinerari) {
      if (!it.hasCoordinates) continue; // senza posizione non si può mostrare
      places.add(_MapPlace(
        key: 'itin_${it.id}',
        kind: MapKind.itinerary,
        name: it.titolo,
        kindLabel: _l.t('kindItinerary'),
        icon: Icons.route,
        color: _itineraryColor,
        hue: BitmapDescriptor.hueYellow,
        position: LatLng(it.latitudine!, it.longitudine!),
        address: _l.t('startPoint'),
        detailOpener: (ctx) => () => Navigator.push(
              ctx,
              MaterialPageRoute(
                  builder: (_) => ItinerarioDetailPage(itinerario: it)),
            ),
      ));
    }

    return places;
  }

  bool _isKindVisible(String kind) {
    switch (kind) {
      case MapKind.restaurant:
        return _showRestaurants;
      case MapKind.bar:
        return _showBars;
      case MapKind.hotel:
        return _showHotels;
      case MapKind.event:
        return _showEvents;
      default:
        return _showItinerari;
    }
  }

  void _setKindVisible(String kind, bool value) {
    switch (kind) {
      case MapKind.restaurant:
        _showRestaurants = value;
        break;
      case MapKind.bar:
        _showBars = value;
        break;
      case MapKind.hotel:
        _showHotels = value;
        break;
      case MapKind.event:
        _showEvents = value;
        break;
      default:
        _showItinerari = value;
    }
  }

  /// Tutti i punti visibili in base ai filtri attivi.
  List<_MapPlace> _visiblePlaces() =>
      _allPlaces().where((p) => _isKindVisible(p.kind)).toList();

  void _rebuildMarkers() {
    final markers = <Marker>{};
    final places = _visiblePlaces();

    for (final p in places) {
      markers.add(
        Marker(
          markerId: MarkerId(p.key),
          position: p.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(p.hue),
          zIndex: _selected?.key == p.key ? 2 : 1,
          infoWindow: InfoWindow(title: p.name, snippet: p.kindLabel),
          onTap: () => _selectPlace(p),
        ),
      );
    }

    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: _l.yourPosition),
        ),
      );
    }

    setState(() {
      _markers = markers;
      // Se il punto selezionato è stato nascosto da un filtro, chiude la scheda.
      if (_selected != null && !places.any((p) => p.key == _selected!.key)) {
        _selected = null;
      }
    });
  }

  /// Seleziona un punto: mostra la scheda con le indicazioni, lo evidenzia
  /// sulla mappa e ingrandisce su di esso.
  Future<void> _selectPlace(_MapPlace place, {double? zoom}) async {
    setState(() => _selected = place);

    final controller = _mapController;
    if (controller == null) return;

    double targetZoom;
    if (zoom != null) {
      targetZoom = zoom;
    } else {
      // Non rimpicciolisce se l'utente è già vicino; ingrandisce se è lontano.
      final current = await controller.getZoomLevel();
      targetZoom = current < 16 ? 16.5 : current;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(place.position, targetZoom),
    );
    if (!mounted) return;
    // Mostra anche il fumetto con il nome sopra il marker.
    controller.showMarkerInfoWindow(MarkerId(place.key));
  }

  /// All'apertura da "Mostra sulla mappa": ingrandisce sul punto richiesto e
  /// lo mostra selezionato. Parte solo quando dati e mappa sono pronti.
  Future<void> _applyFocus() async {
    final focus = widget.focus;
    if (focus == null || _focusApplied) return;
    if (!_dataLoaded || _mapController == null) return;
    _focusApplied = true;

    _MapPlace? target;
    for (final p in _allPlaces()) {
      if (p.key == focus.key) {
        target = p;
        break;
      }
    }

    if (target == null) {
      // Il punto non è nell'elenco (es. dati non caricati): almeno si ingrandisce.
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(focus.position, 17),
      );
      return;
    }

    // Se il filtro di quel tipo era spento, lo riaccende per mostrarlo.
    if (!_isKindVisible(target.kind)) {
      _setKindVisible(target.kind, true);
    }
    _rebuildMarkers();
    // Lascia che la mappa disegni i marker prima di selezionare.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    await _selectPlace(target, zoom: 17);
  }

  Future<void> _openDirections(_MapPlace place, String travelMode) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${place.position.latitude},${place.position.longitude}'
      '&travelmode=$travelMode',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Scheda in basso con le opzioni per raggiungere il punto selezionato.
  Widget _selectedCard(_MapPlace place) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: place.color.withOpacity(0.14),
                child: Icon(place.icon, color: place.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bluNotte,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.address.trim().isEmpty
                          ? place.kindLabel
                          : '${place.kindLabel} · ${place.address}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    DistanceLabel(target: place.position, suffix: true),
                  ],
                ),
              ),
              IconButton(
                tooltip: _l.close,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => setState(() => _selected = null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openDirections(place, 'walking'),
                  icon: const Icon(Icons.directions_walk, size: 20),
                  label: Text(_l.t('walkBtn')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rossoGubbio,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDirections(place, 'driving'),
                  icon: const Icon(Icons.directions_car, size: 20),
                  label: Text(_l.t('carBtn')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.rossoGubbio,
                    side: const BorderSide(color: AppColors.rossoGubbio),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: place.detailOpener(context),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.bluNotte,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                child: Text(_l.t('detailsBtn'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: widget.focus?.position ?? _gubbioCenter,
              zoom: widget.focus != null ? 17 : 14,
            ),
            circles: {
              if (_selected != null)
                Circle(
                  circleId: const CircleId('selected_place'),
                  center: _selected!.position,
                  radius: 40,
                  fillColor: _selected!.color.withOpacity(0.22),
                  strokeColor: _selected!.color,
                  strokeWidth: 3,
                ),
            },
            mapType: _currentMapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            markers: _markers,
            onTap: (_) {
              if (_selected != null) setState(() => _selected = null);
            },
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
                    child: Text(
                      _l.t('mapOfGubbio'),
                      style: const TextStyle(
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
                child: HintedChipRow(
                  height: 44,
                  fadeColor: null, // sopra la mappa: solo la freccia, niente sfumatura
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                      _kindChip(MapKind.restaurant, _l.restaurantsNav,
                          Icons.restaurant_menu),
                      const SizedBox(width: 10),
                      _kindChip(MapKind.bar, _l.barsNav, Icons.local_cafe_outlined),
                      const SizedBox(width: 10),
                      _kindChip(MapKind.hotel, _l.hotelsNav, Icons.hotel_outlined),
                      const SizedBox(width: 10),
                      _kindChip(MapKind.event, _l.t('mapEventsToday'), Icons.event),
                      const SizedBox(width: 10),
                      _kindChip(MapKind.itinerary, _l.t('mapItinerari'), Icons.route),
                  ],
                ),
              ),
            ),
          ),

          // Scheda del punto selezionato (indicazioni a piedi / in auto)
          if (_selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _selectedCard(_selected!),
                ),
              ),
            ),

          // Legenda
          if (_selected == null)
            Positioned(
              left: 16,
              bottom: 170,
              child: _legendCard(),
            ),

          // Map type
          Positioned(
            bottom: _selected != null ? 190 : 100,
            left: 16,
            child: _circleButton(
              icon: Icons.layers_outlined,
              color: AppColors.rossoGubbio,
              onTap: _showMapTypeDialog,
            ),
          ),

          // GPS
          Positioned(
            bottom: _selected != null ? 190 : 100,
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

  /// Chip per accendere / spegnere un tipo di punto sulla mappa.
  Widget _kindChip(String kind, String label, IconData icon) {
    return _filterChip(
      label: label,
      icon: icon,
      selected: _isKindVisible(kind),
      onTap: () {
        setState(() => _setKindVisible(kind, !_isKindVisible(kind)));
        _rebuildMarkers();
      },
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
          _legendRow(_restaurantColor, _l.restaurantsNav),
          const SizedBox(height: 6),
          _legendRow(_barColor, _l.barsNav),
          const SizedBox(height: 6),
          _legendRow(_hotelColor, _l.hotelsNav),
          const SizedBox(height: 6),
          _legendRow(_eventColor, _l.t('mapEventsToday')),
          const SizedBox(height: 6),
          _legendRow(_itineraryColor, _l.t('mapItinerari')),
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
    final granted = await _locationService.ensureLocationPermission(context);
    if (!granted) return;

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
