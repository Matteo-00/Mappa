import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/itinerario_model.dart';
import '../services/content_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/full_photo.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/loading_screen.dart';
import '../widgets/filter_sheet.dart';
import 'admin/admin_widgets.dart';
import 'admin/edit_itinerario_flow.dart';
import 'itinerario_detail_page.dart';

enum _ItinerarioSort { predefinito, titolo, tappe }

/// Elenco degli itinerari consigliati per visitare Gubbio: ricerca, filtri
/// per tema, difficoltà e durata, ordinamento e schede compatte.
class ItinerariPage extends StatefulWidget {
  const ItinerariPage({super.key});

  @override
  State<ItinerariPage> createState() => _ItinerariPageState();
}

class _ItinerariPageState extends State<ItinerariPage> {
  AppLocalizations get _l => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  final _searchController = TextEditingController();

  List<ItinerarioModel> _itinerari = [];
  bool _loading = true;
  String? _loadedLanguageCode;

  String _query = '';
  String? _selectedTema;
  String? _selectedDifficolta;
  String? _selectedDurata;
  _ItinerarioSort _sort = _ItinerarioSort.predefinito;

  @override
  void initState() {
    super.initState();
    _load();
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loadingStart = DateTime.now();
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = languageCode;
    final items = await ContentService.fetchItinerari(languageCode: languageCode);
    // La crescia resta almeno un secondo, così non "lampeggia".
    if (_loading) await LoadingScreen.waitMinimum(loadingStart);
    if (!mounted) return;
    setState(() {
      _itinerari = items;
      _loading = false;
      // Un filtro che non esiste più (es. cambio lingua) viene azzerato.
      if (!_distinct((i) => i.tema).contains(_selectedTema)) _selectedTema = null;
      if (!_distinct((i) => i.difficolta).contains(_selectedDifficolta)) {
        _selectedDifficolta = null;
      }
      if (!_distinct((i) => i.durata).contains(_selectedDurata)) {
        _selectedDurata = null;
      }
    });
  }

  /// Valori distinti (non vuoti) di un campo, in ordine di comparsa.
  List<String> _distinct(String Function(ItinerarioModel) field) {
    final seen = <String>{};
    for (final i in _itinerari) {
      final v = field(i).trim();
      if (v.isNotEmpty) seen.add(v);
    }
    return seen.toList();
  }

  List<ItinerarioModel> get _visible {
    final q = _query.trim().toLowerCase();
    final result = _itinerari.where((it) {
      if (_selectedTema != null && it.tema.trim() != _selectedTema) return false;
      if (_selectedDifficolta != null &&
          it.difficolta.trim() != _selectedDifficolta) {
        return false;
      }
      if (_selectedDurata != null && it.durata.trim() != _selectedDurata) {
        return false;
      }
      if (q.isEmpty) return true;
      return it.titolo.toLowerCase().contains(q) ||
          it.sottotitolo.toLowerCase().contains(q) ||
          it.descrizione.toLowerCase().contains(q) ||
          it.tappe.any((t) => t.nome.toLowerCase().contains(q));
    }).toList();

    switch (_sort) {
      case _ItinerarioSort.predefinito:
        break;
      case _ItinerarioSort.titolo:
        result.sort(
            (a, b) => a.titolo.toLowerCase().compareTo(b.titolo.toLowerCase()));
        break;
      case _ItinerarioSort.tappe:
        result.sort((a, b) => b.tappe.length.compareTo(a.tappe.length));
        break;
    }
    return result;
  }

