import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/luogo_model.dart';
import '../models/storia_model.dart';
import '../pages/bar_detail_page.dart';
import '../pages/event_detail_page.dart';
import '../pages/hotel_detail_page.dart';
import '../pages/itinerario_detail_page.dart';
import '../pages/luogo_detail_page.dart';
import '../pages/restaurant_detail_page.dart';
import '../pages/storia_detail_page.dart';
import '../pages/tappa_detail_page.dart';
import 'content_service.dart';

/// Sezioni dei risultati, nell'ordine in cui compaiono.
enum SearchSection {
  eventi,
  notizie,
  ristoranti,
  bar,
  hotel,
  luoghi,
  infoUtili,
  itinerari,
  storia,
}

/// Un risultato della ricerca: cosa mostrare e quale pagina aprire.
class SearchResult {
  final SearchSection section;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imageUrl;
  final Widget Function() page;

  /// Più alto = più pertinente (titolo che inizia con il testo cercato...).
  final int score;

  const SearchResult({
    required this.section,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
    required this.score,
    this.imageUrl,
  });
}

/// Un elemento cercabile: i testi su cui cercare (già normalizzati) e il
/// risultato da mostrare.
class _Entry {
  final String title;
  final String other;
  final SearchResult Function(int score) build;
  const _Entry(this.title, this.other, this.build);
}

/// Ricerca in tutta l'app: ristoranti, bar, hotel, luoghi, eventi,
/// itinerari (con le tappe) e Storia di Gubbio.
///
/// I contenuti si caricano una volta per lingua (anche dalla copia salvata
/// in modalità offline) e la ricerca avviene sul telefono, mentre si scrive.
class SearchService {
  SearchService._();

  static String? _loadedLanguage;
  static List<_Entry> _entries = [];

