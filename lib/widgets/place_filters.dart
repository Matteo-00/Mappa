import '../utils/text_match.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../services/user_location_service.dart';
import '../theme/app_colors.dart';
import 'app_filter_chip.dart';
import 'rating_icons.dart';
import 'scroll_hints.dart';

/// Ordinamenti disponibili per ristoranti, bar e hotel.
enum PlaceSort { nearest, ratingDesc, ratingAsc, userRating, name }

/// Stato dei filtri di una lista di luoghi (ristoranti, bar, hotel).
class PlaceFilterState {
  PlaceSort sort = PlaceSort.nearest;

  /// Solo i luoghi con 4 stelle o più.
  bool topRatedOnly = false;

  /// Tag selezionato (es. "Pizzeria"), null = tutti.
  String? tag;

  bool get hasActiveFilters => topRatedOnly || tag != null;

  void reset() {
    topRatedOnly = false;
    tag = null;
  }

  /// Un tag che non esiste più (es. dopo un cambio lingua i tag arrivano
  /// tradotti) viene azzerato, altrimenti la lista resterebbe vuota.
  void dropMissingTag(Iterable<List<String>> allTags) {
    if (tag != null && !allTags.any((tags) => tags.contains(tag))) tag = null;
  }
}

/// Logica di filtro/ordinamento comune, indipendente dal tipo di luogo.
class PlaceFilters {
  PlaceFilters._();

  static List<T> apply<T>(
    List<T> items, {
    required PlaceFilterState state,
    required String query,
    required String Function(T) name,
    required String Function(T) description,
    required List<String> Function(T) tags,
    required double? Function(T) rating,
    required double? Function(T) distance, // metri, null se posizione ignota
    // Media e numero delle recensioni degli utenti (null = nessuna).
    double? Function(T)? userRating,
    int Function(T)? userCount,
  }) {
    final q = query;

    final result = items.where((p) {
      if (state.tag != null && !tags(p).contains(state.tag)) return false;
      // "4+": basta il voto di Visit Gubbio OPPURE la media degli utenti.
      if (state.topRatedOnly &&
          (rating(p) ?? 0) < 4 &&
          (userRating?.call(p) ?? 0) < 4) {
        return false;
      }
      return textMatches(q, [name(p), description(p), ...tags(p)]);
    }).toList();

    // Senza posizione "più vicini" non è calcolabile: si ordina per stelle.
    var sort = state.sort;
    final hasLocation = items.any((p) => distance(p) != null);
    if (sort == PlaceSort.nearest && !hasLocation) sort = PlaceSort.ratingDesc;

    int byName(T a, T b) =>
        name(a).toLowerCase().compareTo(name(b).toLowerCase());

    result.sort((a, b) {
      int c;
      switch (sort) {
        case PlaceSort.nearest:
          c = (distance(a) ?? double.infinity)
              .compareTo(distance(b) ?? double.infinity);
          break;
        case PlaceSort.ratingDesc:
          c = (rating(b) ?? 0).compareTo(rating(a) ?? 0);
          break;
        case PlaceSort.ratingAsc:
          // Senza voto in fondo anche in ordine crescente.
          final ra = rating(a) ?? double.infinity;
          final rb = rating(b) ?? double.infinity;
          c = ra.compareTo(rb);
          break;
        case PlaceSort.userRating:
          // Prima i più votati dagli utenti; a parità, quelli con più recensioni.
          c = (userRating?.call(b) ?? -1).compareTo(userRating?.call(a) ?? -1);
          if (c == 0) c = (userCount?.call(b) ?? 0).compareTo(userCount?.call(a) ?? 0);
          break;
        case PlaceSort.name:
          c = byName(a, b);
          break;
      }
      return c != 0 ? c : byName(a, b);
    });
    return result;
  }

