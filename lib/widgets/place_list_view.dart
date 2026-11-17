import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/gubbio_boundary.dart';
import '../l10n/app_localizations.dart';
import '../models/review_model.dart';
import '../pages/admin/admin_widgets.dart';
import '../pages/map_page.dart';
import '../services/language_service.dart';
import '../services/user_location_service.dart';
import '../theme/app_colors.dart';
import 'distance_label.dart';
import 'favorite_button.dart';
import 'full_photo.dart';
import 'premium_scaffold.dart';
import 'rating_icons.dart';
import 'user_rating_badge.dart';

/// Dati di una scheda della lista (ristorante, bar, hotel, chiesa, ...).
class PlaceCardData {
  final String id;
  final String name;
  final String description;
  final String address;
  final LatLng coordinates;
  final String? imageUrl;
  final String? phone;
  final List<String> tags;
  final double? rating;
  final ReviewStats? userStats;

  /// Tipo per i preferiti (null = niente cuore, es. dati non ancora salvati).
  final String? favoriteKind;
  final VoidCallback onTap;

  /// Solo admin: modifica / elimina (null = pulsanti nascosti).
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PlaceCardData({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.coordinates,
    required this.onTap,
    this.imageUrl,
    this.phone,
    this.tags = const [],
    this.rating,
    this.userStats,
    this.favoriteKind,
    this.onEdit,
    this.onDelete,
  });
}

/// Pagina-lista comune a ristoranti, bar, hotel e luoghi (chiese, musei,
/// negozi, sport, agriturismi, parcheggi, ascensori, bagni):
/// barra in alto in vetro chiaro, mappa piccola che si ingrandisce, ricerca,
/// filtri, avviso posizione (una volta sola) e schede con foto grande, voti
/// su una riga e pulsanti rapidi "Chiama" / "Indicazioni".
///
/// Cambiando questo file cambiano tutte le sezioni insieme.
class PlaceListView extends StatefulWidget {
  final String title;

  /// Pulsante in più nella barra in alto (es. "+" per gli admin).
  final Widget? headerAction;

  final IconData fallbackIcon;
  final RatingKind ratingKind;

  /// false per i luoghi senza valutazione (chiese, musei, parcheggi...).
  final bool showRating;

  /// Schede compatte senza foto grande (parcheggi, ascensori, bagni: conta
  /// dove sono, non com'è la foto).
  final bool compactCards;

  final Set<Marker> markers;
  final ValueChanged<GoogleMapController> onMapCreated;

  final TextEditingController searchController;
  final String searchHint;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  /// Barra dei filtri ([PlaceFilterBar]).
  final Widget filterBar;

  final List<PlaceCardData> items;
  final bool locationAvailable;

  /// Cosa mostrare quando la lista è vuota.
  final Widget emptyState;

  const PlaceListView({
    super.key,
    required this.title,
    required this.fallbackIcon,
    required this.markers,
    required this.onMapCreated,
    required this.searchController,
    required this.searchHint,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.filterBar,
    required this.items,
    required this.locationAvailable,
    required this.emptyState,
    this.headerAction,
    this.ratingKind = RatingKind.crescia,
    this.showRating = true,
    this.compactCards = false,
  });

  @override
  State<PlaceListView> createState() => _PlaceListViewState();
}

class _PlaceListViewState extends State<PlaceListView> {
  static const LatLng _centerGubbio = LatLng(43.35190, 12.57730);
  static const double _mapSmall = 132;
  static const double _mapBig = 340;

  bool _bigMap = false;

