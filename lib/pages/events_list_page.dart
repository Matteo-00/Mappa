import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../theme/app_theme.dart';

/// Pagina lista eventi con ricerca e filtri
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
  final TextEditingController _searchController = TextEditingController();
  
  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  
  String _searchQuery = '';
  EventFilter _currentFilter = EventFilter.month;
  
  int _currentPage = 0;
  static const int _eventsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _loadEvents() {
    // Carica eventi del mese corrente
    _allEvents = _getEventsForCurrentMonth();
    _applyFilters();
  }
  
  void _applyFilters() {
    List<EventModel> filtered = List.from(_allEvents);
    
    // Filtra per nome se c'è una ricerca
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Applica filtro temporale
    final now = DateTime.now();
    
    switch (_currentFilter) {
      case EventFilter.day:
        filtered = filtered.where((event) {
          return event.startTime.day == now.day &&
                 event.startTime.month == now.month &&
                 event.startTime.year == now.year;
        }).toList();
        break;
      case EventFilter.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        filtered = filtered.where((event) {
          return event.startTime.isAfter(weekStart) && 
                 event.startTime.isBefore(weekEnd);
        }).toList();
        break;
      case EventFilter.month:
        filtered = filtered.where((event) {
          return event.startTime.month == now.month &&
                 event.startTime.year == now.year;
        }).toList();
        break;
      case EventFilter.year:
        filtered = filtered.where((event) {
          return event.startTime.year == now.year;
        }).toList();
        break;
      case EventFilter.all:
        // Mostra tutti
        break;
    }
    
    // Ordina dal più vicino al più lontano
    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    setState(() {
      _filteredEvents = filtered;
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_filteredEvents.length / _eventsPerPage).ceil();
    final startIndex = _currentPage * _eventsPerPage;
    final endIndex = (startIndex + _eventsPerPage).clamp(0, _filteredEvents.length);
    final currentPageEvents = _filteredEvents.sublist(startIndex, endIndex);
    
    return Scaffold(
      backgroundColor: AppTheme.vgAncientParchment,
      body: Column(
        children: [
          // Barra di ricerca
          _buildSearchBar(),
          
          // Filtri temporali
          _buildFilterChips(),
          
          // Lista eventi
          Expanded(
            child: _filteredEvents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: currentPageEvents.length,
                    itemBuilder: (context, index) {
                      return _buildEventCard(currentPageEvents[index]);
                    },
                  ),
          ),
          
          // Paginazione
          if (totalPages > 1) _buildPagination(totalPages),
        ],
      ),
    );
  }
  
  /// Barra di ricerca
  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vgStoneGray.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Cerca eventi per nome...',
          hintStyle: TextStyle(color: AppTheme.vgStoneGray.withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search, color: AppTheme.vgBronze),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppTheme.vgStoneGray),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _applyFilters();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
  
  /// Chip per i filtri temporali
  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Oggi', EventFilter.day),
          _buildFilterChip('Settimana', EventFilter.week),
          _buildFilterChip('Mese', EventFilter.month),
          _buildFilterChip('Anno', EventFilter.year),
          _buildFilterChip('Tutti', EventFilter.all),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, EventFilter filter) {
    final isSelected = _currentFilter == filter;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _currentFilter = filter;
          });
          _applyFilters();
        },
        backgroundColor: Colors.white,
        selectedColor: AppTheme.vgBronze,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.vgStoneGray,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? AppTheme.vgBronze : AppTheme.vgStoneGray.withOpacity(0.3),
        ),
      ),
    );
  }
  
  /// Card singolo evento
  Widget _buildEventCard(EventModel event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.vgStoneGray.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => widget.onEventTap(event),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine evento con data in overlay
            Stack(
              children: [
                // Immagine
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      colors: [AppTheme.vgWarmStone, AppTheme.vgStoneGray],
                    ),
                  ),
                  child: event.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: Image.network(
                            event.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildEventPlaceholder();
                            },
                          ),
                        )
                      : _buildEventPlaceholder(),
                ),
                
                // Data in alto a destra
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.vgBronze,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      _formatEventDate(event.startTime),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Contenuto testuale
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.vgDarkSlate,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Descrizione
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.vgStoneGray,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventPlaceholder() {
    return Center(
      child: Icon(
        Icons.event,
        size: 60,
        color: AppTheme.vgBronze.withOpacity(0.3),
      ),
    );
  }
  
  /// Stato vuoto
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: AppTheme.vgStoneGray.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun evento trovato',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.vgStoneGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prova a modificare i filtri di ricerca',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.vgStoneGray.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Paginazione
  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
            icon: const Icon(Icons.arrow_back_ios),
            color: AppTheme.vgBronze,
          ),
          const SizedBox(width: 16),
          Text(
            'Pagina ${_currentPage + 1} di $totalPages',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.vgDarkSlate,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.arrow_forward_ios),
            color: AppTheme.vgBronze,
          ),
        ],
      ),
    );
  }
  
  String _formatEventDate(DateTime date) {
    final months = [
      'GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU',
      'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
  
  /// Ottieni eventi del mese corrente (placeholder)
  List<EventModel> _getEventsForCurrentMonth() {
    // TODO: Implementare caricamento eventi reali da database
    // Per ora restituisce una lista vuota
    return [];
  }
}

/// Enum per i filtri temporali
enum EventFilter {
  day,
  week,
  month,
  year,
  all,
}