  bool get _hasActiveFilters =>
      _query.isNotEmpty ||
      _selectedTema != null ||
      _selectedDifficolta != null ||
      _selectedDurata != null;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedTema = null;
      _selectedDifficolta = null;
      _selectedDurata = null;
    });
  }

  void _openItinerario(BuildContext context, ItinerarioModel itinerario) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItinerarioDetailPage(itinerario: itinerario),
      ),
    );
  }

  Future<void> _editItinerario(ItinerarioModel it) async {
    // Si modifica sempre l'originale italiano (vedi edit_itinerario_flow.dart).
    final updated = await editItinerarioFlow(context, it);
    if (updated != null) {
      await _load();
    }
  }

  Future<void> _deleteItinerario(ItinerarioModel it) async {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final ok = await confirmDelete(context, it.titolo);
    if (!ok) return;
    try {
      await ContentService.deleteItinerario(it.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.itinerarioDeleted),
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
    final items = _visible;
    final temi = _distinct((i) => i.tema);
    final difficolta = _distinct((i) => i.difficolta);
    final durate = _distinct((i) => i.durata);

    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          PremiumHeader(title: l10n.itinerariTitle),
          AppSearchField(
            controller: _searchController,
            hint: _l.t('itSearchHint'),
            onChanged: (v) => setState(() => _query = v),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
          ),
          // Un solo pulsante "Filtri" (tema, difficoltà, durata, ordine) al
          // posto delle file di chip: i filtri si scelgono in un pannello.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
            child: Row(
              children: [
                FilterPillButton(
                  activeCount: _activeFilterCount,
                  onTap: () => _openFilters(temi, difficolta, durate),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _l.count('itCount', items.length),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                if (_hasActiveFilters)
                  TextButton(
                    onPressed: _resetFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.rossoGubbio,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(_l.t('fltReset'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                    color: AppColors.rossoGubbio,
                    onRefresh: _load,
                    child: items.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                            itemCount: items.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildItinerarioCard(context, items[i]),
                            ),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Quanti filtri sono attivi (tema, difficoltà, durata, ordine diverso).
  int get _activeFilterCount =>
      (_selectedTema != null ? 1 : 0) +
      (_selectedDifficolta != null ? 1 : 0) +
      (_selectedDurata != null ? 1 : 0) +
      (_sort != _ItinerarioSort.predefinito ? 1 : 0);

  /// Pannello dei filtri, raggruppati: tema, difficoltà, durata, ordinamento.
  void _openFilters(
    List<String> temi,
    List<String> difficolta,
    List<String> durate,
  ) {
    Widget group({
      required IconData icon,
      required String title,
      required List<String> values,
      required String? selected,
      required void Function(String?) onChanged,
      required VoidCallback rebuild,
    }) {
      if (values.length < 2) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilterGroupTitle(icon: icon, text: title),
          FilterChipsWrap(chips: [
            for (final v in values)
              AppFilterChip(
                label: v,
                selected: selected == v,
                onTap: () {
                  setState(() => onChanged(selected == v ? null : v));
                  rebuild();
                },
              ),
          ]),
        ],
      );
    }

    showFilterSheet(
      context,
      title: _l.t('itFiltersTitle'),
      hasActiveFilters: () => _activeFilterCount > 0,
      onReset: () => setState(() {
        _selectedTema = null;
        _selectedDifficolta = null;
        _selectedDurata = null;
        _sort = _ItinerarioSort.predefinito;
      }),
      content: (ctx, rebuild) => [
        group(
          icon: Icons.palette_outlined,
          title: _l.t('itFilterTheme'),
          values: temi,
          selected: _selectedTema,
          onChanged: (v) => _selectedTema = v,
          rebuild: rebuild,
        ),
        group(
          icon: Icons.terrain_outlined,
          title: _l.t('itFilterDifficulty'),
          values: difficolta,
          selected: _selectedDifficolta,
          onChanged: (v) => _selectedDifficolta = v,
          rebuild: rebuild,
        ),
        group(
          icon: Icons.schedule,
          title: _l.t('itFilterDuration'),
          values: durate,
          selected: _selectedDurata,
          onChanged: (v) => _selectedDurata = v,
          rebuild: rebuild,
        ),
        FilterGroupTitle(
            icon: Icons.swap_vert_rounded, text: _l.t('sortLabel')),
        FilterChipsWrap(chips: [
          for (final entry in <(_ItinerarioSort, String)>[
            (_ItinerarioSort.predefinito, _l.t('itSortDefault')),
            (_ItinerarioSort.titolo, _l.t('itSortTitle')),
            (_ItinerarioSort.tappe, _l.t('itSortStops')),
          ])
            AppFilterChip(
              label: entry.$2,
              selected: _sort == entry.$1,
              onTap: () {
                setState(() => _sort = entry.$1);
                rebuild();
              },
            ),
        ]),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Scheda compatta: miniatura a sinistra, testi e dati a destra.
  Widget _buildItinerarioCard(BuildContext context, ItinerarioModel it) {
    final isAdmin = context.watch<AuthService>().isAdmin &&
        ContentService.isRemoteId(it.id);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openItinerario(context, it),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 96,
                        height: 112,
                        child: it.imageUrl != null
                            ? FullPhoto(
                                url: it.imageUrl!,
                                fallback: itinerarioImagePlaceholder(
                                  it.immagineLabel,
                                  icon: it.icona,
                                ),
                              )
                            : itinerarioImagePlaceholder(
                                it.immagineLabel,
                                icon: it.icona,
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (it.tema.trim().isNotEmpty)
                            Text(
                              it.tema.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.rossoGubbio,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            it.titolo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: AppColors.bluNotte,
                            ),
                          ),
                          if (it.sottotitolo.trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              it.sottotitolo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.3,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              if (it.durata.trim().isNotEmpty)
                                _meta(Icons.schedule, it.durata),
                              if (it.difficolta.trim().isNotEmpty)
                                _meta(Icons.terrain_outlined, it.difficolta),
                              _meta(
                                Icons.place_outlined,
                                _l.count('itStop', it.tappe.length),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isAdmin)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        EditIconButton(onPressed: () => _editItinerario(it)),
                        const SizedBox(width: 8),
                        DeleteIconButton(onPressed: () => _deleteItinerario(it)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.tortora),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.bluNotte,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 50),
        Icon(Icons.route_outlined,
            size: 64, color: AppColors.tortora.withValues(alpha: 0.6)),
        const SizedBox(height: 14),
        Text(
          _itinerari.isEmpty ? _l.t('itNoneYet') : _l.t('itNoneFound'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _itinerari.isEmpty
              ? _l.t('itSoon')
              : _l.t('tryChangeSearch'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        if (_hasActiveFilters) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rossoGubbio,
                side: const BorderSide(color: AppColors.rossoGubbio),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(_l.t('fltResetAll')),
            ),
          ),
        ],
      ],
    );
  }
}

/// Placeholder elegante per un itinerario senza foto: sfondo istituzionale
/// con l'icona del percorso (nessun testo tecnico mostrato all'utente).
Widget itinerarioImagePlaceholder(String label,
    {IconData icon = Icons.image_outlined}) {
  return DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.bluNotte, Color(0xFF3A5266), AppColors.rossoGubbio],
        stops: [0.0, 0.55, 1.0],
      ),
    ),
    child: Center(
      child: Icon(icon, size: 40, color: Colors.white.withValues(alpha: 0.55)),
    ),
  );
}
