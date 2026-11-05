import '../widgets/distance_label.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../services/content_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/app_filter_chip.dart';
import '../widgets/full_photo.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/loading_screen.dart';
import '../widgets/scroll_hints.dart';
import 'admin/admin_widgets.dart';
import 'admin/add_event_page.dart';
import '../utils/route_observer.dart';

/// Filtri temporali della lista eventi.
enum EventFilter {
  upcoming, // in corso e futuri
  today,
  weekend,
  week,
  month,
  all,
}

/// Da dove arriva un evento (filtro "fonte").
enum EventSource { comune, visitGubbio }

/// Pagina lista eventi: ricerca, filtro temporale, filtro per categoria e
/// luogo, eventi raggruppati per mese in schede compatte.
class EventsListPage extends StatefulWidget {
  final Function(EventModel) onEventTap;

  const EventsListPage({
    super.key,
    required this.onEventTap,
  });

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> with RouteAware {
  AppLocalizations get _l => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  final TextEditingController _searchController = TextEditingController();

  List<EventModel> _allEvents = [];
  bool _loading = true;

  String _searchQuery = '';
  EventFilter _currentFilter = EventFilter.upcoming;
  String? _selectedCategory;
  String? _selectedPlace;
  EventSource? _selectedSource;
  String? _loadedLanguageCode;

  /// Solo admin: mostra soltanto gli eventi importati da approvare.
  bool _onlyDrafts = false;
  DateTime? _lastImport;
  bool _importing = false;

  bool get _isAdmin => context.read<AuthService>().isAdmin;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
    final languageCode = context.watch<LanguageService>().currentLanguageCode;
    if (_loadedLanguageCode != null && _loadedLanguageCode != languageCode) {
      _loadEvents();
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  /// Si torna alla lista (es. dopo aver pubblicato una bozza): si ricarica.
  @override
  void didPopNext() => _loadEvents();

  Future<void> _loadEvents() async {
    final loadingStart = DateTime.now();
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = languageCode;
    final events = await ContentService.fetchEvents(languageCode: languageCode);
    final lastImport =
        _isAdmin ? await ContentService.lastEventsImport() : null;
    // La crescia resta almeno un secondo, così non "lampeggia".
    if (_loading) await LoadingScreen.waitMinimum(loadingStart);
    if (!mounted) return;
    setState(() {
      _allEvents = events;
      _lastImport = lastImport;
      _loading = false;
      if (!_allEvents.any((e) => e.isDraft)) _onlyDrafts = false;
      if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
        _selectedCategory = null;
      }
      if (_selectedPlace != null && !_places.contains(_selectedPlace)) {
        _selectedPlace = null;
      }
    });
  }

  /// Valori distinti (non vuoti) di un campo degli eventi, in ordine alfabetico.
  List<String> _distinct(String Function(EventModel) field) {
    final set = <String>{};
    for (final e in _allEvents) {
      final v = field(e).trim();
      if (v.isNotEmpty) set.add(v);
    }
    return set.toList()..sort();
  }

  List<String> get _categories => _distinct((e) => e.category);
  List<String> get _places => _distinct((e) => e.location);

  /// Fonti presenti negli eventi (il filtro compare solo se sono due).
  bool get _hasBothSources =>
      _allEvents.any((e) => e.isFromComune) &&
      _allEvents.any((e) => !e.isFromComune);

  int get _draftCount => _allEvents.where((e) => e.isDraft).length;

  /// L'evento si svolge (anche in parte) nel periodo [from, to).
  static bool _overlaps(EventModel e, DateTime from, DateTime to) =>
      e.startTime.isBefore(to) && !e.endTime.isBefore(from);

  /// Eventi filtrati: prima i prossimi (dal più vicino), poi i conclusi
  /// (dal più recente) — questi ultimi compaiono solo con "Tutti".
  /// Un evento di più giorni (es. una mostra) compare in tutti i periodi in
  /// cui è aperto, non solo nel giorno in cui inizia.
  List<EventModel> get _filteredEvents {
    final q = _searchQuery.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    // Weekend: sabato e domenica di questa settimana (da oggi se è già sabato
    // o domenica).
    final saturday = weekStart.add(const Duration(days: 5));
    final weekendFrom = today.isAfter(saturday) ? today : saturday;
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1);

    final filtered = _allEvents.where((event) {
      if (_onlyDrafts && !event.isDraft) return false;
      if (_selectedSource == EventSource.comune && !event.isFromComune) {
        return false;
      }
      if (_selectedSource == EventSource.visitGubbio && event.isFromComune) {
        return false;
      }
      if (_selectedCategory != null && event.category.trim() != _selectedCategory) {
        return false;
      }
      if (_selectedPlace != null && event.location.trim() != _selectedPlace) {
        return false;
      }
      if (q.isNotEmpty &&
          !event.title.toLowerCase().contains(q) &&
          !event.location.toLowerCase().contains(q) &&
          !event.category.toLowerCase().contains(q) &&
          !event.description.toLowerCase().contains(q)) {
        return false;
      }
      switch (_currentFilter) {
        case EventFilter.upcoming:
          return !event.endTime.isBefore(now);
        case EventFilter.today:
          return _overlaps(event, today, tomorrow) &&
              !event.endTime.isBefore(now);
        case EventFilter.weekend:
          return _overlaps(event, weekendFrom, weekEnd) &&
              !event.endTime.isBefore(now);
        case EventFilter.week:
          return _overlaps(event, weekStart, weekEnd);
        case EventFilter.month:
          return _overlaps(event, monthStart, monthEnd);
        case EventFilter.all:
          return true;
      }
    }).toList();

    final upcoming = filtered.where((e) => !e.endTime.isBefore(now)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final past = filtered.where((e) => e.endTime.isBefore(now)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return [...upcoming, ...past];
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != null ||
      _selectedPlace != null ||
      _selectedSource != null ||
      _onlyDrafts ||
      _currentFilter != EventFilter.upcoming;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedPlace = null;
      _selectedSource = null;
      _onlyDrafts = false;
      _currentFilter = EventFilter.upcoming;
    });
  }

