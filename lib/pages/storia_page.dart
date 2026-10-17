import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/storia_model.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/scroll_hints.dart';
import 'admin/add_storia_content_page.dart';
import 'admin/add_storia_epoca_page.dart';
import 'admin/admin_widgets.dart';
import 'admin/edit_storia_intro_page.dart';
import 'admin/translate_storia_migration_page.dart';
import 'storia_detail_page.dart';

Map<String, String> _buildCategoriaLabels(AppLocalizations l10n) => {
  'chiesa': l10n.categoryChiesa,
  'palazzo': l10n.categoryPalazzo,
  'piazza': l10n.categoryPiazza,
  'monumento': l10n.categoryMonumento,
  'natura': l10n.categoryNatura,
};

/// Sezione "Storia di Gubbio" — un viaggio nel tempo attraverso le epoche
/// della città. Ogni epoca ha un'intestazione che resta ancorata in alto
/// mentre si scorre, così si sa sempre in che periodo ci si trova.
///
/// Gli admin possono modificare tutto da qui: testi e foto di copertina,
/// epoche (aggiungi / modifica / elimina) e contenuti storici.
class StoriaPage extends StatefulWidget {
  const StoriaPage({super.key});

  @override
  State<StoriaPage> createState() => _StoriaPageState();
}

class _StoriaPageState extends State<StoriaPage> {
  AppLocalizations get _l => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  final _searchController = TextEditingController();

  bool _loading = true;
  List<StoriaEpoca> _epoche = [];
  List<StoriaContenuto> _contenuti = [];
  StoriaIntro _intro = const StoriaIntro();
  String? _loadedLanguageCode;

