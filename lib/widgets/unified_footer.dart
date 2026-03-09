import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

/// Footer uniformato per entrambe le modalità
/// Struttura identica, cambiano solo colori e nomi dei pulsanti
class UnifiedFooter extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onNavigationTap;
  final VoidCallback onLocationMenuTap;
  final bool isLocationMenuOpen;
  
  const UnifiedFooter({
    super.key,
    required this.selectedIndex,
    required this.onNavigationTap,
    required this.onLocationMenuTap,
    required this.isLocationMenuOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final mode = themeProvider.currentMode;
        final bgColor = AppTheme.getFooterBackground(mode);
        final selectedColor = AppTheme.getFooterSelected(mode);
        final unselectedColor = AppTheme.getFooterUnselected(mode);
        
        return Container(
          height: 70,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
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
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // SINISTRA: Home
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: selectedIndex == 0,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => onNavigationTap(0),
              ),
              
              // CENTRO: Pulsante posizione (RIFATTO COMPLETAMENTE)
              _buildLocationButton(
                mode: mode,
                selectedColor: selectedColor,
              ),
              
              // DESTRA: Eventi (Visit Gubbio) o Programma (Festa dei Ceri)
              _buildNavItem(
                icon: Icons.calendar_today_rounded,
                label: themeProvider.isVisitGubbio ? 'Eventi' : 'Programma',
                isSelected: selectedIndex == 1,
                selectedColor: selectedColor,
                unselectedColor: unselectedColor,
                onTap: () => onNavigationTap(1),
              ),
            ],
          ),
        );
      },
    );
  }
  
  /// Pulsante navigazione standard
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required Color unselectedColor,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? selectedColor : unselectedColor;
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: selectedColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Pulsante centrale posizione COMPLETAMENTE RIFATTO
  /// Comportamento: click → appaiono 2 pulsanti rotondi sopra
  Widget _buildLocationButton({
    required AppMode mode,
    required Color selectedColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onLocationMenuTap,
        splashColor: selectedColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icona che ruota quando il menu è aperto
            AnimatedRotation(
              turns: isLocationMenuOpen ? 0.125 : 0, // Ruota di 45° quando aperto
              duration: const Duration(milliseconds: 250),
              child: Icon(
                isLocationMenuOpen ? Icons.close : Icons.location_on_rounded,
                color: selectedColor,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mappa',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selectedColor,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