  /// Trasforma la lista in righe: intestazioni di gruppo + eventi.
  List<Object> _buildRows(List<EventModel> events) {
    final now = DateTime.now();
    final rows = <Object>[];
    String? lastGroup;
    for (final e in events) {
      final isPast = e.endTime.isBefore(now);
      final group = isPast
          ? _l.t('eventsPast')
          : '${_l.list('monthsFull')[e.startTime.month - 1]} ${e.startTime.year}';
      if (group != lastGroup) {
        rows.add(group);
        lastGroup = group;
      }
      rows.add(e);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    // Finché i dati non arrivano: schermata di caricamento a pagina intera.
    if (_loading) return LoadingScreen(onRetry: _loadEvents);
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final events = _filteredEvents;
    final rows = _buildRows(events);

    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          PremiumHeader(title: l10n.events),
          AppSearchField(
            controller: _searchController,
            hint: l10n.searchEventsHint,
            onChanged: (v) => setState(() => _searchQuery = v),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          ),
          if (context.watch<AuthService>().isAdmin) _buildAdminImportBar(),
          _buildTimeChips(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _l.count('eventsCount', events.length),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                if (_hasExtraFilters || _hasBothSources)
                  _buildFiltersButton(),
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
                    onRefresh: _loadEvents,
                    child: events.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                            itemCount: rows.length,
                            itemBuilder: (context, i) {
                              final row = rows[i];
                              if (row is String) return _buildGroupHeader(row);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildEventCard(row as EventModel),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Chip per il filtro temporale
  Widget _buildTimeChips() {
    // "Tutti" subito dopo "Prossimi": così si vede senza dover scorrere.
    final labels = {
      EventFilter.upcoming: _l.t('fltUpcoming'),
      EventFilter.all: _l.t('fltAll'),
      EventFilter.today: _l.t('fltToday'),
      EventFilter.weekend: _l.t('fltWeekend'),
      EventFilter.week: _l.t('fltThisWeek'),
      EventFilter.month: _l.t('fltThisMonth'),
    };
    return HintedChipRow(
      height: 46,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
      children: [
          for (final entry in labels.entries) ...[
            AppFilterChip(
              label: entry.value,
              selected: _currentFilter == entry.key,
              icon: entry.key == EventFilter.upcoming ? Icons.event_available : null,
              onTap: () => setState(() => _currentFilter = entry.key),
            ),
            const SizedBox(width: 8),
          ],
      ],
    );
  }

  bool get _hasExtraFilters => _categories.length > 1 || _places.length > 1;

  int get _extraFiltersCount =>
      (_selectedSource != null ? 1 : 0) +
      (_selectedCategory != null ? 1 : 0) +
      (_selectedPlace != null ? 1 : 0);

  /// Un solo pulsante al posto delle righe di chip di fonte, categoria e luogo.
  Widget _buildFiltersButton() {
    final n = _extraFiltersCount;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: _openFiltersSheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: n > 0 ? AppColors.rossoGubbio : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: n > 0 ? AppColors.rossoGubbio : AppColors.grigioChiaro),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded,
                  size: 16, color: n > 0 ? Colors.white : AppColors.bluNotte),
              const SizedBox(width: 6),
              Text(
                n > 0 ? '${_l.t('fltFilters')} ($n)' : _l.t('fltFilters'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: n > 0 ? Colors.white : AppColors.bluNotte,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFiltersSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.avorio,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheet) {
          void change(VoidCallback fn) {
            setState(fn);
            setSheet(() {});
          }

          Widget section(String title, List<Widget> chips) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted)),
                    ),
                    Wrap(spacing: 8, runSpacing: 8, children: chips),
                  ],
                ),
              );

          List<Widget> stringChips(List<String> values, String? selected,
                  String allLabel, void Function(String?) onChanged) =>
              [
                AppFilterChip(
                  label: allLabel,
                  selected: selected == null,
                  compact: true,
                  onTap: () => change(() => onChanged(null)),
                ),
                for (final v in values)
                  AppFilterChip(
                    label: v,
                    selected: selected == v,
                    compact: true,
                    onTap: () =>
                        change(() => onChanged(selected == v ? null : v)),
                  ),
              ];

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(_l.t('fltFilters'),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                        ),
                        if (_extraFiltersCount > 0)
                          TextButton(
                            onPressed: () => change(() {
                              _selectedSource = null;
                              _selectedCategory = null;
                              _selectedPlace = null;
                            }),
                            child: Text(_l.t('fltReset')),
                          ),
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(_l.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_hasBothSources)
                      section(_l.t('fltAllSources'), [
                        AppFilterChip(
                          label: _l.t('fltAllSources'),
                          selected: _selectedSource == null,
                          compact: true,
                          onTap: () => change(() => _selectedSource = null),
                        ),
                        for (final src in EventSource.values)
                          AppFilterChip(
                            label: _l.t(src == EventSource.comune
                                ? 'srcComune'
                                : 'srcVisit'),
                            selected: _selectedSource == src,
                            compact: true,
                            onTap: () => change(() => _selectedSource =
                                _selectedSource == src ? null : src),
                          ),
                      ]),
                    if (_categories.length > 1)
                      section(
                        _l.t('fltAllCategories'),
                        stringChips(_categories, _selectedCategory,
                            _l.t('fltAllCategories'),
                            (v) => _selectedCategory = v),
                      ),
                    if (_places.length > 1)
                      section(
                        _l.t('fltAllPlaces'),
                        stringChips(_places, _selectedPlace,
                            _l.t('fltAllPlaces'), (v) => _selectedPlace = v),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Solo admin: ultimo controllo del sito del Comune, "Importa ora" e le
  /// bozze da approvare.
  Widget _buildAdminImportBar() {
    final last = _lastImport;
    final lastText = last == null
        ? 'mai'
        : '${last.day.toString().padLeft(2, '0')}/'
            '${last.month.toString().padLeft(2, '0')} '
            '${last.hour.toString().padLeft(2, '0')}:'
            '${last.minute.toString().padLeft(2, '0')}';
    final drafts = _draftCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grigioChiaro),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_download_outlined,
                size: 20, color: AppColors.bluNotte),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eventi dal sito del Comune · ultimo controllo: $lastText',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                  if (drafts > 0)
                    GestureDetector(
                      onTap: () => setState(() => _onlyDrafts = !_onlyDrafts),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          _onlyDrafts
                              ? 'Mostra tutti gli eventi'
                              : '$drafts ${drafts == 1 ? 'evento' : 'eventi'} da approvare',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: _importing ? null : _runImport,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.rossoGubbio,
                visualDensity: VisualDensity.compact,
              ),
              child: _importing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.rossoGubbio),
                    )
                  : const Text('Importa ora',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runImport() async {
    setState(() => _importing = true);
    String message;
    try {
      final r = await ContentService.runEventsImport();
      final nuovi = r['nuovi'] ?? 0;
      final bozze = r['bozze'] ?? 0;
      message = nuovi == 0
          ? 'Nessun evento nuovo sul sito del Comune'
          : '$nuovi eventi nuovi importati'
              '${bozze > 0 ? ' ($bozze da approvare)' : ''}';
      final errori = r['errori'];
      if (errori is List && errori.isNotEmpty) {
        message += '\nAttenzione: ${errori.first}';
      }
    } catch (e) {
      message = 'Importazione non riuscita: $e';
    }
    if (!mounted) return;
    setState(() => _importing = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    _loadEvents();
  }

  Widget _buildGroupHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 12, 0, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Future<void> _editEvent(EventModel event) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEventPage(editEvent: event)),
    );
    if (updated == true) {
      await _loadEvents();
    }
  }

  Future<void> _deleteEvent(EventModel event) async {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final ok = await confirmDelete(context, event.title);
    if (!ok) return;
    try {
      await ContentService.deleteEvent(event.id);
      await _loadEvents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.eventDeleted),
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

  /// Scheda compatta: data a sinistra, testi al centro, miniatura a destra.
  Widget _buildEventCard(EventModel event) {
    final canEdit = context.watch<AuthService>().isAdmin &&
        ContentService.isRemoteId(event.id);
    final status = event.getStatus();
    final isPast = status == EventStatus.past;

    return Opacity(
      opacity: isPast ? 0.7 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.bluNotte.withOpacity(0.06),
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
            onTap: () => widget.onEventTap(event),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateBlock(event.startTime, isPast),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                color: AppColors.bluNotte,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _metaRow(Icons.schedule, _timeRange(event)),
                            if (event.location.trim().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              _metaRow(Icons.place_outlined, event.location),
                            ],
                            const SizedBox(height: 2),
                            DistanceLabel(target: event.coordinates, fontSize: 12),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (event.isDraft)
                                  _pill(_l.t('evDraft'), const Color(0xFFE65100),
                                      strong: true),
                                if (event.isDraft && event.datesToVerify)
                                  _pill(_l.t('evDatesCheck'),
                                      const Color(0xFFE65100)),
                                if (event.category.trim().isNotEmpty)
                                  _pill(event.category, AppColors.verdeSalvia),
                                if (event.isFromComune &&
                                    event.category.trim() != _l.t('srcComune'))
                                  _pill(_l.t('srcComune'), AppColors.bluNotte),
                                if (status == EventStatus.current)
                                  _pill(_l.t('eventNow'), AppColors.rossoGubbio,
                                      strong: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (event.imageUrl != null) ...[
                        const SizedBox(width: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 70,
                            height: 70,
                            child: FullPhoto(
                              url: event.imageUrl!,
                              fallback: const ColoredBox(
                                color: AppColors.grigioChiaro,
                                child: Icon(Icons.festival_outlined,
                                    color: AppColors.tortora),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (canEdit)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          EditIconButton(onPressed: () => _editEvent(event)),
                          const SizedBox(width: 8),
                          DeleteIconButton(onPressed: () => _deleteEvent(event)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBlock(DateTime date, bool isPast) {
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: (isPast ? AppColors.tortora : AppColors.rossoGubbio)
            .withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            _l.list('monthsShort')[date.month - 1],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isPast ? AppColors.textMuted : AppColors.rossoGubbio,
            ),
          ),
          Text(
            '${date.day}',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: AppColors.bluNotte,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color, {bool strong = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: strong ? color : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: strong ? Colors.white : AppColors.bluNotte,
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.rossoGubbio),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  String _timeRange(EventModel e) {
    String hm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    String day(DateTime d) => '${d.day} ${_l.list('monthsShort')[d.month - 1]}';
    final s = e.startTime;
    final end = e.endTime;
    final allDay = s.hour == 0 && s.minute == 0 && end.hour == 23 && end.minute == 59;
    final sameDay =
        s.year == end.year && s.month == end.month && s.day == end.day;
    // Eventi di più giorni (mostre, mercatini...): "4 nov – 24 nov".
    if (!sameDay && end.isAfter(s)) {
      final range = '${day(s)} – ${day(end)}';
      return allDay ? range : '$range · ${hm(s)}';
    }
    if (allDay) return _l.t('evAllDay');
    return end.isAfter(s) ? '${hm(s)} – ${hm(end)}' : hm(s);
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 50),
        Icon(Icons.event_busy,
            size: 70, color: AppColors.tortora.withOpacity(0.55)),
        const SizedBox(height: 16),
        Text(
          l10n.noEventsFound,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tryChangeFilters,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
        if (_currentFilter != EventFilter.all) ...[
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: () => setState(() {
                _currentFilter = EventFilter.all;
                _selectedCategory = null;
                _selectedPlace = null;
              }),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rossoGubbio,
                side: const BorderSide(color: AppColors.rossoGubbio),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(_l.t('showAllEvents')),
            ),
          ),
        ],
      ],
    );
  }
}