  String _searchQuery = '';
  String? _selectedEraId;
  String? _selectedCategory;

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
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    final firstLoad = _loadedLanguageCode == null;
    _loadedLanguageCode = languageCode;
    if (firstLoad) setState(() => _loading = true);
    final epoche = await ContentService.fetchStoriaEpoche(languageCode: languageCode);
    final contenuti = await ContentService.fetchStoriaContenuti(languageCode: languageCode);
    final intro = await ContentService.fetchStoriaIntro();
    if (!mounted) return;
    setState(() {
      _epoche = epoche;
      _contenuti = contenuti;
      _intro = intro;
      _loading = false;
      if (_selectedEraId != null && !epoche.any((e) => e.id == _selectedEraId)) {
        _selectedEraId = null;
      }
    });
  }

  StoriaEpoca? _eraOf(StoriaContenuto c) {
    for (final e in _epoche) {
      if (e.id == c.eraId) return e;
    }
    return null;
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedEraId != null ||
      _selectedCategory != null;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedEraId = null;
      _selectedCategory = null;
    });
  }

  List<StoriaContenuto> get _filtered {
    final query = _searchQuery.trim().toLowerCase();
    final isAdmin = context.read<AuthService>().isAdmin;
    return _contenuti.where((c) {
      if (!c.isPublished && !isAdmin) return false;
      if (_selectedEraId != null && c.eraId != _selectedEraId) return false;
      if (_selectedCategory != null && c.category != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty && !c.searchableText.contains(query)) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  // ------------------------------------------------------------ azioni admin

  Future<void> _openDetail(StoriaContenuto c) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StoriaDetailPage(contenuto: c, epoca: _eraOf(c)),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _addContent() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddStoriaContentPage()),
    );
    if (added == true) _load();
  }

  Future<void> _editContent(StoriaContenuto c) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddStoriaContentPage(editContenuto: c)),
    );
    if (updated == true) _load();
  }

  Future<void> _deleteContent(StoriaContenuto c) async {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final ok = await confirmDelete(context, c.title);
    if (!ok) return;
    try {
      await ContentService.deleteStoriaContenuto(c.id);
      _load();
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

  Future<void> _addEpoca() async {
    final maxOrder = _epoche.isEmpty
        ? 0
        : _epoche.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b);
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddStoriaEpocaPage(suggestedSortOrder: maxOrder + 1),
      ),
    );
    if (added == true) _load();
  }

  Future<void> _editEpoca(StoriaEpoca e) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddStoriaEpocaPage(editEpoca: e)),
    );
    if (updated == true) _load();
  }

  Future<void> _deleteEpoca(StoriaEpoca e) async {
    final count = _contenuti.where((c) => c.eraId == e.id).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina epoca'),
        content: Text(
          count == 0
              ? 'Vuoi eliminare l\'epoca "${e.nome}"?'
              : 'Vuoi eliminare l\'epoca "${e.nome}"?\n\n'
                  '$count ${count == 1 ? 'contenuto resterà salvato ma sarà' : 'contenuti resteranno salvati ma saranno'}'
                  ' senza epoca finché non ne assegni un\'altra.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.rossoGubbio),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ContentService.deleteStoriaEpoca(e.id);
      _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $err'),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  Future<void> _editIntro() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditStoriaIntroPage(intro: _intro)),
    );
    if (updated == true) _load();
  }

  /// Scelta di cosa aggiungere (pulsante "+" degli admin).
  Future<void> _showAddMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.avorio,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.castle_outlined,
                    color: AppColors.rossoGubbio),
                title: const Text('Nuovo contenuto storico',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Monumento, chiesa, palazzo, piazza...'),
                onTap: () => Navigator.pop(ctx, 'content'),
              ),
              ListTile(
                leading: const Icon(Icons.history_edu_outlined,
                    color: AppColors.rossoGubbio),
                title: const Text('Nuova epoca',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Un nuovo periodo della timeline'),
                onTap: () => Navigator.pop(ctx, 'epoca'),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == 'content') {
      await _addContent();
    } else if (choice == 'epoca') {
      await _addEpoca();
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final isAdmin = context.watch<AuthService>().isAdmin;
    final filtered = _filtered;

    // Raggruppa i contenuti filtrati per epoca, rispettando l'ordine delle epoche.
    final epocheOrdinate = [..._epoche]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final gruppi = <StoriaEpoca, List<StoriaContenuto>>{};
    for (final epoca in epocheOrdinate) {
      final items = filtered.where((c) => c.eraId == epoca.id).toList();
      // Gli admin vedono anche le epoche ancora vuote, per poterle modificare.
      final showEmptyEra = isAdmin && !_hasActiveFilters;
      if (items.isNotEmpty || showEmptyEra) gruppi[epoca] = items;
    }
    // Contenuti senza epoca associata (es. epoca eliminata).
    final senzaEpoca = filtered.where((c) => _eraOf(c) == null).toList();

    return Scaffold(
      backgroundColor: AppColors.avorio,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddMenu,
              backgroundColor: AppColors.rossoGubbio,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(l10n.addFab),
            )
          : null,
      body: Column(
        children: [
          PremiumHeader(
            title: l10n.storiaTitle,
            trailing: isAdmin
                ? IconButton(
                    tooltip: l10n.translateExistingContentTooltip,
                    icon: const Icon(Icons.translate, color: AppColors.rossoGubbio),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TranslateStoriaMigrationPage(),
                        ),
                      );
                    },
                  )
                : null,
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.rossoGubbio),
                  )
                : RefreshIndicator(
                    color: AppColors.rossoGubbio,
                    onRefresh: _load,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: _buildIntroHero(isAdmin)),
                        const SliverToBoxAdapter(child: SizedBox(height: 18)),
                        SliverToBoxAdapter(child: _buildSearchBar()),
                        SliverToBoxAdapter(child: _buildEraFilterChips()),
                        SliverToBoxAdapter(child: _buildCategoryFilterChips()),
                        SliverToBoxAdapter(child: _buildResultsRow(filtered.length)),
                        if (filtered.isEmpty && gruppi.isEmpty)
                          SliverToBoxAdapter(child: _buildEmptyState())
                        else ...[
                          for (final entry in gruppi.entries)
                            SliverMainAxisGroup(
                              slivers: [
                                SliverPersistentHeader(
                                  pinned: true,
                                  delegate: _EraHeaderDelegate(epoca: entry.key),
                                ),
                                SliverToBoxAdapter(
                                  child: _EraIntro(
                                    epoca: entry.key,
                                    isAdmin: isAdmin,
                                    isEmpty: entry.value.isEmpty,
                                    onEdit: () => _editEpoca(entry.key),
                                    onDelete: () => _deleteEpoca(entry.key),
                                  ),
                                ),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, i) => _buildTimelineItem(
                                      entry.value[i],
                                      entry.key,
                                      isAdmin,
                                      isLast: i == entry.value.length - 1,
                                    ),
                                    childCount: entry.value.length,
                                  ),
                                ),
                              ],
                            ),
                          if (senzaEpoca.isNotEmpty) ...[
                            if (gruppi.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                                  child: Text(
                                    _l.t('stNoEra'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => _buildTimelineItem(
                                  senzaEpoca[i],
                                  null,
                                  isAdmin,
                                  isLast: i == senzaEpoca.length - 1,
                                ),
                                childCount: senzaEpoca.length,
                              ),
                            ),
                          ],
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Se l'admin non ha personalizzato il testo, usa quello predefinito nella
  /// lingua dell'utente; altrimenti mostra il testo scritto dall'admin.
  String _introText(String value, String defaultValue, String key) =>
      value == defaultValue ? _l.t(key) : value;

  // -------------------------------------------------- Hero introduzione
  Widget _buildIntroHero(bool isAdmin) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 170,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _heroBackground(),
                  const DecoratedBox(
                      decoration: BoxDecoration(gradient: AppColors.heroOverlay)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _introText(_intro.titolo, StoriaIntro.defaultTitolo, 'stHeroTitle'),
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _introText(_intro.sottotitolo, StoriaIntro.defaultSottotitolo, 'stHeroSubtitle'),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: EditIconButton(onPressed: _editIntro),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _introText(_intro.testo, StoriaIntro.defaultTesto, 'stHeroText'),
            style: const TextStyle(
                fontSize: 14, height: 1.55, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _heroBackground() {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.heroFallback),
      child: Center(
        child: Icon(Icons.castle, size: 56, color: Colors.white.withOpacity(0.75)),
      ),
    );
    final url = _intro.imageUrl;
    if (url == null) return fallback;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

  // -------------------------------------------------- Ricerca
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Container(
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
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: _l.t('stSearchHint'),
            hintStyle: const TextStyle(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, color: AppColors.rossoGubbio),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.tortora),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------- Filtro epoca
  Widget _buildEraFilterChips() {
    final epocheOrdinate = [..._epoche]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return HintedChipRow(
      height: 52,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      children: [
          _FilterPill(
            label: _l.t('stAllEras'),
            selected: _selectedEraId == null,
            onTap: () => setState(() => _selectedEraId = null),
          ),
          for (final e in epocheOrdinate) ...[
            const SizedBox(width: 8),
            _FilterPill(
              label: e.nome,
              selected: _selectedEraId == e.id,
              onTap: () => setState(
                  () => _selectedEraId = _selectedEraId == e.id ? null : e.id),
            ),
          ],
      ],
    );
  }

  // -------------------------------------------------- Filtro categoria
  Widget _buildCategoryFilterChips() {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final categoriaLabels = _buildCategoriaLabels(l10n);
    final categorie = _contenuti.map((c) => c.category).toSet().toList()..sort();
    if (categorie.length < 2) return const SizedBox.shrink();
    return HintedChipRow(
      height: 44,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      children: [
          _FilterPill(
            label: l10n.allCategories,
            selected: _selectedCategory == null,
            compact: true,
            onTap: () => setState(() => _selectedCategory = null),
          ),
          for (final cat in categorie) ...[
            const SizedBox(width: 8),
            _FilterPill(
              label: categoriaLabels[cat] ?? cat,
              selected: _selectedCategory == cat,
              compact: true,
              onTap: () => setState(
                  () => _selectedCategory = _selectedCategory == cat ? null : cat),
            ),
          ],
      ],
    );
  }

  Widget _buildResultsRow(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _l.count('stPlaces', count),
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
              child: Text(_l.t('fltResetShort'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------- Elemento della timeline
  /// Scheda con linea del tempo a sinistra (puntino + filo che collega le schede).
  Widget _buildTimelineItem(
    StoriaContenuto c,
    StoriaEpoca? epoca,
    bool isAdmin, {
    required bool isLast,
  }) {
    return Stack(
      children: [
        // Filo verticale (si ferma a metà dell'ultima scheda)
        Positioned(
          left: 29,
          top: 0,
          bottom: isLast ? 40 : 0,
          child: Container(width: 2, color: AppColors.tortora.withOpacity(0.45)),
        ),
        // Puntino
        Positioned(
          left: 23,
          top: 26,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.rossoGubbio, width: 3),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(52, 0, 20, 14),
          child: _buildContentCard(c, epoca, isAdmin),
        ),
      ],
    );
  }

  // -------------------------------------------------- Card contenuto
  Widget _buildContentCard(StoriaContenuto c, StoriaEpoca? epoca, bool isAdmin) {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final categoryLabel = _buildCategoriaLabels(l10n)[c.category] ?? c.category;

    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetail(c),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: c.coverImage != null
                            ? Image.network(
                                c.coverImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _cardPlaceholder(c.category),
                              )
                            : _cardPlaceholder(c.category),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.displayDate.isNotEmpty)
                            Text(
                              c.displayDate.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.rossoGubbio,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            c.title,
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
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _miniBadge(categoryLabel, AppColors.verdeSalvia),
                              if (!c.isPublished)
                                _miniBadge(_l.t('stDraft'), Colors.grey, dark: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (c.shortDescription.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    c.shortDescription,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, height: 1.45, color: AppColors.textMuted),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (isAdmin) ...[
                      EditIconButton(onPressed: () => _editContent(c)),
                      const SizedBox(width: 6),
                      DeleteIconButton(onPressed: () => _deleteContent(c)),
                    ],
                    const Spacer(),
                    Text(
                      _l.t('stReadStory'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.rossoGubbio,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 16, color: AppColors.rossoGubbio),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String text, Color color, {bool dark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(dark ? 0.2 : 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: dark ? AppColors.bluNotte : AppColors.bluNotte.withOpacity(0.85),
        ),
      ),
    );
  }

  Widget _cardPlaceholder(String category) {
    IconData icon;
    switch (category) {
      case 'chiesa':
        icon = Icons.church_outlined;
        break;
      case 'palazzo':
        icon = Icons.account_balance_outlined;
        break;
      case 'piazza':
        icon = Icons.location_city_outlined;
        break;
      case 'natura':
        icon = Icons.park_outlined;
        break;
      default:
        icon = Icons.castle_outlined;
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.grigioChiaro, AppColors.tortora],
        ),
      ),
      child: Center(child: Icon(icon, size: 30, color: Colors.white.withOpacity(0.9))),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 52, color: AppColors.tortora.withOpacity(0.7)),
          const SizedBox(height: 14),
          Text(
            _l.t('stNoContent'),
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.bluNotte),
          ),
          const SizedBox(height: 6),
          Text(
            _l.t('stNoContentHint'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rossoGubbio,
                side: const BorderSide(color: AppColors.rossoGubbio),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(_l.t('fltResetAll')),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip di filtro a pillola (rosso quando attivo).
class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16, vertical: compact ? 7 : 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.rossoGubbio : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: selected ? AppColors.rossoGubbio : AppColors.grigioChiaro,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.bluNotte,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Introduzione di un'epoca: descrizione (espandibile), date/eventi chiave e,
/// per gli admin, i pulsanti per modificare o eliminare l'epoca.
class _EraIntro extends StatefulWidget {
  final StoriaEpoca epoca;
  final bool isAdmin;
  final bool isEmpty;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EraIntro({
    required this.epoca,
    required this.isAdmin,
    required this.isEmpty,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EraIntro> createState() => _EraIntroState();
}

class _EraIntroState extends State<_EraIntro> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final e = widget.epoca;
    if (e.descrizione.isEmpty &&
        e.eventiImportanti.isEmpty &&
        !widget.isAdmin) {
      return const SizedBox(height: 6);
    }
    final long = e.descrizione.length > 180;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.tortora.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.descrizione.isNotEmpty) ...[
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: Text(
                  e.descrizione,
                  maxLines: _expanded || !long ? null : 3,
                  overflow: _expanded || !long ? null : TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, height: 1.55, color: AppColors.bluNotte),
                ),
              ),
              if (long)
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 2),
                    child: Text(
                      _expanded ? l10n.t('stShowLess') : l10n.t('stReadMore'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.rossoGubbio,
                      ),
                    ),
                  ),
                ),
            ],
            if (e.eventiImportanti.isNotEmpty) ...[
              if (e.descrizione.isNotEmpty) const SizedBox(height: 12),
              Text(
                l10n.t('stRemember'),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final ev in e.eventiImportanti)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        ev,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.bluNotte,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (widget.isAdmin) ...[
              if (e.descrizione.isNotEmpty || e.eventiImportanti.isNotEmpty)
                const SizedBox(height: 12),
              if (widget.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Nessun contenuto in questa epoca: usa "+" per aggiungerne uno.',
                    style: TextStyle(
                        fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
                  ),
                ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Modifica epoca'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.bluNotte,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Elimina'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.rossoGubbio,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Intestazione di un'epoca che resta ancorata in alto durante lo scroll.
class _EraHeaderDelegate extends SliverPersistentHeaderDelegate {
  final StoriaEpoca epoca;

  _EraHeaderDelegate({required this.epoca});

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.avorio,
        border: Border(
          bottom: BorderSide(
            color: overlapsContent
                ? AppColors.grigioChiaro
                : Colors.transparent,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(left: 3, right: 12),
            decoration: const BoxDecoration(
              color: AppColors.rossoGubbio,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              epoca.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.bluNotte,
              ),
            ),
          ),
          if (epoca.periodo.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.rossoGubbio.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                epoca.periodo,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.rossoGubbio,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _EraHeaderDelegate oldDelegate) => true;
}
