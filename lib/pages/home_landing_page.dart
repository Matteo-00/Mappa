import '../services/user_location_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/itinerario_model.dart';
import '../models/event_model.dart';
import 'luoghi_page.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/content_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/home_video_background.dart';
import 'admin/add_place_page.dart';
import 'admin/add_event_page.dart';
import 'admin/add_luogo_page.dart';
import '../models/luogo_model.dart';
import 'admin/add_itinerario_page.dart';
import 'events_list_page.dart';
import 'event_detail_page.dart';
import 'restaurants_page.dart';
import 'bars_page.dart';
import 'hotels_page.dart';
import 'admin/scegli_vetrina_page.dart';
import 'admin/review_reports_page.dart';
import '../services/review_service.dart';
import '../utils/route_observer.dart';
import 'map_page.dart';
import 'storia_page.dart';
import 'user_profile_page.dart';
import 'itinerari_page.dart' show ItinerariPage, itinerarioImagePlaceholder;
import 'itinerario_detail_page.dart';

/// Home page landing di Visit Gubbio.
/// Video/hero a tutto schermo sullo sfondo; in basso il pannello "Esplora
/// Gubbio" che si tira su e giù con il dito (o con il pulsante freccia): chiuso
/// in basso lascia vedere il video, a metà mostra i 3 itinerari della vetrina,
/// aperto anche gli accessi rapidi e i prossimi eventi.
class HomeLandingPage extends StatefulWidget {
  const HomeLandingPage({super.key});

  @override
  State<HomeLandingPage> createState() => _HomeLandingPageState();
}

