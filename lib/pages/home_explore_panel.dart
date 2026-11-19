part of 'home_landing_page.dart';

// ============================================================
// Pannello "Esplora Gubbio" della home: vetro chiaro (avorio
// trasparente e sfocato, il video si intravede dietro), barra di
// ricerca e schede Itinerari / Eventi / Servizi.
// ============================================================

const Color _goldSoft = Color(0xFFE6CFA0);

/// Altezza del pannello chiuso (solo la ricerca) e a metà (ricerca,
/// schede e i 3 itinerari della vetrina), senza il bordo di sistema.
const double _panelClosedPx = 94;
const double _panelMidPx = 446;

extension _ExplorePanel on _HomeLandingPageState {
  bool get _panelOpen => _sheetExtent > _maxE - 0.04;
  void _togglePanel() => _toggleSheet(_minE, _maxE);

  static final _surface = Colors.white.withValues(alpha: 0.82);
  static final _surfaceBorder =
      Border.all(color: Colors.white.withValues(alpha: 0.9));

  Widget _buildExplorePanel(ScrollController sc) {
    const radius = BorderRadius.vertical(top: Radius.circular(28));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.avorio.withValues(alpha: 0.78),
              borderRadius: radius,
              border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.8))),
            ),
            // Il pannello si trascina anche con il mouse (versione web).
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context)
                  .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
              child: ListView(
                controller: sc,
                padding: EdgeInsets.only(
                    bottom: 24 + MediaQuery.of(context).padding.bottom),
                children: [
                  _panelHeader(),
                  ValueListenableBuilder<int>(
                    valueListenable: _panelTab,
                    builder: (context, tab, _) => _panelTabs(tab),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ intestazione

  /// Maniglia, barra di ricerca e freccia. Un tocco fuori dalla ricerca
  /// apre/chiude il pannello.
  Widget _panelHeader() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePanel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Column(children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.tortora.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _openSearch,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: _surfaceBorder,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bluNotte.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(children: [
                    const Icon(Icons.search_rounded,
                        color: AppColors.rossoGubbio),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _l10n.t('searchHint'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14.5, color: AppColors.textMuted),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Tooltip(
              message: _l10n.t(_panelOpen ? 'homeCollapse' : 'homeExpand'),
              child: GestureDetector(
                onTap: _togglePanel,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: AppColors.bluNotte,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedRotation(
                    turns: _panelOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_up_rounded,
                        color: Colors.white, size: 28),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ------------------------------------------------------------ schede

  Widget _panelTabs(int tab) {
    final labels = [
      (Icons.route_outlined, _l10n.t('mapItinerari')),
      (Icons.event_outlined, _l10n.t('homeTabEvents')),
      (Icons.grid_view_rounded, _l10n.t('homeTabServices')),
    ];
    final Widget body = switch (tab) {
      0 => Column(children: [
          _itinerariRow(200),
          _allButton(_l10n.t('homeAllItineraries'), _openItinerari),
          if (context.watch<AuthService>().isAdmin)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                onPressed: _chooseVetrina,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(_l10n.t('homeChooseVetrina')),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.bluNotte),
              ),
            ),
        ]),
      1 => Column(children: [
          _eventsList(),
          _allButton(_l10n.t('homeAllEvents'), _openEvents),
        ]),
      _ => _servicesGrid(),
    };
    // Aperto del tutto: sotto la scheda scelta compaiono anche le altre due
    // sezioni (mai ripetute) e, in fondo, la Storia di Gubbio.
    final rest = <Widget>[
      if (tab != 1) ...[
        _panelSection(_l10n.t('homeUpcomingEvents'),
            onSeeAll: _openEvents, top: 26),
        _eventsRow(),
      ],
      if (tab != 2) ...[
        _panelSection(_l10n.t('homeTabServices'), top: 24),
        _servicesGrid(),
      ],
      if (tab == 2) ...[
        _panelSection(_l10n.suggestedItinerariesNav,
            onSeeAll: _openItinerari, top: 24),
        _itinerariRow(180),
      ],
      _storiaBanner(),
    ];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.bluNotte.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => _panelTab.value = i,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: tab == i
                          ? AppColors.rossoGubbio
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: tab == i
                          ? [
                              BoxShadow(
                                color: AppColors.rossoGubbio
                                    .withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(labels[i].$1,
                            size: 17,
                            color: tab == i
                                ? Colors.white
                                : AppColors.bluNotte),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            labels[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: tab == i
                                  ? Colors.white
                                  : AppColors.bluNotte,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(tab), child: body),
      ),
      ...rest,
    ]);
  }

  Widget _panelSection(String title, {VoidCallback? onSeeAll, double top = 18}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.bluNotte,
              ),
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _l10n.seeAllLabel,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.rossoGubbio),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.rossoGubbio),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _allButton(String text, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onTap,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label:
                Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.bluNotte,
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              side: const BorderSide(color: AppColors.grigioChiaro),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );

  // ------------------------------------------------------------ itinerari

  /// I 3 itinerari della vetrina affiancati, tutti visibili a metà.
  Widget _itinerariRow(double height) {
    final items = _itinerariConsigliati.take(3).toList();
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: _openItinerari,
          child: SizedBox(
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child:
                  itinerarioImagePlaceholder('', icon: Icons.route_outlined),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              // Con meno di 3 itinerari le schede restano della stessa
              // larghezza.
              Expanded(
                  child: i < items.length
                      ? _itinerarioCard(items[i])
                      : const SizedBox()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _itinerarioCard(ItinerarioModel it) {
    final placeholder = itinerarioImagePlaceholder('', icon: it.icona);
    final meta = [
      if (it.durata.trim().isNotEmpty) it.durata.trim(),
      if (it.tappe.isNotEmpty) _l10n.count('homeStops', it.tappe.length),
    ].join(' · ');
    return GestureDetector(
      onTap: () => _openItinerario(it),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (it.imageUrl != null)
                Image.network(it.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => placeholder)
              else
                placeholder,
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x22000000),
                      Color(0x00000000),
                      Color(0xE0000000),
                    ],
                    stops: [0.0, 0.35, 1.0],
                  ),
                ),
              ),
              if (it.tema.trim().isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.rossoGubbio,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        it.tema.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.titolo,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ eventi

  void _openEvent(EventModel e) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailPage(event: e)),
      );

  Widget _noEvents() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Text(
          _l10n.t('homeNoUpcomingEvents'),
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      );

  /// Scheda Eventi: i prossimi eventi uno sotto l'altro.
  Widget _eventsList() {
    if (_prossimiEventi.isEmpty) return _noEvents();
    return Column(children: [
      for (final e in _prossimiEventi.take(4))
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: _eventCard(e, width: double.infinity),
        ),
    ]);
  }

  /// Pannello aperto: i prossimi eventi in fila orizzontale.
  Widget _eventsRow() {
    if (_prossimiEventi.isEmpty) return _noEvents();
    return SizedBox(
      height: 94,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _prossimiEventi.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _eventCard(_prossimiEventi[i]),
      ),
    );
  }

  Widget _eventCard(EventModel e, {double width = 250}) {
    final months = _l10n.list('monthsShort');
    final now = DateTime.now();
    final live = !e.startTime.isAfter(now) && !e.endTime.isBefore(now);
    return GestureDetector(
      onTap: () => _openEvent(e),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(18),
          border: _surfaceBorder,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              constraints: const BoxConstraints(minHeight: 60),
              decoration: BoxDecoration(
                color: AppColors.rossoGubbio.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(months[e.startTime.month - 1],
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rossoGubbio,
                          letterSpacing: 0.8)),
                  Text('${e.startTime.day}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.bluNotte,
                          height: 1.1)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (live)
                    Text(_l10n.t('eventNow'),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.rossoGubbio,
                            letterSpacing: 0.6)),
                  Text(e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.bluNotte,
                          height: 1.2)),
                  if (e.location.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.place_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(e.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ servizi

  /// Griglia 4x2 degli accessi rapidi (Mappa, Eventi, Storia, ...).
  Widget _servicesGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.95,
        children: [
          for (final (icon, label, color, onTap) in _quickItems())
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: color, size: 25),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.bluNotte,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ storia

  /// In fondo al pannello aperto: invito alla Storia di Gubbio.
  Widget _storiaBanner() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
        child: GestureDetector(
          onTap: _openStoria,
          child: Container(
            height: 112,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(children: [
              Positioned(
                right: -10,
                bottom: -18,
                child: Icon(Icons.auto_stories_outlined,
                    size: 130, color: Colors.white.withValues(alpha: 0.12)),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_l10n.t('homeStoriaOver'),
                        style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w800,
                            color: _goldSoft)),
                    const SizedBox(height: 4),
                    Text(_l10n.storiaDiGubbioNav,
                        style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(_l10n.t('homeStoriaSub'),
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );
}