  /// Toglie maiuscole, accenti e apostrofi: "Città" e "citta" sono uguali.
  static String normalize(String s) {
    const from = 'àáâäãåèéêëìíîïòóôöõùúûüçñ';
    const to = 'aaaaaaeeeeiiiiooooouuuucn';
    final lower = s.toLowerCase();
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf
        .toString()
        .replaceAll(RegExp(r"[’'`´]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Carica (o ricarica, se è cambiata la lingua) tutti i contenuti.
  static Future<void> load(String languageCode, AppLocalizations l,
      {bool force = false}) async {
    if (!force && _loadedLanguage == languageCode && _entries.isNotEmpty) {
      return;
    }
    final months = l.list('monthsShort');
    final entries = <_Entry>[];
    String join(Iterable<String?> parts) =>
        normalize(parts.whereType<String>().join(' '));

    await Future.wait([
      ContentService.fetchRestaurants(languageCode: languageCode).then((list) {
        for (final r in list) {
          entries.add(_Entry(
            normalize(r.name),
            join([r.description, r.address, ...r.cuisineTypes]),
            (score) => SearchResult(
              section: SearchSection.ristoranti,
              title: r.name,
              subtitle: r.address,
              icon: Icons.restaurant_menu,
              imageUrl: r.imageUrl,
              score: score,
              page: () => RestaurantDetailPage(restaurant: r),
            ),
          ));
        }
      }),
      ContentService.fetchBars(languageCode: languageCode).then((list) {
        for (final b in list) {
          entries.add(_Entry(
            normalize(b.name),
            join([b.description, b.address, ...b.cuisineTypes]),
            (score) => SearchResult(
              section: SearchSection.bar,
              title: b.name,
              subtitle: b.address,
              icon: Icons.local_cafe_outlined,
              imageUrl: b.imageUrl,
              score: score,
              page: () => BarDetailPage(bar: b),
            ),
          ));
        }
      }),
      ContentService.fetchHotels(languageCode: languageCode).then((list) {
        for (final h in list) {
          entries.add(_Entry(
            normalize(h.name),
            join([h.description, h.address, ...h.cuisineTypes]),
            (score) => SearchResult(
              section: SearchSection.hotel,
              title: h.name,
              subtitle: h.address,
              icon: Icons.hotel_outlined,
              imageUrl: h.imageUrl,
              score: score,
              page: () => HotelDetailPage(hotel: h),
            ),
          ));
        }
      }),
      ContentService.fetchLuoghi(languageCode: languageCode).then((list) {
        for (final p in list) {
          final kind = l.t(p.tipo.kindKey);
          entries.add(_Entry(
            normalize(p.name),
            join([p.description, p.address, kind, ...p.tags]),
            (score) => SearchResult(
              section: p.tipo.isUsefulInfo
                  ? SearchSection.infoUtili
                  : SearchSection.luoghi,
              title: p.name,
              subtitle:
                  p.address.trim().isEmpty ? kind : '$kind · ${p.address}',
              icon: p.tipo.icon,
              imageUrl: p.imageUrl,
              score: score,
              page: () => LuogoDetailPage(luogo: p),
            ),
          ));
        }
      }),
      ContentService.fetchEvents(languageCode: languageCode).then((list) {
        final now = DateTime.now();
        for (final e in list) {
          // Le bozze (eventi importati da approvare) non si cercano.
          if (e.isDraft) continue;
          final d = e.startTime;
          final when = '${d.day} ${months[d.month - 1]} ${d.year}';
          final past = e.endTime.isBefore(now);
          entries.add(_Entry(
            normalize(e.title),
            join([e.description, e.location, e.category]),
            (score) => SearchResult(
              section: e.isNews ? SearchSection.notizie : SearchSection.eventi,
              title: e.title,
              subtitle: [when, if (e.location.trim().isNotEmpty) e.location]
                  .join(' · '),
              icon: e.isNews ? Icons.newspaper_outlined : Icons.event_outlined,
              imageUrl: e.imageUrl,
              // Gli eventi già conclusi vengono dopo quelli in programma.
              score: past && !e.isNews ? score - 15 : score,
              page: () => EventDetailPage(event: e),
            ),
          ));
        }
      }),
      ContentService.fetchItinerari(languageCode: languageCode).then((list) {
        for (final it in list) {
          entries.add(_Entry(
            normalize(it.titolo),
            join([it.sottotitolo, it.descrizione, it.tema, it.durata]),
            (score) => SearchResult(
              section: SearchSection.itinerari,
              title: it.titolo,
              subtitle: [it.durata, l.count('homeStops', it.tappe.length)]
                  .where((s) => s.trim().isNotEmpty)
                  .join(' · '),
              icon: it.icona,
              imageUrl: it.imageUrl,
              score: score,
              page: () => ItinerarioDetailPage(itinerario: it),
            ),
          ));
          // Anche le singole tappe ("Basilica di Sant'Ubaldo" dentro un
          // itinerario).
          for (var i = 0; i < it.tappe.length; i++) {
            final t = it.tappe[i];
            entries.add(_Entry(
              normalize(t.nome),
              join([t.descrizione, t.approfondimento]),
              (score) => SearchResult(
                section: SearchSection.itinerari,
                title: t.nome,
                subtitle: '${l.t('searchStopOf')} ${it.titolo}',
                icon: Icons.flag_outlined,
                score: score - 5,
                page: () => TappaDetailPage(itinerario: it, index: i),
              ),
            ));
          }
        }
      }),
      Future.wait([
        ContentService.fetchStoriaEpoche(languageCode: languageCode),
        ContentService.fetchStoriaContenuti(languageCode: languageCode),
      ]).then((res) {
        final epoche = {
          for (final e in (res[0] as List).cast<StoriaEpoca>()) e.id: e
        };
        for (final c in (res[1] as List).cast<StoriaContenuto>()) {
          if (!c.isPublished) continue;
          final epoca = epoche[c.eraId];
          entries.add(_Entry(
            normalize(c.title),
            join([
              c.shortDescription,
              c.fullDescription,
              c.localStory,
              c.curiosity,
              epoca?.nome,
              ...c.tags,
            ]),
            (score) => SearchResult(
              section: SearchSection.storia,
              title: c.title,
              subtitle: [c.displayDate, epoca?.nome]
                  .whereType<String>()
                  .where((s) => s.trim().isNotEmpty)
                  .join(' · '),
              icon: Icons.auto_stories_outlined,
              imageUrl: c.coverImage,
              score: score,
              page: () => StoriaDetailPage(contenuto: c, epoca: epoca),
            ),
          ));
        }
      }),
    ]);

    _entries = entries;
    _loadedLanguage = languageCode;
  }

  /// Risultati per [query], dal più pertinente. Servono almeno 2 lettere.
  static List<SearchResult> search(String query) {
    final q = normalize(query);
    if (q.length < 2) return [];
    final words = q.split(' ');
    final results = <SearchResult>[];
    for (final e in _entries) {
      // Ogni parola deve comparire nel titolo o negli altri testi.
      if (!words.every((w) => e.title.contains(w) || e.other.contains(w))) {
        continue;
      }
      var score = 0;
      if (e.title == q) {
        score = 100;
      } else if (e.title.startsWith(q)) {
        score = 80;
      } else if (e.title.contains(q)) {
        score = 60;
      } else if (words.every(e.title.contains)) {
        score = 50;
      } else {
        score = 20;
      }
      results.add(e.build(score));
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  // -------------------------------------------------- Ricerche recenti

  static const _recentKey = 'recent_searches_v1';

  static Future<List<String>> recent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_recentKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> addRecent(String query) async {
    final q = query.trim();
    if (q.length < 2) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_recentKey) ?? [];
      list.removeWhere((s) => s.toLowerCase() == q.toLowerCase());
      list.insert(0, q);
      await prefs.setStringList(_recentKey, list.take(8).toList());
    } catch (_) {
      // Non indispensabile.
    }
  }

  static Future<void> clearRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentKey);
    } catch (_) {}
  }
}
