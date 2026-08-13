import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/visit_gubbio_welcome_dialog.dart';
import 'events_list_page.dart';
import 'event_detail_page.dart';
import 'restaurants_page.dart';
import 'bars_page.dart';
import 'map_page.dart';

/// Home page landing di Visit Gubbio.
/// Grande hero a tutto schermo + card avorio per le sezioni principali.
class HomeLandingPage extends StatefulWidget {
  const HomeLandingPage({super.key});

  @override
  State<HomeLandingPage> createState() => _HomeLandingPageState();
}

class _HomeLandingPageState extends State<HomeLandingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasShownWelcome = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownWelcome && mounted) {
        _hasShownWelcome = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const VisitGubbioWelcomeDialog(),
        );
      }
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
              MaterialPageRoute(
                builder: (_) => EventDetailPage(event: event),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openRestaurants() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RestaurantsPage()),
    );
  }

  void _openBars() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BarsPage()),
    );
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Hero image (con fallback gradiente tramonto)
          _buildHero(),

          // Overlay scuro per leggibilità
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.heroOverlay),
          ),

          // Contenuto
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildTopBar(),
                  const Spacer(),
                  _buildWelcomeText(),
                  const SizedBox(height: 22),
                  _buildPlayButton(),
                  const SizedBox(height: 28),
                  _buildCardsGrid(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Image.asset(
      'assets/geo/hero.jpg',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback elegante se la foto hero non è presente
        return const DecoratedBox(
          decoration: BoxDecoration(gradient: AppColors.heroFallback),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _glassIconButton(
          icon: Icons.menu,
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ],
    );
  }

  Widget _glassIconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withOpacity(0.22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benvenuto in',
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            shadows: const [
              Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 1)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Gubbio',
          style: TextStyle(
            fontFamily: 'serif',
            color: Colors.white,
            fontSize: 64,
            fontWeight: FontWeight.w700,
            height: 1.0,
            letterSpacing: -1.0,
            shadows: [
              Shadow(color: Colors.black54, blurRadius: 14, offset: Offset(0, 2)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Scopri la magia di una delle città\nmedievali più affascinanti d'Italia.",
          style: TextStyle(
            color: Colors.white.withOpacity(0.92),
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.w400,
            shadows: const [
              Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return Material(
      color: Colors.transparent,
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
          width: 60,
          height: 60,
          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
        ),
      ),
    );
  }

  Widget _buildCardsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _sectionCard(
                icon: Icons.castle_outlined,
                title: 'Eventi',
                subtitle: 'Scopri cosa\nsuccede a Gubbio',
                onTap: _openEvents,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _sectionCard(
                icon: Icons.restaurant_menu,
                title: 'Ristoranti',
                subtitle: 'I migliori ristoranti\ndove gustare',
                onTap: _openRestaurants,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _sectionCard(
                icon: Icons.local_cafe_outlined,
                title: 'Bar',
                subtitle: 'I locali perfetti\nper una pausa',
                onTap: _openBars,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _sectionCard(
                icon: Icons.place_outlined,
                title: 'Mappa',
                subtitle: 'Esplora la città\ne i suoi luoghi',
                onTap: _openMap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.avorio,
      borderRadius: BorderRadius.circular(20),
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.rossoGubbio, size: 28),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluNotte,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
