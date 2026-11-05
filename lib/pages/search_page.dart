import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../services/offline_mode_service.dart';
import '../services/search_service.dart';
import '../theme/app_colors.dart';
import '../widgets/full_photo.dart';
import 'events_list_page.dart';
import 'event_detail_page.dart';
import 'itinerari_page.dart' show ItinerariPage;
import 'map_page.dart';
import 'restaurants_page.dart';
import 'storia_page.dart';

/// Ricerca in tutta l'app: mentre si scrive compaiono i risultati divisi per
/// sezione; toccandone uno si apre la sua scheda.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _loading = true;
  List<String> _recent = [];
  List<SearchResult> _results = [];

  AppLocalizations get _l => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final lang = context.read<LanguageService>().currentLanguageCode +
        OfflineModeService.instance.reloadKey;
    final recent = await SearchService.recent();
    if (mounted) setState(() => _recent = recent);
    await SearchService.load(lang, _l);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = SearchService.search(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    setState(() => _results = SearchService.search(v));
  }

  void _useRecent(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    _onChanged(q);
  }

  Future<void> _open(SearchResult r) async {
    SearchService.addRecent(_controller.text);
    _focus.unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => r.page()),
    );
    final recent = await SearchService.recent();
    if (mounted) setState(() => _recent = recent);
  }

  String _sectionTitle(SearchSection s) {
    switch (s) {
      case SearchSection.eventi:
        return _l.events;
      case SearchSection.ristoranti:
        return _l.restaurantsNav;
      case SearchSection.bar:
        return _l.barsNav;
      case SearchSection.hotel:
        return _l.hotelsNav;
      case SearchSection.luoghi:
        return _l.t('menuCultureShops');
      case SearchSection.infoUtili:
        return _l.t('menuUsefulInfo');
      case SearchSection.itinerari:
        return _l.t('mapItinerari');
      case SearchSection.storia:
        return _l.storiaDiGubbioNav;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final query = _controller.text.trim();
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Campo di ricerca con il pulsante indietro
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.rossoGubbio),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: _onChanged,
                      onSubmitted: (v) => SearchService.addRecent(v),
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.bluNotte),
                      decoration: InputDecoration(
                        hintText: l.t('searchHint'),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.rossoGubbio),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppColors.textMuted),
                                onPressed: () {
                                  _controller.clear();
                                  _onChanged('');
                                },
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: query.length < 2
                  ? _buildStart(l)
                  : _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.rossoGubbio))
                      : _results.isEmpty
                          ? _buildNoResults(l, query)
                          : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  /// Prima di scrivere: ricerche recenti e qualche suggerimento.
  Widget _buildStart(AppLocalizations l) {
    final suggestions = l.list('searchSuggestions');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (_recent.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: _label(l.t('searchRecent'))),
              TextButton(
                onPressed: () async {
                  await SearchService.clearRecent();
                  if (mounted) setState(() => _recent = []);
                },
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.rossoGubbio,
                    visualDensity: VisualDensity.compact),
                child: Text(l.t('searchClear')),
              ),
            ],
          ),
          for (final r in _recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.history_rounded,
                  color: AppColors.textMuted),
              title: Text(r,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.bluNotte)),
              trailing: const Icon(Icons.north_west_rounded,
                  size: 18, color: AppColors.textMuted),
              onTap: () => _useRecent(r),
            ),
          const SizedBox(height: 12),
        ],
        _label(l.t('searchTry')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in suggestions)
              ActionChip(
                label: Text(s),
                onPressed: () => _useRecent(s),
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.grigioChiaro),
                labelStyle: const TextStyle(
                    color: AppColors.bluNotte, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoResults(AppLocalizations l, String query) {
    Widget link(IconData icon, String label, Widget Function() page) =>
        ListTile(
          leading: Icon(icon, color: AppColors.rossoGubbio),
          title: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.bluNotte)),
          trailing:
              const Icon(Icons.chevron_right, color: AppColors.tortora),
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => page())),
        );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
      children: [
        Icon(Icons.search_off_rounded,
            size: 56, color: AppColors.tortora.withValues(alpha: 0.7)),
        const SizedBox(height: 12),
        Text(
          l.fmt('searchNoResults', {'q': query}),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte),
        ),
        const SizedBox(height: 6),
        Text(
          l.t('searchNoResultsHint'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),
        link(Icons.calendar_month_outlined, l.events, () => EventsListPage(
              onEventTap: (e) => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EventDetailPage(event: e))),
            )),
        link(Icons.restaurant_menu, l.restaurantsNav,
            () => const RestaurantsPage()),
        link(Icons.route_outlined, l.t('mapItinerari'),
            () => const ItinerariPage()),
        link(Icons.auto_stories_outlined, l.storiaDiGubbioNav,
            () => const StoriaPage()),
        link(Icons.map_outlined, l.mapNav, () => const MapPage()),
      ],
    );
  }

  Widget _buildResults() {
    // Sezioni nell'ordine dell'enum; dentro, dal più pertinente.
    final groups = <SearchSection, List<SearchResult>>{};
    for (final r in _results) {
      groups.putIfAbsent(r.section, () => []).add(r);
    }
    final sections = SearchSection.values.where(groups.containsKey).toList()
      // Prima la sezione con il risultato migliore.
      ..sort((a, b) => groups[b]!.first.score.compareTo(groups[a]!.first.score));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 2),
          child: Text(
            _l.count('searchCount', _results.length),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted),
          ),
        ),
        for (final s in sections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 14, 0, 8),
            child: _label(_sectionTitle(s)),
          ),
          for (final r in groups[s]!.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTile(r),
            ),
        ],
      ],
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
          letterSpacing: 0.8,
        ),
      );

  Widget _buildTile(SearchResult r) {
    final fallback = ColoredBox(
      color: AppColors.rossoGubbio.withValues(alpha: 0.08),
      child: Icon(r.icon, color: AppColors.rossoGubbio, size: 22),
    );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(r),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: r.imageUrl != null
                      ? FullPhoto(url: r.imageUrl!, fallback: fallback)
                      : fallback,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bluNotte,
                      ),
                    ),
                    if (r.subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        r.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.tortora),
            ],
          ),
        ),
      ),
    );
  }
}
