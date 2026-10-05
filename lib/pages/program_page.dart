import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/event_timeline.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_bottom_nav.dart';
import '../data/events_data.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../models/user_mode.dart';

/// Pagina Programma con tabs per i tre eventi (15 Mag, 19 Mag, 2 Giu)
/// Mostra timeline verticale con stati automatici
/// Header e footer sempre visibili
class ProgramPage extends StatefulWidget {
  const ProgramPage({super.key});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final authService = context.watch<AuthService>();
    final isCeraiolo = authService.userMode == UserMode.ceraiolo;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: const CustomHeader(),
      body: Column(
        children: [
          // Titolo pagina
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              l10n.programTitle,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ),
          ),
          // Tabs
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFEAEAEA),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2F80ED), // Blu per indicatore
              indicatorWeight: 3,
              labelColor: const Color(0xFF2F80ED), // Blu per label selezionato
              unselectedLabelColor: const Color(0xFF6B6B6B),
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: l10n.tab15Mag),
                Tab(text: l10n.tab19Mag),
                Tab(text: l10n.tab2Giu),
              ],
            ),
          ),
          // Content delle tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 15 Maggio - Ceri Grandi
                EventTimeline(
                  events: get15MaggioEvents(),
                ),
                // 19 Maggio - Ceri Mezzani
                _buildComingSoonTab(l10n.ceriMezzani, l10n),
                // 2 Giugno - Ceri Piccoli
                _buildComingSoonTab(l10n.ceriPiccoli, l10n),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: 2, // Programma selezionato
        onTap: (index) => _handleNavigation(context, index, isCeraiolo),
        showMute: isCeraiolo,
        onLocationMenuTap: () {}, // Non utilizzato in questa pagina
        isLocationMenuOpen: false,
      ),
    );
  }

  /// Tab "Coming soon" per eventi futuri
  Widget _buildComingSoonTab(String eventName, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_rounded,
            size: 64,
            color: const Color(0xFFB22222).withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            eventName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.comingSoonProgram,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  /// Gestisce la navigazione dal footer
  void _handleNavigation(BuildContext context, int index, bool isCeraiolo) {
    if (index == 0) {
      // Home - torna alla home
      Navigator.of(context).pop();
    } else if (index == 1) {
      // Dove sono - torna alla home e attiva geolocalizzazione
      Navigator.of(context).pop();
    } else if (index == 2) {
      // Programma - già qui, non fare nulla
      return;
    } else if (index == 3 && isCeraiolo) {
      // Mute - torna alla home
      Navigator.of(context).pop();
    }
  }
}