class _HomeLandingPageState extends State<HomeLandingPage> with RouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final LocationService _locationService = LocationService();
  late AppLocalizations _l10n;
  List<ItinerarioModel> _itinerariConsigliati = [];

  /// Prossimi eventi pubblicati (al massimo 6), dal più vicino.
  List<EventModel> _prossimiEventi = [];

  /// Pannello "Esplora Gubbio": si trascina tra chiuso, metà e aperto.
  final DraggableScrollableController _sheet = DraggableScrollableController();

  /// Quanto è aperto il pannello (frazione dell'altezza dello schermo).
  double _sheetExtent = 0;

  /// Solo admin: recensioni segnalate ancora da controllare (numero rosso).
  int _reportedCount = 0;

  /// Audio del video di sfondo: parte muto, il pulsante lo attiva.
  final ValueNotifier<bool> _videoMuted = ValueNotifier<bool>(true);

  /// Il video va una volta sola: a fine corsa [_videoFinished] diventa true e
  /// compare il pulsante "play"; premendolo [_videoReplay] fa ripartire il video.
  final ValueNotifier<bool> _videoFinished = ValueNotifier<bool>(false);
  final ValueNotifier<int> _videoReplay = ValueNotifier<int>(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  /// Si torna sulla home (es. dalle recensioni segnalate): numero aggiornato.
  @override
  void didPopNext() => _loadReportedCount();

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _videoMuted.dispose();
    _videoFinished.dispose();
    _videoReplay.dispose();
    _sheet.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // All'apertura chiediamo (una volta) il consenso alla posizione.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Dopo la scelta dell'utente aggiorna la posizione condivisa (distanze).
      _locationService
          .ensureLocationPermission(context)
          .then((_) => UserLocationService.instance.refresh());
    });
    _loadItinerari();
    _loadEventi();
    _loadReportedCount();
  }

  Future<void> _loadEventi() async {
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    final all = await ContentService.fetchEvents(languageCode: languageCode);
    final now = DateTime.now();
    final next = all
        .where((e) => !e.isDraft && !e.endTime.isBefore(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (!mounted) return;
    setState(() => _prossimiEventi = next.take(6).toList());
  }

  Future<void> _loadReportedCount() async {
    if (!context.read<AuthService>().isAdmin) return;
    final count = await ReviewService.countReported();
    if (!mounted) return;
    setState(() => _reportedCount = count);
  }

  Future<void> _openReportedReviews() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReviewReportsPage()),
    );
    _loadReportedCount();
  }

  Future<void> _loadItinerari() async {
    final languageCode = context.read<LanguageService>().currentLanguageCode;
    // Vetrina: i 3 itinerari scelti dall'admin (o i primi 3 se non ne ha scelti).
    final items =
        await ContentService.fetchItinerariVetrina(languageCode: languageCode);
    if (!mounted) return;
    setState(() => _itinerariConsigliati = items);
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

  void _openHotels() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HotelsPage()),
      );

  void _openMap() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapPage()),
      );

  void _openStoria() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StoriaPage()),
      );

  /// Solo admin: sceglie quali itinerari mostrare in vetrina.
  Future<void> _chooseVetrina() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ScegliVetrinaPage()),
    );
    if (changed == true) _loadItinerari();
  }

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
              backgroundColor: AppColors.rossoGubbio.withValues(alpha: 0.12),
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

        // Con tanti elementi il menu scorre invece di uscire dallo schermo.
        return SafeArea(
          child: SingleChildScrollView(
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _l10n.addContentTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.bluNotte,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              tile(Icons.restaurant_menu, _l10n.addRestaurantMenuItem,
                  const AddPlacePage(isBar: false)),
              tile(Icons.local_cafe_outlined, _l10n.addBarMenuItem,
                  const AddPlacePage(isBar: true)),
              tile(Icons.hotel_outlined, _l10n.addHotelMenuItem,
                  const AddPlacePage(isBar: false, isHotel: true)),
              for (final t in LuogoTipo.values)
                tile(t.icon, _l10n.t('add_${t.name}'),
                    AddLuogoPage(tipo: t)),
              tile(Icons.event, _l10n.addEventMenuItem, const AddEventPage()),
              tile(Icons.route, _l10n.addItinerarioMenuItem,
                  const AddItinerarioPage()),
              const SizedBox(height: 12),
            ],
          ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final size = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    // Posizioni del pannello: chiuso (solo il titolo), metà, aperto.
    final minExtent = ((96 + bottomInset) / size.height).clamp(0.08, 0.2);
    // A metà: quanto basta per vedere per intero i 3 itinerari della vetrina
    // (titolo del pannello + intestazione + schede), su qualsiasi schermo.
    final midExtent =
        ((385 + bottomInset) / size.height).clamp(minExtent + 0.1, 0.7);
    const maxExtent = 0.88;
    if (_sheetExtent == 0) _sheetExtent = midExtent;

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
                      // In alto a destra: il profilo (icona utente) per tutti e,
                      // alla sua sinistra, solo per gli amministratori, le
                      // recensioni segnalate (con il numero di quelle ancora da
                      // controllare) e il "+" per aggiungere contenuti.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (context.watch<AuthService>().isAdmin) ...[
                            _withBadge(
                              _glassIconButton(
                                icon: Icons.feedback_outlined,
                                onTap: _openReportedReviews,
                              ),
                              _reportedCount,
                            ),
                            const SizedBox(width: 10),
                            _glassIconButton(
                              icon: Icons.add,
                              onTap: _showAdminMenu,
                            ),
                            const SizedBox(width: 10),
                          ],
                          _glassIconButton(
                            icon: Icons.person_outline_rounded,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const UserProfilePage()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Con il pannello tutto aperto il titolo si nasconde.
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _sheetExtent > 0.75 ? 0 : 1,
                    child: _buildTitle(),
                  ),
                ],
              ),
            ),
          ),

          // Pulsante audio del video: segue il bordo del pannello.
          Positioned(
            left: 20,
            bottom: _sheetExtent * size.height + 14,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              // Con il pannello tutto aperto il video non si vede: niente audio.
              opacity: _sheetExtent > 0.75 ? 0 : 1,
              child: IgnorePointer(
                ignoring: _sheetExtent > 0.75,
                child: _buildSoundButton(),
              ),
            ),
          ),

          // Pannello "Esplora Gubbio": si tira su e giù con il dito.
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (n) {
              setState(() => _sheetExtent = n.extent);
              return false;
            },
            child: DraggableScrollableSheet(
              controller: _sheet,
              initialChildSize: midExtent,
              minChildSize: minExtent,
              maxChildSize: maxExtent,
              snap: true,
              snapSizes: [midExtent],
              builder: (context, scrollController) => _buildPanel(
                scrollController,
                minExtent: minExtent,
                midExtent: midExtent,
                maxExtent: maxExtent,
              ),
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
        // Video a tutto schermo; finché non è pronto (o se manca) lo sfondo di riserva.
        HomeVideoBackground(
          muted: _videoMuted,
          finished: _videoFinished,
          replay: _videoReplay,
          fallback: Image.asset(
            'assets/geo/hero.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.heroFallback),
            ),
          ),
        ),
        // Leggera vignettatura per leggibilità, senza coprire il video
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.28),
                Colors.black.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.15),
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
            color: Colors.white.withValues(alpha: 0.95),
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

  /// Attiva / disattiva l'audio del video di sfondo.
  Widget _buildSoundButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _videoMuted,
          builder: (context, muted, _) => _glassIconButton(
            icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            onTap: () => _videoMuted.value = !muted,
          ),
        ),
        // A video finito: "play" per rivederlo.
        ValueListenableBuilder<bool>(
          valueListenable: _videoFinished,
          builder: (context, finished, _) => finished
              ? Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: _glassIconButton(
                    icon: Icons.play_arrow_rounded,
                    onTap: () => _videoReplay.value++,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // -------------------------------------------------- Pannello Esplora

  /// Freccia del pannello: lo apre del tutto oppure lo richiude in basso.
  void _toggleSheet(double minExtent, double maxExtent) {
    final open = _sheetExtent > maxExtent - 0.04;
    _sheet.animateTo(
      open ? minExtent : maxExtent,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildPanel(
    ScrollController scrollController, {
    required double minExtent,
    required double midExtent,
    required double maxExtent,
  }) {
    final isAdmin = context.watch<AuthService>().isAdmin;
    final isOpen = _sheetExtent > maxExtent - 0.04;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.avorio,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        // Il pannello si trascina anche con il mouse (versione web).
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: PointerDeviceKind.values.toSet(),
          ),
          child: ListView(
          controller: scrollController,
          padding: EdgeInsets.only(
              bottom: 24 + MediaQuery.of(context).padding.bottom),
          children: [
            // Intestazione: si trascina, e un tocco la apre/chiude.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleSheet(minExtent, maxExtent),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 14, 6),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.tortora.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _l10n.exploreGubbioTitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.rossoGubbio,
                                  letterSpacing: 1.6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _l10n.t('homeExploreSubtitle'),
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.bluNotte,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: AppColors.rossoGubbio,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _toggleSheet(minExtent, maxExtent),
                            child: Tooltip(
                              message: _l10n
                                  .t(isOpen ? 'homeCollapse' : 'homeExpand'),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: AnimatedRotation(
                                  turns: isOpen ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 300),
                                  child: const Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Itinerari consigliati: i 3 della vetrina, tutti visibili già
            // con il pannello a metà.
            _sectionHeader(
              _l10n.suggestedItinerariesNav,
              top: 6,
              onSeeAll: _openItinerari,
              extra: isAdmin
                  ? GestureDetector(
                      onTap: _chooseVetrina,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 15, color: AppColors.bluNotte),
                            SizedBox(width: 4),
                            Text(
                              'Scegli',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.bluNotte,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
            _buildItinerariVetrina(),

            // Accessi rapidi (2 righe da 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
              child: _buildQuickGrid(),
            ),

            // Prossimi eventi
            _sectionHeader(_l10n.t('homeUpcomingEvents'),
                onSeeAll: _openEvents),
            _buildEventsRow(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title,
      {required VoidCallback onSeeAll, Widget? extra, double top = 22}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top, 20, 10),
      child: Row(
        children: [
          Expanded(
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
          if (extra != null) extra,
          GestureDetector(
            onTap: onSeeAll,
            child: Text(
              _l10n.seeAllLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.rossoGubbio,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------- Accessi rapidi
  Widget _buildQuickGrid() {
    final items = <(IconData, String, Color, VoidCallback)>[
      (Icons.map_outlined, _l10n.mapNav, const Color(0xFF2E7D6B), _openMap),
      (Icons.calendar_month_outlined, _l10n.events, AppColors.rossoGubbio,
          _openEvents),
      (Icons.auto_stories_outlined, _l10n.storiaShortLabel,
          const Color(0xFF8D6E63), _openStoria),
      (Icons.route_outlined, _l10n.t('mapItinerari'), const Color(0xFF3F51B5),
          _openItinerari),
      (Icons.restaurant_menu, _l10n.restaurantsNav, const Color(0xFFD84315),
          _openRestaurants),
      (Icons.local_cafe_outlined, _l10n.barsNav, const Color(0xFF6D4C41),
          _openBars),
      (Icons.hotel_outlined, _l10n.hotelsNav, const Color(0xFF00838F),
          _openHotels),
      (LuogoTipo.parcheggio.icon, _l10n.t(LuogoTipo.parcheggio.navKey),
          LuogoTipo.parcheggio.color, _openParcheggi),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 4,
      childAspectRatio: 0.92,
      children: [
        for (final (icon, label, color, onTap) in items)
          _quickAction(icon, label, color, onTap),
      ],
    );
  }

  void _openParcheggi() => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const LuoghiPage(tipo: LuogoTipo.parcheggio)),
      );

  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
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
    );
  }

  // -------------------------------------------------- Itinerari (vetrina)
  /// I 3 itinerari scelti per la vetrina, affiancati e tutti visibili.
  Widget _buildItinerariVetrina() {
    final items = _itinerariConsigliati.take(3).toList();
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: _openItinerari,
          child: SizedBox(
            height: 150,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: itinerarioImagePlaceholder('',
                  icon: Icons.route_outlined),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _buildItinerarioCard(items[i])),
            ],
            // Con meno di 3 itinerari le schede restano della stessa larghezza.
            for (var i = items.length; i < 3; i++) ...[
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItinerarioCard(ItinerarioModel it) {
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
          boxShadow: [
            BoxShadow(
              color: AppColors.bluNotte.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (it.imageUrl != null)
                Image.network(
                  it.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => placeholder,
                )
              else
                placeholder,
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x26000000),
                      Color(0x00000000),
                      Color(0xE6000000),
                    ],
                    stops: [0.0, 0.3, 1.0],
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
                    child: _glassChip(it.tema.toUpperCase(), strong: true),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        meta,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
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

  Widget _glassChip(String text, {IconData? icon, bool strong = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: strong
            ? AppColors.rossoGubbio.withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: strong
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: strong ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: strong ? 0.8 : 0,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------- Prossimi eventi
  Widget _buildEventsRow() {
    final events = _prossimiEventi;
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          _l10n.t('homeNoUpcomingEvents'),
          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
        ),
      );
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _buildEventCard(events[i]),
      ),
    );
  }

  Widget _buildEventCard(EventModel e) {
    final months = _l10n.list('monthsShort');
    final now = DateTime.now();
    final live = !e.startTime.isAfter(now) && !e.endTime.isBefore(now);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailPage(event: e)),
        ),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.grigioChiaro),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.rossoGubbio.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      months[e.startTime.month - 1],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.rossoGubbio,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      '${e.startTime.day}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bluNotte,
                        height: 1.1,
                      ),
                    ),
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
                      Text(
                        _l10n.t('eventNow'),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rossoGubbio,
                          letterSpacing: 0.6,
                        ),
                      ),
                    Text(
                      e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bluNotte,
                        height: 1.2,
                      ),
                    ),
                    if (e.location.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              e.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                            ),
                          ),
                        ],
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

  /// Pallino rosso con il numero in alto a destra (nascosto se 0).
  Widget _withBadge(Widget child, int count) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -3,
          right: -3,
          child: IgnorePointer(
            child: Container(
              constraints: const BoxConstraints(minWidth: 20),
              height: 20,
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.22),
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
