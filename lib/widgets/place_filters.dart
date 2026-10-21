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
enum PlaceSort { nearest, ratingDesc, ratingAsc, name }

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
  }) {
    final q = query.trim().toLowerCase();

    final result = items.where((p) {
      if (state.tag != null && !tags(p).contains(state.tag)) return false;
      if (state.topRatedOnly && (rating(p) ?? 0) < 4) return false;
      if (q.isEmpty) return true;
      return name(p).toLowerCase().contains(q) ||
          description(p).toLowerCase().contains(q) ||
          tags(p).any((t) => t.toLowerCase().contains(q));
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
    case PlaceSort.name:
      return l.t('sortName');
  }
}

AppLocalizations _l10n(BuildContext context) => AppLocalizations.of(
    context.read<LanguageService>().currentLanguageCode);

/// Barra dei filtri: ordinamento, "più vicini a me", "4+ stelle" e tag.
/// Modifica direttamente [state] e poi chiama [onChanged].
class PlaceFilterBar extends StatelessWidget {
  final PlaceFilterState state;
  final List<String> availableTags;
  final bool locationAvailable;
  final int resultCount;
  final VoidCallback onChanged;

  const PlaceFilterBar({
    super.key,
    required this.state,
    required this.availableTags,
    required this.locationAvailable,
    required this.resultCount,
    required this.onChanged,
  });

  /// "Più vicini a me": ordina dal più vicino al più lontano. Se la posizione
  /// non è attiva la chiede; se era già attivo torna all'ordine per stelle.
  Future<void> _toggleNearest(BuildContext context) async {
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
    state.sort = state.sort == PlaceSort.nearest
        ? PlaceSort.ratingDesc
        : PlaceSort.nearest;
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
            AppFilterChip(
              label: _l10n(context).t('nearestToMe'),
              icon: locationAvailable
                  ? Icons.near_me_rounded
                  : Icons.location_off_outlined,
              selected: locationAvailable && state.sort == PlaceSort.nearest,
              onTap: () => _toggleNearest(context),
            ),
            const SizedBox(width: 8),
            AppFilterChip(
              label: '4+',
              leading: const CresciaIcon(size: 14),
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

  /// Chip che apre il menu degli ordinamenti.
  Widget _sortChip(BuildContext context) {
    return PopupMenuButton<PlaceSort>(
      tooltip: _l10n(context).t('sortLabel'),
      initialValue: state.sort,
      onSelected: (v) {
        state.sort = v;
        onChanged();
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: PlaceSort.nearest,
          enabled: locationAvailable,
          child: Text(locationAvailable
              ? _l10n(context).t('nearestToMe')
              : _l10n(context).t('sortMenuNearestNoLoc')),
        ),
        PopupMenuItem(
          value: PlaceSort.ratingDesc,
          child: Text(_l10n(context).t('sortMenuRatingDesc')),
        ),
        PopupMenuItem(
          value: PlaceSort.ratingAsc,
          child: Text(_l10n(context).t('sortMenuRatingAsc')),
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
              _sortLabel(_l10n(context), state.sort),
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