  AppLocalizations get _l => AppLocalizations.of(
      context.watch<LanguageService>().currentLanguageCode);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final l = _l;
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
                top: top + 74,
                bottom: 24 + MediaQuery.of(context).padding.bottom),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              _buildMap(l),
              _buildSearchBar(),
              widget.filterBar,
              _LocationBanner(visible: !widget.locationAvailable),
              if (widget.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: widget.emptyState,
                )
              else
                for (final item in widget.items)
                  widget.compactCards
                      ? _CompactPlaceCard(
                          data: item, fallbackIcon: widget.fallbackIcon)
                      : _PlaceCard(
                          data: item,
                          fallbackIcon: widget.fallbackIcon,
                          ratingKind: widget.ratingKind,
                          showRating: widget.showRating,
                        ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassHeader(
              title: widget.title,
              trailing: widget.headerAction,
            ),
          ),
        ],
      ),
    );
  }

  /// Mappa piccola di default; "Mostra mappa" la ingrandisce.
  Widget _buildMap(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          height: _bigMap ? _mapBig : _mapSmall,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition:
                    const CameraPosition(target: _centerGubbio, zoom: 15),
                onMapCreated: widget.onMapCreated,
                markers: widget.markers,
                polygons: {
                  Polygon(
                    polygonId: const PolygonId('gubbio_municipal_boundary'),
                    points: gubbioMunicipalBoundary,
                    strokeWidth: 4,
                    strokeColor: Colors.red,
                    fillColor: Colors.red.withValues(alpha: 0.05),
                    geodesic: true,
                  ),
                },
                // La mappa si muove con il dito anche dentro la lista.
                gestureRecognizers: {
                  Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer()),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Material(
                  color: Colors.white,
                  elevation: 3,
                  shadowColor: Colors.black26,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () => setState(() => _bigMap = !_bigMap),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _bigMap
                                ? Icons.close_fullscreen_rounded
                                : Icons.open_in_full_rounded,
                            size: 16,
                            color: AppColors.rossoGubbio,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l.t(_bigMap ? 'mapHide' : 'mapShow'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bluNotte,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: widget.searchController,
        onChanged: widget.onSearchChanged,
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.rossoGubbio),
          suffixIcon: widget.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.tortora),
                  onPressed: () {
                    widget.searchController.clear();
                    widget.onSearchChanged('');
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
}

// ============================================================ barra in alto

/// Barra in alto in "vetro chiaro" (come il pannello della home): il
/// contenuto che scorre sotto si intravede sfocato. Va messa in uno Stack
/// sopra una lista che lascia spazio in alto.
class GlassHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const GlassHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canGoBack = showBackButton(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: EdgeInsets.fromLTRB(16, top + 10, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.avorio.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                  color: AppColors.bluNotte.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            children: [
              if (canGoBack) ...[
                const BackCircleButton(),
                const SizedBox(width: 8),
              ],
              const HomeButton(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: AppColors.bluNotte,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================ avviso posizione

/// "Abilita la posizione per vedere la distanza": una volta sola in cima alla
/// lista invece che su ogni scheda.
class _LocationBanner extends StatelessWidget {
  final bool visible;
  const _LocationBanner({required this.visible});

  @override
  Widget build(BuildContext context) {
    final service = UserLocationService.instance;
    final l = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (!visible || !service.checked || service.position != null) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 6),
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          decoration: BoxDecoration(
            color: AppColors.bluNotte.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.near_me_outlined,
                  size: 20, color: AppColors.bluNotte),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  service.availability == LocationAvailability.serviceDisabled
                      ? l.t('enableGpsForDistance')
                      : l.t('enableLocationForDistance'),
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.bluNotte,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => service.enable(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppColors.rossoGubbio,
                  shape: const StadiumBorder(),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Text(l.t('locBannerBtn'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================ azioni

Future<void> openWalkingDirections(LatLng p) async {
  final url = Uri.parse('https://www.google.com/maps/dir/?api=1'
      '&destination=${p.latitude},${p.longitude}&travelmode=walking');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

Future<void> callPhone(String phone) async {
  final url = Uri.parse('tel:${phone.replaceAll(' ', '')}');
  if (await canLaunchUrl(url)) await launchUrl(url);
}

/// Pulsantino a pillola ("Chiama", "Indicazioni") sulle schede.
class PlaceActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PlaceActionChip(
      {super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.avorio,
      shape: const StadiumBorder(
          side: BorderSide(color: AppColors.grigioChiaro)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: AppColors.rossoGubbio),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluNotte,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================ schede

/// Pulsanti admin (modifica / elimina) se previsti.
Widget? _adminButtons(PlaceCardData d) {
  if (d.onEdit == null && d.onDelete == null) return null;
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (d.onEdit != null) EditIconButton(onPressed: d.onEdit!),
      if (d.onEdit != null && d.onDelete != null) const SizedBox(width: 6),
      if (d.onDelete != null) DeleteIconButton(onPressed: d.onDelete!),
    ],
  );
}

/// Scheda con foto grande larga quanto la scheda.
class _PlaceCard extends StatelessWidget {
  final PlaceCardData data;
  final IconData fallbackIcon;
  final RatingKind ratingKind;
  final bool showRating;

  const _PlaceCard({
    required this.data,
    required this.fallbackIcon,
    required this.ratingKind,
    required this.showRating,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final d = data;
    final placeholder = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tortora.withValues(alpha: 0.45), AppColors.avorio],
        ),
      ),
      child: Center(
        child: Icon(fallbackIcon,
            size: 52, color: AppColors.rossoGubbio.withValues(alpha: 0.55)),
      ),
    );
    final admin = _adminButtons(d);
    final hasRating = showRating && d.rating != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: d.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto grande
              SizedBox(
                height: d.imageUrl != null ? 170 : 120,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (d.imageUrl != null)
                      FullPhoto(url: d.imageUrl!, fallback: placeholder)
                    else
                      placeholder,
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x33000000), Color(0x00000000)],
                          stops: [0, 0.45],
                        ),
                      ),
                    ),
                    if (d.tags.isNotEmpty)
                      Positioned(
                        left: 12,
                        top: 12,
                        right: 70,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              d.tags.first.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 0.9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.rossoGubbio,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (d.favoriteKind != null)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: FavoriteButton(kind: d.favoriteKind!, id: d.id),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            d.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                              color: AppColors.bluNotte,
                            ),
                          ),
                        ),
                        if (admin != null) admin,
                      ],
                    ),
                    if (d.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        d.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.3,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    // Voti su una riga sola: Visit Gubbio + utenti.
                    if (hasRating || d.userStats != null) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (hasRating)
                            RatingSummary(rating: d.rating!, kind: ratingKind),
                          if (d.userStats != null)
                            UserRatingBadge(stats: d.userStats!),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    // Pulsanti rapidi e distanza.
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if (d.phone != null && d.phone!.trim().isNotEmpty)
                                PlaceActionChip(
                                  icon: Icons.call_outlined,
                                  label: l.t('actCall'),
                                  onTap: () => callPhone(d.phone!),
                                ),
                              PlaceActionChip(
                                icon: Icons.directions_outlined,
                                label: l.t('actDirections'),
                                onTap: () =>
                                    openWalkingDirections(d.coordinates),
                              ),
                            ],
                          ),
                        ),
                        DistanceLabel(
                            target: d.coordinates, showPrompt: false),
                        const SizedBox(width: 4),
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
}

