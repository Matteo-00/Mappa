import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/luogo_model.dart';
import '../services/content_service.dart';
import '../services/favorites_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import '../widgets/favorite_button.dart';
import '../widgets/full_photo.dart';
import '../widgets/premium_scaffold.dart';
import 'bar_detail_page.dart';
import 'event_detail_page.dart';
import 'hotel_detail_page.dart';
import 'itinerario_detail_page.dart';
import 'luogo_detail_page.dart';
import 'map_page.dart' show MapKind;
import 'restaurant_detail_page.dart';

/// Una riga dell'elenco dei preferiti.
class _FavItem {
  final String kind;
  final String id;
  final String title;
  final String? imageUrl;
  final IconData icon;
  final Widget Function() page;

  const _FavItem(
      this.kind, this.id, this.title, this.imageUrl, this.icon, this.page);
}

/// "I miei preferiti": le schede salvate con il cuore, divise per tipo.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Map<String, _FavItem> _all = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lang = context.read<LanguageService>().currentLanguageCode;
    final kinds = FavoritesService.instance.items
        .map((k) => k.split(':').first)
        .toSet();
    final luoghiKinds = LuogoTipo.values.map((t) => t.db).toSet();
    final all = <String, _FavItem>{};
    void add(_FavItem i) => all[FavoritesService.keyFor(i.kind, i.id)] = i;

    await Future.wait([
      if (kinds.contains(MapKind.restaurant))
        ContentService.fetchRestaurants(languageCode: lang).then((list) {
          for (final r in list) {
            add(_FavItem(MapKind.restaurant, r.id, r.name, r.imageUrl,
                Icons.restaurant_menu, () => RestaurantDetailPage(restaurant: r)));
          }
        }),
      if (kinds.contains(MapKind.bar))
        ContentService.fetchBars(languageCode: lang).then((list) {
          for (final b in list) {
            add(_FavItem(MapKind.bar, b.id, b.name, b.imageUrl,
                Icons.local_cafe_outlined, () => BarDetailPage(bar: b)));
          }
        }),
      if (kinds.contains(MapKind.hotel))
        ContentService.fetchHotels(languageCode: lang).then((list) {
          for (final h in list) {
            add(_FavItem(MapKind.hotel, h.id, h.name, h.imageUrl,
                Icons.hotel_outlined, () => HotelDetailPage(hotel: h)));
          }
        }),
      if (kinds.any(luoghiKinds.contains))
        ContentService.fetchLuoghi(languageCode: lang).then((list) {
          for (final l in list) {
            add(_FavItem(l.tipo.db, l.id, l.name, l.imageUrl, l.tipo.icon,
                () => LuogoDetailPage(luogo: l)));
          }
        }),
      if (kinds.contains(MapKind.itinerary))
        ContentService.fetchItinerari(languageCode: lang).then((list) {
          for (final it in list) {
            add(_FavItem(MapKind.itinerary, it.id, it.titolo, it.imageUrl,
                it.icona, () => ItinerarioDetailPage(itinerario: it)));
          }
        }),
      if (kinds.contains(MapKind.event))
        ContentService.fetchEvents(languageCode: lang).then((list) {
          for (final e in list) {
            add(_FavItem(MapKind.event, e.id, e.title, e.imageUrl,
                Icons.event_outlined, () => EventDetailPage(event: e)));
          }
        }),
    ]);
    if (!mounted) return;
    setState(() {
      _all = all;
      _loading = false;
    });
  }

  String _sectionTitle(AppLocalizations l, String kind) {
    switch (kind) {
      case MapKind.restaurant:
        return l.restaurantsNav;
      case MapKind.bar:
        return l.barsNav;
      case MapKind.hotel:
        return l.hotelsNav;
      case MapKind.itinerary:
        return l.t('mapItinerari');
      case MapKind.event:
        return l.events;
      default:
        final tipo = LuogoTipoInfo.parse(kind);
        return tipo == null ? kind : l.t(tipo.navKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          PremiumHeader(title: l.t('favTitle')),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.rossoGubbio))
                : ListenableBuilder(
                    listenable: FavoritesService.instance,
                    builder: (context, _) => _buildList(l),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppLocalizations l) {
    // Solo i preferiti ancora esistenti (una scheda eliminata sparisce).
    final items = [
      for (final k in FavoritesService.instance.items)
        if (_all[k] != null) _all[k]!,
    ];
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(32, 70, 32, 32),
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 64, color: AppColors.tortora.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            l.t('favEmptyTitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.t('favEmptyText'),
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14.5, height: 1.5, color: AppColors.textMuted),
          ),
        ],
      );
    }

    // Raggruppati per tipo, nell'ordine in cui compare il primo di ogni tipo.
    final groups = <String, List<_FavItem>>{};
    for (final i in items) {
      groups.putIfAbsent(i.kind, () => []).add(i);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 14, 0, 8),
            child: Text(
              _sectionTitle(l, entry.key).toUpperCase(),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (final i in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildTile(i),
            ),
        ],
      ],
    );
  }

  Widget _buildTile(_FavItem i) {
    final fallback = ColoredBox(
      color: AppColors.grigioChiaro,
      child: Icon(i.icon, color: AppColors.rossoGubbio),
    );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => i.page()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: i.imageUrl != null
                      ? FullPhoto(url: i.imageUrl!, fallback: fallback)
                      : fallback,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  i.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bluNotte,
                  ),
                ),
              ),
              FavoriteButton(kind: i.kind, id: i.id, light: true),
            ],
          ),
        ),
      ),
    );
  }
}
