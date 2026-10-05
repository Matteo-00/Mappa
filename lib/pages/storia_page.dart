import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/storia_model.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import 'admin/add_storia_content_page.dart';
import 'admin/admin_widgets.dart';
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
/// della città, con timeline verticale, ricerca e filtri.
class StoriaPage extends StatefulWidget {
  const StoriaPage({super.key});

  @override
  State<StoriaPage> createState() => _StoriaPageState();
}

class _StoriaPageState extends State<StoriaPage> {
  final _searchController = TextEditingController();
  final _timelineBarKey = GlobalKey();
  final Map<String, GlobalKey> _cardKeys = {};

  bool _loading = true;
  List<StoriaEpoca> _epoche = [];
  List<StoriaContenuto> _contenuti = [];
  StoriaContenuto? _currentCard;
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
    setState(() => _loading = true);
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = languageCode;
    final epoche = await ContentService.fetchStoriaEpoche(languageCode: languageCode);
    final contenuti = await ContentService.fetchStoriaContenuti(languageCode: languageCode);
    if (!mounted) return;
    setState(() {
      _epoche = epoche;
      _contenuti = contenuti;
      _loading = false;
    });
  }

  StoriaEpoca? _eraOf(StoriaContenuto c) {
    for (final e in _epoche) {
      if (e.id == c.eraId) return e;
    }
    return null;
  }

  GlobalKey _keyForCard(String id) =>
      _cardKeys.putIfAbsent(id, () => GlobalKey());

  /// Trova la card il cui titolo è attualmente sotto la barra del tempo
  /// (cioè quella che l'utente sta leggendo) e aggiorna il puntino.
  void _recomputeCurrentCard() {
    final barBox =
        _timelineBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (barBox == null || !barBox.attached) return;
    final readingY = barBox.localToGlobal(Offset.zero).dy + barBox.size.height;

    StoriaContenuto? best;
    double bestTop = double.negativeInfinity;
    for (final c in _filtered) {
      final box = _cardKeys[c.id]?.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top <= readingY && top > bestTop) {
        bestTop = top;
        best = c;
      }
    }
    best ??= _filtered.isNotEmpty ? _filtered.first : null;
    if (best?.id != _currentCard?.id) {
      setState(() => _currentCard = best);
    }
  }

  List<StoriaContenuto> get _filtered {
    final query = _searchQuery.trim().toLowerCase();
    return _contenuti.where((c) {
      if (c.isPublished == false &&
          !context.read<AuthService>().isAdmin) {
        return false;
      }
      if (_selectedEraId != null && c.eraId != _selectedEraId) return false;
      if (_selectedCategory != null && c.category != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty && !c.searchableText.contains(query)) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

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
      if (items.isNotEmpty) gruppi[epoca] = items;
    }
    // Contenuti senza epoca associata (fallback, non dovrebbero essercene).
    final senzaEpoca = filtered.where((c) => _eraOf(c) == null).toList();

    if (!_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recomputeCurrentCard();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.avorio,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _addContent,
              backgroundColor: AppColors.rossoGubbio,
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
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      _recomputeCurrentCard();
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: _load,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(child: _buildIntroHero()),
                          const SliverToBoxAdapter(child: SizedBox(height: 22)),
                          SliverToBoxAdapter(child: _buildSearchBar()),
                          const SliverToBoxAdapter(child: SizedBox(height: 14)),
                          SliverToBoxAdapter(child: _buildEraFilterChips()),
                          const SliverToBoxAdapter(child: SizedBox(height: 10)),
                          SliverToBoxAdapter(child: _buildCategoryFilterChips()),
                          const SliverToBoxAdapter(child: SizedBox(height: 10)),
                          if (filtered.isNotEmpty)
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _StickyTimelineDelegate(
                                child: _buildTimelineBar(filtered),
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 100),
                              child: filtered.isEmpty
                                  ? _buildEmptyState()
                                  : Column(
                                      children: [
                                        for (final epoca in gruppi.keys) ...[
                                          _buildEraHeader(epoca),
                                          const SizedBox(height: 14),
                                          ...gruppi[epoca]!.map(
                                            (c) => Padding(
                                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                                              child: _buildContentCard(c, epoca, isAdmin,
                                                  key: _keyForCard(c.id)),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                        if (senzaEpoca.isNotEmpty)
                                          ...senzaEpoca.map(
                                            (c) => Padding(
                                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                                              child: _buildContentCard(c, null, isAdmin,
                                                  key: _keyForCard(c.id)),
                                            ),
                                          ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------- Timeline orizzontale fissa
  Widget _buildTimelineBar(List<StoriaContenuto> filtered) {
    final conAnno = filtered.where((c) => c.startYear != null).toList();
    final current = _currentCard;

    double fraction = 0;
    int? minYear;
    int? maxYear;
    if (conAnno.isNotEmpty) {
      minYear = conAnno.map((c) => c.startYear!).reduce((a, b) => a < b ? a : b);
      maxYear = conAnno.map((c) => c.startYear!).reduce((a, b) => a > b ? a : b);
      if (current?.startYear != null && maxYear != minYear) {
        fraction = (current!.startYear! - minYear) / (maxYear - minYear);
        fraction = fraction.clamp(0.0, 1.0);
      }
    }

    return Container(
      key: _timelineBarKey,
      color: AppColors.avorio,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.avorio,
        border: Border(
          bottom: BorderSide(color: AppColors.grigioChiaro.withOpacity(0.8)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (current != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      current.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bluNotte,
                      ),
                    ),
                  ),
                  if (current.displayDate.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      current.displayDate,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.rossoGubbio,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (minYear != null && maxYear != null)
            LayoutBuilder(
              builder: (context, constraints) {
                const dotSize = 14.0;
                final trackWidth = constraints.maxWidth;
                final dotLeft =
                    (fraction * trackWidth - dotSize / 2).clamp(0.0, trackWidth - dotSize);
                return SizedBox(
                  height: 18,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 7,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.grigioChiaro,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 7,
                        left: 0,
                        width: (fraction * trackWidth).clamp(0.0, trackWidth),
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.rossoGubbio,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Positioned(
                        left: dotLeft,
                        top: 2,
                        child: Container(
                          width: dotSize,
                          height: dotSize,
                          decoration: BoxDecoration(
                            color: AppColors.rossoGubbio,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.bluNotte.withOpacity(0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          if (minYear != null && maxYear != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  minYear < 0 ? '${-minYear} a.C.' : '$minYear',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Oggi',
                  style: TextStyle(
                      fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------- Hero introduzione
  Widget _buildIntroHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 210,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.heroFallback),
                    child: Center(
                      child: Icon(Icons.castle,
                          size: 60, color: Colors.white.withOpacity(0.85)),
                    ),
                  ),
                  const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.heroOverlay)),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'La storia di Gubbio',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Un viaggio attraverso più di 2.000 anni di storia',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Dall\'antica Iguvium romana al Libero Comune, dal Rinascimento dei '
            'Montefeltro fino ai giorni nostri: scopri le epoche, i monumenti e '
            'i racconti che hanno reso unica Gubbio.',
            style: TextStyle(fontSize: 14.5, height: 1.55, color: AppColors.bluNotte),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------- Ricerca
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Cerca per nome, epoca, curiosità...',
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
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _filterChip('Tutte le epoche', _selectedEraId == null,
              () => setState(() => _selectedEraId = null)),
          const SizedBox(width: 8),
          for (final e in epocheOrdinate) ...[
            _filterChip(e.nome, _selectedEraId == e.id,
                () => setState(() => _selectedEraId = e.id)),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------- Filtro categoria
  Widget _buildCategoryFilterChips() {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final categoriaLabels = _buildCategoriaLabels(l10n);
    final categorie = _contenuti.map((c) => c.category).toSet().toList()..sort();
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _filterChip(l10n.allCategories, _selectedCategory == null,
              () => setState(() => _selectedCategory = null)),
          const SizedBox(width: 8),
          for (final cat in categorie) ...[
            _filterChip(categoriaLabels[cat] ?? cat, _selectedCategory == cat,
                () => setState(() => _selectedCategory = cat)),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.rossoGubbio : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.rossoGubbio : AppColors.grigioChiaro,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.bluNotte,
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------- Intestazione epoca
  Widget _buildEraHeader(StoriaEpoca epoca) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.rossoGubbio,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 56,
                color: AppColors.tortora.withOpacity(0.4),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  epoca.nome,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bluNotte,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  epoca.periodo,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rossoGubbio,
                    letterSpacing: 0.3,
                  ),
                ),
                if (epoca.descrizione.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    epoca.descrizione,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
                if (epoca.eventiImportanti.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: epoca.eventiImportanti
                        .map((ev) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.tortora.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                ev,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.bluNotte,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------- Card contenuto
  Widget _buildContentCard(StoriaContenuto c, StoriaEpoca? epoca, bool isAdmin, {Key? key}) {
    return Material(
      key: key,
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openDetail(c),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.bluNotte.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: c.coverImage != null
                          ? Image.network(
                              c.coverImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _cardPlaceholder(c.category),
                            )
                          : _cardPlaceholder(c.category),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.bluNotte,
                                ),
                              ),
                            ),
                            if (isAdmin)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  EditIconButton(onPressed: () => _editContent(c)),
                                  const SizedBox(width: 6),
                                  DeleteIconButton(onPressed: () => _deleteContent(c)),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (c.displayDate.isNotEmpty)
                              _miniBadge(c.displayDate, AppColors.rossoGubbio),
                            if (epoca != null)
                              _miniBadge(epoca.nome, AppColors.tortora, dark: true),
                            if (!c.isPublished)
                              _miniBadge('Bozza', Colors.grey, dark: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                c.shortDescription,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textMuted),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openDetail(c),
                  style: TextButton.styleFrom(foregroundColor: AppColors.rossoGubbio),
                  icon: const Text('Approfondisci',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  label: const Icon(Icons.arrow_forward_rounded, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String text, Color color, {bool dark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(dark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: dark ? AppColors.bluNotte : color,
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
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.tortora.withOpacity(0.7)),
          const SizedBox(height: 14),
          const Text(
            'Nessun contenuto trovato',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.bluNotte),
          ),
          const SizedBox(height: 6),
          const Text(
            'Prova a modificare la ricerca o i filtri selezionati.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Header fisso (sempre visibile durante lo scroll) per la timeline orizzontale.
class _StickyTimelineDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTimelineDelegate({required this.child});

  @override
  double get minExtent => 74;

  @override
  double get maxExtent => 74;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyTimelineDelegate oldDelegate) => true;
}


