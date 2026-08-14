import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/itinerari_data.dart';
import '../models/itinerario_model.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import 'admin/add_place_page.dart';
import 'admin/add_event_page.dart';
import 'admin/add_itinerario_page.dart';
import 'events_list_page.dart';
import 'event_detail_page.dart';
import 'restaurants_page.dart';
import 'bars_page.dart';
import 'map_page.dart';
import 'storia_page.dart';
import 'itinerari_page.dart';
import 'itinerario_detail_page.dart';

/// Home page landing di Visit Gubbio.
/// Video/hero a tutto schermo sullo sfondo; in basso un pannello compatto
/// "Esplora Gubbio" + "Itinerari consigliati" che può scorrere via a destra
/// per liberare la vista sul video.
class HomeLandingPage extends StatefulWidget {
  const HomeLandingPage({super.key});

  @override
  State<HomeLandingPage> createState() => _HomeLandingPageState();
}

class _HomeLandingPageState extends State<HomeLandingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final LocationService _locationService = LocationService();
  bool _showPanel = true;

  @override
  void initState() {
    super.initState();
    // All'apertura chiediamo (una volta) il consenso alla posizione.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _locationService.ensureLocationPermission(context);
    });
  }

  void _openEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventsListPage(
          onEventTap: (event) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
            );
          },
        ),
      ),
    );
  }

  void _openRestaurants() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RestaurantsPage()),
      );

  void _openBars() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BarsPage()),
      );

  void _openMap() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapPage()),
      );

  void _openStoria() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StoriaPage()),
      );

  void _openItinerari() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ItinerariPage()),
      );

  void _openItinerario(ItinerarioModel it) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItinerarioDetailPage(itinerario: it)),
      );

  /// Menu amministratore: aggiungi contenuti.
  void _showAdminMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.avorio,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        Widget tile(IconData icon, String label, Widget page) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.rossoGubbio.withOpacity(0.12),
              child: Icon(icon, color: AppColors.rossoGubbio),
            ),
            title: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.bluNotte)),
            trailing: const Icon(Icons.chevron_right, color: AppColors.tortora),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grigioChiaro,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'AGGIUNGI CONTENUTO',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.bluNotte,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              tile(Icons.restaurant_menu, 'Aggiungi Ristorante',
                  const AddPlacePage(isBar: false)),
              tile(Icons.local_cafe_outlined, 'Aggiungi Bar',
                  const AddPlacePage(isBar: true)),
              tile(Icons.event, 'Aggiungi Evento', const AddEventPage()),
              tile(Icons.route, 'Aggiungi Itinerario',
                  const AddItinerarioPage()),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final panelHeight = (size.height * 0.36).clamp(250.0, 360.0);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      drawer: const AppDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Sfondo video/hero a tutto schermo
          _buildVideoBackground(),

          // Barra superiore + titolo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _glassIconButton(
                        icon: Icons.menu,
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      if (context.watch<AuthService>().isAdmin)
                        _glassIconButton(
                          icon: Icons.add,
                          onTap: _showAdminMenu,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildTitle(),
                ],
              ),
            ),
          ),

          // Pulsante centrale "play" del video
          Align(
            alignment: const Alignment(0, -0.15),
            child: _buildPlayButton(),
          ),

          // Linguetta per riaprire il pannello (visibile quando è nascosto)
          Positioned(
            right: 0,
            bottom: panelHeight * 0.5,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              offset: _showPanel ? const Offset(1.4, 0) : Offset.zero,
              child: _buildReopenTab(),
            ),
          ),

          // Pannello "Esplora Gubbio" scorrevole
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
              offset: _showPanel ? Offset.zero : const Offset(1.05, 0),
              child: _buildPanel(panelHeight),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------- Sfondo video
  Widget _buildVideoBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/geo/hero.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.heroFallback),
          ),
        ),
        // Leggera vignettatura per leggibilità, senza coprire il video
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.28),
                Colors.black.withOpacity(0.05),
                Colors.black.withOpacity(0.15),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VISIT',
          style: TextStyle(
            fontFamily: 'serif',
            color: Colors.white.withOpacity(0.95),
            fontSize: 24,
            fontWeight: FontWeight.w500,
            letterSpacing: 5,
            shadows: const [
              Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2)),
            ],
          ),
        ),
        const Text(
          'GUBBIO',
          style: TextStyle(
            fontFamily: 'serif',
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1.0,
            letterSpacing: 1,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 2)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return Material(
      color: Colors.white.withOpacity(0.16),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withOpacity(0.9), width: 2),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video di presentazione in arrivo'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: const SizedBox(
          width: 68,
          height: 68,
          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 38),
        ),
      ),
    );
  }

  // -------------------------------------------------- Linguetta riapertura
  Widget _buildReopenTab() {
    return Material(
      color: AppColors.rossoGubbio,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        bottomLeft: Radius.circular(16),
      ),
      elevation: 6,
      child: InkWell(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        onTap: () => setState(() => _showPanel = true),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
              SizedBox(height: 4),
              Icon(Icons.explore_outlined, color: Colors.white, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------- Pannello Esplora
  Widget _buildPanel(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.avorio,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con titolo e freccetta per nascondere
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ESPLORA GUBBIO',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bluNotte,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _hideButton(),
                ],
              ),
              const SizedBox(height: 12),

              // Accessi rapidi
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _quickAction(Icons.place_outlined, 'Mappa', _openMap),
                  _quickAction(
                      Icons.auto_stories_outlined, 'Storia', _openStoria),
                  _quickAction(Icons.local_cafe_outlined, 'Bar', _openBars),
                  _quickAction(
                      Icons.restaurant_menu, 'Ristoranti', _openRestaurants),
                  _quickAction(
                      Icons.calendar_today_outlined, 'Eventi', _openEvents),
                ],
              ),
              const SizedBox(height: 16),

              // Itinerari
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ITINERARI CONSIGLIATI',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bluNotte,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openItinerari,
                    child: const Text(
                      'Vedi tutti',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.rossoGubbio,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildItinerariRow()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hideButton() {
    return Material(
      color: AppColors.grigioChiaro.withOpacity(0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _showPanel = false),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(Icons.chevron_right_rounded,
              color: AppColors.bluNotte, size: 24),
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.grigioChiaro),
                ),
                child: Icon(icon, color: AppColors.rossoGubbio, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.bluNotte,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Riga itinerari: 3 card visibili senza scroll
  Widget _buildItinerariRow() {
    const gap = 10.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - gap * 2) / 3;
        return Row(
          children: List.generate(itinerariConsigliati.length.clamp(0, 3), (i) {
            final it = itinerariConsigliati[i];
            return Padding(
              padding: EdgeInsets.only(right: i < 2 ? gap : 0),
              child: _buildItinerarioCard(it, cardWidth),
            );
          }),
        );
      },
    );
  }

  Widget _buildItinerarioCard(ItinerarioModel it, double width) {
    return GestureDetector(
      onTap: () => _openItinerario(it),
      child: SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.grigioChiaro, AppColors.tortora],
                  ),
                ),
                child: Center(
                  child: Icon(it.icona,
                      size: 26, color: Colors.white.withOpacity(0.9)),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xC0000000)],
                    stops: [0.4, 1.0],
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withOpacity(0.22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
