import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../pages/user_profile_page.dart';

/// Header uniformato per entrambe le modalità (Visit Gubbio / Festa dei Ceri)
/// Struttura identica, cambiano solo i colori del tema
class UnifiedHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuTap;
  
  const UnifiedHeader({
    super.key,
    required this.onMenuTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final mode = themeProvider.currentMode;
        final bgColor = AppTheme.getHeaderBackground(mode);
        final textColor = AppTheme.getHeaderText(mode);
        final iconColor = AppTheme.getHeaderIcon(mode);
        
        return Container(
          height: 65,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(
                color: mode == AppMode.visitGubbio 
                    ? AppTheme.vgStoneGray.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // SINISTRA: Menu hamburger
              _buildMenuButton(iconColor),
              
              // CENTRO: Titolo con cornice elegante
              _buildAppTitle(themeProvider, textColor, iconColor),
              
              // DESTRA: Icona profilo utente
              _buildProfileButton(context, iconColor),
            ],
          ),
        );
      },
    );
  }
  
  /// Pulsante menu hamburger
  Widget _buildMenuButton(Color iconColor) {
    return IconButton(
      onPressed: onMenuTap,
      icon: Icon(
        Icons.menu_rounded,
        color: iconColor,
        size: 28,
      ),
      tooltip: 'Menu',
      splashRadius: 24,
    );
  }
  
  /// Titolo dell'app con cornice elegante
  Widget _buildAppTitle(ThemeProvider themeProvider, Color textColor, Color accentColor) {
    final title = themeProvider.getAppTitle();
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(title),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          gradient: themeProvider.isVisitGubbio
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.1),
                  ],
                )
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 1.2,
            fontFamily: 'serif',
          ),
        ),
      ),
    );
  }
  
  /// Pulsante profilo utente
  Widget _buildProfileButton(BuildContext context, Color iconColor) {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const UserProfilePage(),
          ),
        );
      },
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person_rounded,
          color: iconColor,
          size: 22,
        ),
      ),
      tooltip: 'Profilo',
      splashRadius: 24,
    );
  }
}
