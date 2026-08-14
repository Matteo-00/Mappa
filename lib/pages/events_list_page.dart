import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../services/content_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import 'admin/admin_widgets.dart';

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
  EventFilter _currentFilter = EventFilter.all;
  
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
  
  Future<void> _loadEvents() async {
    final events = await ContentService.fetchEvents();
    if (!mounted) return;
    setState(() {
      _allEvents = events;
    });
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
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          const PremiumHeader(title: 'Eventi'),

          // Barra di ricerca
          _buildSearchBar(),
          
          // Filtri temporali
          _buildFilterChips(),
          
          // Lista eventi
          Expanded(
            child: _filteredEvents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
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
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _applyFilters();
        },
        decoration: InputDecoration(
          hintText: 'Cerca eventi per nome...',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(Icons.search, color: AppColors.rossoGubbio),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.tortora),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
  
  /// Chip per i filtri temporali
  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
        showCheckmark: false,
        onSelected: (selected) {
          setState(() {
            _currentFilter = filter;
          });
          _applyFilters();
        },
        backgroundColor: Colors.white,
        selectedColor: AppColors.rossoGubbio,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.bluNotte,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        side: BorderSide(
          color: isSelected ? AppColors.rossoGubbio : AppColors.grigioChiaro,
        ),
      ),
    );
  }
  
  /// Card singolo evento
  Future<void> _deleteEvent(EventModel event) async {
    final ok = await confirmDelete(context, event.title);
    if (!ok) return;
    try {
      await ContentService.deleteEvent(event.id);
      await _loadEvents();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento eliminato'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  Widget _buildEventCard(EventModel event) {
    final canDelete = context.watch<AuthService>().isAdmin &&
        ContentService.isRemoteId(event.id);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => widget.onEventTap(event),
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine evento con data in overlay
            Stack(
              children: [
                // Immagine
                Container(
                  height: 170,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.tortora.withOpacity(0.4),
                        AppColors.avorio,
                      ],
                    ),
                  ),
                  child: event.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.rossoGubbio,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
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

                // Pulsante elimina (solo admin)
                if (canDelete)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _deleteEvent(event),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.delete_outline,
                              size: 20, color: AppColors.rossoGubbio),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Contenuto testuale
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titolo
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bluNotte,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Descrizione
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
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
        Icons.festival_outlined,
        size: 56,
        color: AppColors.rossoGubbio.withOpacity(0.4),
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
            size: 76,
            color: AppColors.tortora.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessun evento trovato',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Prova a modificare i filtri di ricerca',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
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
            color: AppColors.rossoGubbio,
          ),
          const SizedBox(width: 16),
          Text(
            'Pagina ${_currentPage + 1} di $totalPages',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
            icon: const Icon(Icons.arrow_forward_ios),
            color: AppColors.rossoGubbio,
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
}

/// Enum per i filtri temporali
enum EventFilter {
  day,
  week,
  month,
  year,
  all,
}
