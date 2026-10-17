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
import '../widgets/premium_scaffold.dart';
import '../widgets/scroll_hints.dart';
import 'admin/admin_widgets.dart';
import 'admin/add_event_page.dart';

/// Filtri temporali della lista eventi.
enum EventFilter {
  upcoming, // in corso e futuri
  today,
  week,
  month,
  all,
}

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

class _EventsListPageState extends State<EventsListPage> {
  AppLocalizations get _l => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  final TextEditingController _searchController = TextEditingController();

  List<EventModel> _allEvents = [];
  bool _loading = true;

  String _searchQuery = '';
  EventFilter _currentFilter = EventFilter.upcoming;
  String? _selectedCategory;
  String? _selectedPlace;
  String? _loadedLanguageCode;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = context.watch<LanguageService>().currentLanguageCode;
    if (_loadedLanguageCode != null && _loadedLanguageCode != languageCode) {
      _loadEvents();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = languageCode;
    final events = await ContentService.fetchEvents(languageCode: languageCode);
    if (!mounted) return;
    setState(() {
      _allEvents = events;
      _loading = false;
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

  /// Eventi filtrati: prima i prossimi (dal più vicino), poi i conclusi
  /// (dal più recente) — questi ultimi compaiono solo con "Tutti".
  List<EventModel> get _filteredEvents {
    final q = _searchQuery.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final filtered = _allEvents.where((event) {
      if (_selectedCategory != null && event.category.trim() != _selectedCategory) {
        return false;
      }
      if (_selectedPlace != null && event.location.trim() != _selectedPlace) {
        return false;
      }
      if (q.isNotEmpty &&
          !event.title.toLowerCase().contains(q) &&
          !event.location.toLowerCase().contains(q) &&
          !event.description.toLowerCase().contains(q)) {
        return false;
      }
      switch (_currentFilter) {
        case EventFilter.upcoming:
          return !event.endTime.isBefore(now);
        case EventFilter.today:
          return event.startTime.year == now.year &&
              event.startTime.month == now.month &&
              event.startTime.day == now.day;
        case EventFilter.week:
          return !event.startTime.isBefore(weekStart) &&
              event.startTime.isBefore(weekEnd);
        case EventFilter.month:
          return event.startTime.month == now.month &&
              event.startTime.year == now.year;
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
      _currentFilter != EventFilter.upcoming;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _selectedPlace = null;
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
          _buildTimeChips(),
          if (_categories.length > 1)
            _chipRow(
              values: _categories,
              selected: _selectedCategory,
              allLabel: _l.t('fltAllCategories'),
              icon: Icons.category_outlined,
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
          if (_places.length > 1)
            _chipRow(
              values: _places,
              selected: _selectedPlace,
              allLabel: _l.t('fltAllPlaces'),
              icon: Icons.place_outlined,
              onChanged: (v) => setState(() => _selectedPlace = v),
            ),
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
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.rossoGubbio),
                  )
                : RefreshIndicator(
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

  Widget _chipRow({
    required List<String> values,
    required String? selected,
    required String allLabel,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return HintedChipRow(
      height: 40,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      children: [
          AppFilterChip(
            label: allLabel,
            selected: selected == null,
            compact: true,
            icon: icon,
            onTap: () => onChanged(null),
          ),
          for (final v in values) ...[
            const SizedBox(width: 8),
            AppFilterChip(
              label: v,
              selected: selected == v,
              compact: true,
              onTap: () => onChanged(selected == v ? null : v),
            ),
          ],
      ],
    );
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
                                if (event.category.trim().isNotEmpty)
                                  _pill(event.category, AppColors.verdeSalvia),
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
                            child: Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(
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
    return e.endTime.isAfter(e.startTime)
        ? '${hm(e.startTime)} – ${hm(e.endTime)}'
        : hm(e.startTime);
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