/// Scheda compatta (parcheggi, ascensori, bagni): icona, nome, indirizzo,
/// distanza e "Indicazioni".
class _CompactPlaceCard extends StatelessWidget {
  final PlaceCardData data;
  final IconData fallbackIcon;

  const _CompactPlaceCard({required this.data, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final d = data;
    final admin = _adminButtons(d);
    final icon = Icon(fallbackIcon, size: 30, color: AppColors.rossoGubbio);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: d.onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.rossoGubbio.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: d.imageUrl != null
                      ? FullPhoto(url: d.imageUrl!, fallback: Center(child: icon))
                      : Center(child: icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.bluNotte,
                        ),
                      ),
                      if (d.address.trim().isNotEmpty)
                        Text(
                          d.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          PlaceActionChip(
                            icon: Icons.directions_outlined,
                            label: l.t('actDirections'),
                            onTap: () => openWalkingDirections(d.coordinates),
                          ),
                          const Spacer(),
                          DistanceLabel(
                              target: d.coordinates, showPrompt: false),
                        ],
                      ),
                    ],
                  ),
                ),
                if (admin != null) admin,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsante della barra in alto che apre la mappa grande dell'app.
class HeaderMapButton extends StatelessWidget {
  const HeaderMapButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const MapPage())),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.map_outlined,
              color: AppColors.rossoGubbio, size: 22),
        ),
      ),
    );
  }
}