  /// Tag presenti nei dati, dal più usato al meno usato.
  static List<String> tagsByFrequency(Iterable<List<String>> allTags) {
    final counts = <String, int>{};
    for (final list in allTags) {
      for (final tag in list) {
        final t = tag.trim();
        if (t.isNotEmpty) counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
  }
}

String _sortLabel(AppLocalizations l, PlaceSort sort) {
  switch (sort) {
    case PlaceSort.nearest:
      return l.t('sortNearest');
    case PlaceSort.ratingDesc:
      return l.t('sortRatingDesc');
    case PlaceSort.ratingAsc:
      return l.t('sortRatingAsc');
    case PlaceSort.userRating:
      return l.t('sortUserRating');
    case PlaceSort.name:
      return l.t('sortName');
  }
}

AppLocalizations _l10n(BuildContext context) => AppLocalizations.of(
    context.read<LanguageService>().currentLanguageCode);

/// Barra dei filtri: ordinamento, "più vicini a me", "4+ stelle" e tag.
/// Modifica direttamente [state] e poi chiama [onChanged].
class PlaceFilterBar extends StatelessWidget {
  /// Icona usata per le valutazioni di questo tipo di luogo (crescia, amaro, palazzo).
  final RatingKind ratingKind;

  /// false per i luoghi senza valutazione (chiese, musei, parcheggi): niente
  /// ordinamento per stelle né chip "4+".
  final bool showRating;
  final PlaceFilterState state;
  final List<String> availableTags;
  final bool locationAvailable;
  final int resultCount;
  final VoidCallback onChanged;

  /// Mostra l'ordinamento "più votati dagli utenti" (se ci sono recensioni).
  final bool showUserRating;

  const PlaceFilterBar({
    super.key,
    this.ratingKind = RatingKind.crescia,
    this.showRating = true,
    this.showUserRating = false,
    required this.state,
    required this.availableTags,
    required this.locationAvailable,
    required this.resultCount,
    required this.onChanged,
  });

  /// "Più vicini a me" scelto dal menu dell'ordinamento: se la posizione non
  /// è attiva la chiede (se l'utente non la concede l'ordine non cambia).
  Future<void> _chooseNearest(BuildContext context) async {
    if (!locationAvailable) {
      // Serve la posizione: chiede il permesso / apre le impostazioni.
      await UserLocationService.instance.enable(context);
      if (UserLocationService.instance.position == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_l10n(context).t('enableLocationSort')),
            ),
          );
        }
        return;
      }
    }
    state.sort = PlaceSort.nearest;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HintedChipRow(
          height: 48,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          children: [
            _sortChip(context),
            const SizedBox(width: 8),
            if (showRating)
              AppFilterChip(
                label: '4+',
                leading: RatingIcon(kind: ratingKind, size: 14),
                selected: state.topRatedOnly,
                onTap: () {
                  state.topRatedOnly = !state.topRatedOnly;
                  onChanged();
                },
              ),
            for (final tag in availableTags) ...[
              const SizedBox(width: 8),
              AppFilterChip(
                label: tag,
                selected: state.tag == tag,
                onTap: () {
                  state.tag = state.tag == tag ? null : tag;
                  onChanged();
                },
              ),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _l10n(context).count('result', resultCount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              if (state.hasActiveFilters)
                TextButton(
                  onPressed: () {
                    state.reset();
                    onChanged();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.rossoGubbio,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(_l10n(context).t('fltReset'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Ordine davvero usato: "più vicini" senza posizione diventa per stelle
  /// (o per nome), come in [PlaceFilters.apply].
  PlaceSort get effectiveSort => state.sort == PlaceSort.nearest &&
          !locationAvailable
      ? (showRating ? PlaceSort.ratingDesc : PlaceSort.name)
      : state.sort;

  /// Chip che apre il menu degli ordinamenti.
  Widget _sortChip(BuildContext context) {
    return PopupMenuButton<PlaceSort>(
      tooltip: _l10n(context).t('sortLabel'),
      initialValue: effectiveSort,
      onSelected: (v) {
        if (v == PlaceSort.nearest) {
          _chooseNearest(context);
          return;
        }
        state.sort = v;
        onChanged();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        // Sempre selezionabile: senza posizione la chiede.
        PopupMenuItem(
          value: PlaceSort.nearest,
          child: Row(children: [
            Icon(
              locationAvailable
                  ? Icons.near_me_rounded
                  : Icons.location_off_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(_l10n(context).t('nearestToMe')),
          ]),
        ),
        if (showRating)
          PopupMenuItem(
            value: PlaceSort.ratingDesc,
            child: Text(_l10n(context).t('sortMenuRatingDesc')),
          ),
        if (showRating)
          PopupMenuItem(
            value: PlaceSort.ratingAsc,
            child: Text(_l10n(context).t('sortMenuRatingAsc')),
          ),
        if (showUserRating)
          PopupMenuItem(
            value: PlaceSort.userRating,
            child: Text(_l10n(context).t('sortMenuUserRating')),
          ),
        PopupMenuItem(
          value: PlaceSort.name,
          child: Text(_l10n(context).t('sortMenuName')),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bluNotte,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 17, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              _sortLabel(_l10n(context), effectiveSort),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded,
                size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
