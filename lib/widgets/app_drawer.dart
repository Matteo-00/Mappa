import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

/// Menu laterale (drawer) per la navigazione principale
/// Voci del menu dipendono dalla modalità corrente
class AppDrawer extends StatelessWidget {
  final Function(String) onMenuItemSelected;
  
  const AppDrawer({
    super.key,
    required this.onMenuItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final mode = themeProvider.currentMode;
        
        return Drawer(
          backgroundColor: mode == AppMode.visitGubbio 
              ? AppTheme.vgAncientParchment 
              : AppTheme.fcLightBackground,
          child: SafeArea(
            child: Column(
              children: [
                // Header del drawer
                _buildDrawerHeader(context, themeProvider),
                
                const SizedBox(height: 8),
                
                // Menu items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _buildMenuItems(context, themeProvider),
                  ),
                ),
                
                // Footer del drawer
                _buildDrawerFooter(themeProvider),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Header del drawer con logo/titolo
  Widget _buildDrawerHeader(BuildContext context, ThemeProvider themeProvider) {
    final isVisitGubbio = themeProvider.isVisitGubbio;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isVisitGubbio 
            ? AppTheme.vgCardGradient 
            : AppTheme.fcHeaderGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isVisitGubbio ? Icons.location_city : Icons.celebration,
            size: 40,
            color: isVisitGubbio ? AppTheme.vgBronze : Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            themeProvider.getAppTitle(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isVisitGubbio ? AppTheme.vgDarkSlate : Colors.white,
              letterSpacing: 0.5,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isVisitGubbio 
                ? 'Esplora la città medievale' 
                : 'Una tradizione millenaria',
            style: TextStyle(
              fontSize: 13,
              color: isVisitGubbio 
                  ? AppTheme.vgStoneGray 
                  : Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Costruisce le voci del menu in base alla modalità
  List<Widget> _buildMenuItems(BuildContext context, ThemeProvider themeProvider) {
    if (themeProvider.isVisitGubbio) {
      return [
        _buildMenuItem(
          context,
          icon: Icons.event,
          title: 'Eventi',
          subtitle: 'Scopri cosa succede in città',
          onTap: () {
            Navigator.pop(context);
            onMenuItemSelected('eventi');
          },
          themeProvider: themeProvider,
        ),
        _buildMenuItem(
          context,
          icon: Icons.restaurant,
          title: 'Ristoranti',
          subtitle: 'Dove mangiare a Gubbio',
          onTap: () {
            Navigator.pop(context);
            onMenuItemSelected('ristoranti');
          },
          themeProvider: themeProvider,
        ),
        const Divider(height: 32),
        _buildMenuItem(
          context,
          icon: Icons.celebration,
          title: 'Festa dei Ceri',
          subtitle: 'Entra nella tradizione',
          onTap: () {
            Navigator.pop(context);
            onMenuItemSelected('festa_ceri');
          },
          themeProvider: themeProvider,
          highlight: true,
        ),
      ];
    } else {
      // Menu per modalità Festa dei Ceri
      return [
        _buildMenuItem(
          context,
          icon: Icons.calendar_today,
          title: 'Programma',
          subtitle: 'Eventi della festa',
          onTap: () {
            Navigator.pop(context);
            onMenuItemSelected('programma');
          },
          themeProvider: themeProvider,
        ),
        _buildMenuItem(
          context,
          icon: Icons.info_outline,
          title: 'Informazioni',
          subtitle: 'Storia della festa',
          onTap: () {
            Navigator.pop(context);
            onMenuItemSelected('informazioni');
          },
          themeProvider: themeProvider,
        ),
        const Divider(height: 32),
        _buildMenuItem(
          context,
          icon: Icons.arrow_back,
          title: 'Torna a Visit Gubbio',
          subtitle: 'Menu principale',
          onTap: () {
            Navigator.pop(context);
            onMenuItemSelected('visit_gubbio');
          },
          themeProvider: themeProvider,
          highlight: true,
        ),
      ];
    }
  }
  
  /// Singola voce del menu
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
    bool highlight = false,
  }) {
    final isVisitGubbio = themeProvider.isVisitGubbio;
    final accentColor = isVisitGubbio ? AppTheme.vgBronze : AppTheme.fcDeepRed;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: highlight 
            ? accentColor.withOpacity(0.1) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: accentColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isVisitGubbio ? AppTheme.vgDarkSlate : AppTheme.fcBlack,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isVisitGubbio ? AppTheme.vgStoneGray : Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: accentColor.withOpacity(0.5),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  /// Footer del drawer
  Widget _buildDrawerFooter(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: themeProvider.isVisitGubbio 
                ? AppTheme.vgStoneGray.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Text(
        '© 2026 Visit Gubbio\nVersione 1.0.0',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: themeProvider.isVisitGubbio 
              ? AppTheme.vgStoneGray 
              : Colors.grey[600],
        ),
      ),
    );
  }
}
