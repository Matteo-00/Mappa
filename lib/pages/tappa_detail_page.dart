import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/itinerario_model.dart';
import '../models/storia_model.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import 'admin/edit_itinerario_flow.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import '../utils/route_links.dart';
import '../widgets/distance_label.dart';
import 'itinerari_page.dart' show itinerarioImagePlaceholder;
import 'map_page.dart';
import 'storia_detail_page.dart';

/// Pagina "Approfondisci" di una tappa di un itinerario: titolo, descrizione,
/// approfondimento, curiosità, posizione sulla mappa e collegamenti diretti ai
/// contenuti di "Storia di Gubbio".
class TappaDetailPage extends StatefulWidget {
  final ItinerarioModel itinerario;

  /// Posizione della tappa nell'elenco delle tappe dell'itinerario.
  final int index;

  const TappaDetailPage({
    super.key,
    required this.itinerario,
    required this.index,
  });

  @override
  State<TappaDetailPage> createState() => _TappaDetailPageState();
}

class _TappaDetailPageState extends State<TappaDetailPage> {
  /// Itinerario mostrato: si aggiorna dopo una modifica dell'admin.
  late ItinerarioModel _it = widget.itinerario;

  List<StoriaContenuto> _storia = [];
  List<StoriaEpoca> _epoche = [];
  bool _loadingStoria = false;
  String? _loadedLanguageCode;

  ItinerarioTappa get _tappa => _it.tappe[widget.index];

  @override
  void initState() {
    super.initState();
    _loadStoria();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = context.watch<LanguageService>().currentLanguageCode;
    if (_loadedLanguageCode != null && _loadedLanguageCode != code) {
      _loadStoria();
    }
  }

  /// Carica i contenuti di Storia di Gubbio collegati a questa tappa.
  Future<void> _loadStoria() async {
    final ids = _tappa.storiaIds;
    final code = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = code;
    if (ids.isEmpty) return;
    setState(() => _loadingStoria = true);
    final storia = await ContentService.fetchStoriaByIds(ids, languageCode: code);
    final epoche = await ContentService.fetchStoriaEpoche(languageCode: code);
    if (!mounted) return;
    setState(() {
      _storia = storia;
      _epoche = epoche;
      _loadingStoria = false;
    });
  }

  StoriaEpoca? _epocaOf(StoriaContenuto c) {
    for (final e in _epoche) {
      if (e.id == c.eraId) return e;
    }
    return null;
  }

  /// Solo admin: modifica l'itinerario partendo da questa tappa.
  Future<void> _edit() async {
    final updated =
        await editItinerarioFlow(context, _it, stopIndex: widget.index);
    if (updated == null || !mounted) return;
    if (widget.index >= updated.tappe.length) {
      // La tappa è stata eliminata: si torna indietro.
      Navigator.pop(context);
      return;
    }
    setState(() {
      _it = updated;
      _storia = [];
    });
    _loadStoria();
  }

