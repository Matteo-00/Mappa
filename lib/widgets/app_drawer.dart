import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import 'scroll_hints.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../pages/events_list_page.dart';
import '../pages/event_detail_page.dart';
import '../pages/restaurants_page.dart';
import '../pages/bars_page.dart';
import '../pages/hotels_page.dart';
import '../pages/luoghi_page.dart';
import '../models/luogo_model.dart';
import '../pages/map_page.dart';
import '../pages/storia_page.dart';
import '../pages/itinerari_page.dart';
import '../pages/user_profile_page.dart';
import '../pages/login_page.dart';

/// Sottovoce di un gruppo del menu (icona, titolo, pagina da aprire).
class _SubItem {
  final IconData icon;
  final String title;
  final Widget Function() page;
  const _SubItem(this.icon, this.title, this.page);
}

/// Menu laterale di Visit Gubbio.
/// Sfondo avorio, logo centrato, voci minimali con divider.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: AppColors.avorio,
      child: SafeArea(
        child: Column(
          children: [
            // Riga superiore: chiudi
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _iconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Logo centrato
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 24),
              child: SizedBox(
                height: 190,
                child: Image.asset(
                  'assets/geo/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: AppColors.grigioChiaro, height: 1),
            ),

            // Voci menu
            Expanded(
              child: VerticalScrollHint(
                fadeColor: AppColors.avorio,
                builder: (scrollController) => ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: [
                  _menuItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: l10n.events,
                    onTap: () {
                      Navigator.pop(context);
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
                    },
                  ),
                  // Un'unica voce che si apre con le 3 sottovoci: risparmia spazio nel menu.
                  _menuGroup(
                    context,
                    icon: Icons.restaurant_menu,
                    title: l10n.t('menuEatDrinkStay'),
                    items: [
                      _SubItem(Icons.restaurant_menu, l10n.restaurantsNav,
                          () => const RestaurantsPage()),
                      _SubItem(Icons.local_cafe_outlined, l10n.barsNav,
                          () => const BarsPage()),
                      _SubItem(Icons.hotel_outlined, l10n.hotelsNav,
                          () => const HotelsPage()),
                    ],
                  ),
                  // Chiese, musei e negozi.
                  _menuGroup(
                    context,
                    icon: Icons.museum_outlined,
                    title: l10n.t('menuCultureShops'),
                    items: [
                      for (final t in const [
                        LuogoTipo.chiesa,
                        LuogoTipo.museo,
                        LuogoTipo.negozio,
                      ])
                        _SubItem(t.icon, l10n.t(t.navKey),
                            () => LuoghiPage(tipo: t)),
                    ],
                  ),
                  _menuItem(
                    context,
                    icon: Icons.place_outlined,
                    title: l10n.mapNav,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapPage()),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.auto_stories_outlined,
                    title: l10n.storiaDiGubbioNav,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StoriaPage()),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.map_outlined,
                    title: l10n.suggestedItinerariesNav,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ItinerariPage()),
                      );
                    },
                  ),
                  // Informazioni utili (per ora solo i parcheggi).
                  _menuGroup(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: l10n.t('menuUsefulInfo'),
                    items: [
                      _SubItem(
                        LuogoTipo.parcheggio.icon,
                        l10n.t(LuogoTipo.parcheggio.navKey),
                        () => const LuoghiPage(tipo: LuogoTipo.parcheggio),
                      ),
                    ],
                  ),
                  _menuItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    title: l10n.userNav,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const UserProfilePage()),
                      );
                    },
                  ),
                ],
              ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.rossoGubbio, size: 22),
                  label: Text(
                    l10n.logout,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.rossoGubbio,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.rossoGubbio),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                l10n.appVersionLabel('1.2.0'),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.exitConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    await context.read<AuthService>().logout();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.rossoGubbio, size: 26),
      splashRadius: 24,
    );
  }

  /// Voce del menu che si espande mostrando delle sottovoci.
  Widget _menuGroup(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<_SubItem> items,
  }) {
    return Column(
      children: [
        Theme(
          // Toglie le linee che ExpansionTile disegna di default.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(icon, color: AppColors.rossoGubbio, size: 24),
            title: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.bluNotte,
              ),
            ),
            iconColor: AppColors.rossoGubbio,
            collapsedIconColor: AppColors.tortora,
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            childrenPadding: const EdgeInsets.only(left: 22, bottom: 6),
            shape: const Border(),
            collapsedShape: const Border(),
            children: [
              for (final item in items)
                ListTile(
                  dense: true,
                  leading: Icon(item.icon, color: AppColors.tortora, size: 22),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.bluNotte,
                    ),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item.page()),
                    );
                  },
                ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: AppColors.grigioChiaro, height: 1),
        ),
      ],
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.rossoGubbio, size: 24),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.bluNotte,
            ),
          ),
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          hoverColor: AppColors.grigioChiaro.withOpacity(0.4),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(color: AppColors.grigioChiaro, height: 1),
        ),
      ],
    );
  }
}
