import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../pages/events_list_page.dart';
import '../pages/event_detail_page.dart';
import '../pages/restaurants_page.dart';
import '../pages/bars_page.dart';
import '../pages/map_page.dart';
import '../pages/storia_page.dart';
import '../pages/user_profile_page.dart';

/// Menu laterale di Visit Gubbio.
/// Sfondo avorio, logo centrato, voci minimali con divider.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                children: [
                  _menuItem(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: 'Eventi',
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
                  _menuItem(
                    context,
                    icon: Icons.restaurant_menu,
                    title: 'Ristoranti',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RestaurantsPage()),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.local_cafe_outlined,
                    title: 'Bar',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BarsPage()),
                      );
                    },
                  ),
                  _menuItem(
                    context,
                    icon: Icons.place_outlined,
                    title: 'Mappa',
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
                    title: 'Storia di Gubbio',
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
                    icon: Icons.person_outline_rounded,
                    title: 'Utente',
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

            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Versione 1.0.0',
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

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.rossoGubbio, size: 26),
      splashRadius: 24,
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