  void _openOnMap() {
    final pos = _tappa.position;
    if (pos == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPage(
          focus: MapFocus(
            kind: MapKind.itinerary,
            id: _it.id,
            position: pos,
            stopIndex: widget.index,
          ),
        ),
      ),
    );
  }

  void _goToStop(int newIndex) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TappaDetailPage(itinerario: _it, index: newIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final it = _it;
    final isAdmin = context.watch<AuthService>().isAdmin;
    final t = _tappa;
    final total = it.tappe.length;

    final hasText = t.descrizione.trim().isNotEmpty ||
        t.approfondimento.trim().isNotEmpty ||
        t.curiosita.trim().isNotEmpty;
    final hasAnything = hasText || t.hasCoordinates || t.storiaIds.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.bluNotte,
            foregroundColor: Colors.white,
            actions: [
              if (isAdmin)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.black.withOpacity(0.28),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _edit,
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.edit_outlined,
                            color: Colors.white, size: 21),
                      ),
                    ),
                  ),
                ),
            ],
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Material(
                color: Colors.black.withOpacity(0.28),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (it.imageUrl != null)
                    Image.network(
                      it.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          itinerarioImagePlaceholder(it.immagineLabel,
                              icon: it.icona),
                    )
                  else
                    itinerarioImagePlaceholder(it.immagineLabel, icon: it.icona),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0xBB000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.rossoGubbio,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            '${l10n.fmt('tpStopNumber', {'n': '${widget.index + 1}'})}  ·  ${it.titolo}'
                                .toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.nome,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Durata e distanza
                  if (t.durata.trim().isNotEmpty || t.hasCoordinates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (t.durata.trim().isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule,
                                    size: 16, color: AppColors.tortora),
                                const SizedBox(width: 5),
                                Text(
                                  t.durata,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.bluNotte,
                                  ),
                                ),
                              ],
                            ),
                          if (t.hasCoordinates)
                            DistanceLabel(
                                target: t.position!, fontSize: 13.5, suffix: true),
                        ],
                      ),
                    ),

                  if (t.descrizione.trim().isNotEmpty)
                    Text(
                      t.descrizione,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        color: AppColors.bluNotte,
                      ),
                    ),

                  if (t.approfondimento.trim().isNotEmpty)
                    _section(
                      icon: Icons.auto_stories_outlined,
                      title: l10n.t('tpApprofondimento'),
                      child: Text(
                        t.approfondimento,
                        style: const TextStyle(
                          fontSize: 15.5,
                          height: 1.65,
                          color: AppColors.bluNotte,
                        ),
                      ),
                    ),

                  if (t.curiosita.trim().isNotEmpty)
                    _section(
                      icon: Icons.lightbulb_outline,
                      title: l10n.t('tpCuriosita'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.tortora.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          t.curiosita,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: AppColors.bluNotte,
                          ),
                        ),
                      ),
                    ),

                  _buildWhere(l10n, t),

                  if (t.storiaIds.isNotEmpty) _buildStoryLinks(l10n),

                  if (!hasAnything)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Text(
                        l10n.t('tpNoExtra'),
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textMuted),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: total > 1 ? _buildStopNav(l10n, total) : null,
    );
  }

  /// "Dove si trova": coordinate e pulsanti per mappa, a piedi, in auto.
  Widget _buildWhere(AppLocalizations l10n, ItinerarioTappa t) {
    if (!t.hasCoordinates) {
      return _section(
        icon: Icons.place_outlined,
        title: l10n.t('tpWhere'),
        child: Text(
          l10n.t('tpNoPosition'),
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      );
    }
    final pos = t.position!;
    return _section(
      icon: Icons.place_outlined,
      title: l10n.t('tpWhere'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.bluNotte.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.my_location,
                    size: 18, color: AppColors.rossoGubbio),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                  '${l10n.t('tpCoordinates')}: '
                  '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.bluNotte,
                  ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openOnMap,
                icon: const Icon(Icons.map_outlined, size: 20),
                label: Text(l10n.t('tpOnMap')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rossoGubbio,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  textStyle: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openDirectionsTo(pos, 'walking'),
                    icon: const Icon(Icons.directions_walk, size: 20),
                    label: Text(l10n.t('walkBtn')),
                    style: _outlinedStyle(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openDirectionsTo(pos, 'driving'),
                    icon: const Icon(Icons.directions_car, size: 20),
                    label: Text(l10n.t('carBtn')),
                    style: _outlinedStyle(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.rossoGubbio,
        side: const BorderSide(color: AppColors.rossoGubbio),
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  /// Collegamenti con la storia di Gubbio: aprono direttamente quel contenuto.
  Widget _buildStoryLinks(AppLocalizations l10n) {
    if (_loadingStoria) {
      return _section(
        icon: Icons.history_edu_outlined,
        title: l10n.t('tpStoryLinks'),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: AppColors.rossoGubbio),
          ),
        ),
      );
    }
    // Contenuti eliminati o non più visibili: se non resta nulla, niente sezione.
    if (_storia.isEmpty) return const SizedBox.shrink();

    return _section(
      icon: Icons.history_edu_outlined,
      title: l10n.t('tpStoryLinks'),
      child: Column(
        children: [
          for (final c in _storia)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _storyCard(c, l10n),
            ),
        ],
      ),
    );
  }

  Widget _storyCard(StoriaContenuto c, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoriaDetailPage(contenuto: c, epoca: _epocaOf(c)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: c.coverImage != null
                        ? Image.network(
                            c.coverImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _storyPlaceholder(),
                          )
                        : _storyPlaceholder(),
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
                            fontSize: 10.5,
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: AppColors.bluNotte,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.t('stReadStory'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.rossoGubbio,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.tortora),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _storyPlaceholder() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.grigioChiaro, AppColors.tortora],
          ),
        ),
        child: Center(
          child: Icon(Icons.castle_outlined, color: Colors.white, size: 26),
        ),
      );

  /// Tappa precedente / successiva.
  Widget _buildStopNav(AppLocalizations l10n, int total) {
    final hasPrev = widget.index > 0;
    final hasNext = widget.index < total - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: hasPrev ? () => _goToStop(widget.index - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
                label: Text(l10n.t('tpPrevStop'),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.rossoGubbio,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
            Text(
              '${widget.index + 1}/$total',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.bluNotte,
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: hasNext ? () => _goToStop(widget.index + 1) : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.rossoGubbio,
                  alignment: Alignment.centerRight,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(l10n.t('tpNextStop'),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.rossoGubbio),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bluNotte,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
