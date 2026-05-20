import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';

/// Menu espandibile del pulsante centrale del footer
/// Mostra 2 pulsanti rotondi sopra il pulsante principale
class LocationMenu extends StatelessWidget {
  final VoidCallback onGubbioMapsTap;
  final VoidCallback onWhereAmITap;
  
  const LocationMenu({
    super.key,
    required this.onGubbioMapsTap,
    required this.onWhereAmITap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final mode = themeProvider.currentMode;
        final accentColor = AppTheme.getFooterSelected(mode);
        
        return Positioned(
          bottom: 90, // Sopra il footer
          left: 0,
          right: 0,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLocationMenuItem(
                    icon: themeProvider.isVisitGubbio 
                        ? Icons.map_rounded 
                        : Icons.route_rounded,
                    label: themeProvider.isVisitGubbio 
                        ? 'GubbioMaps' 
                        : 'Mappa Percorso',
                    onTap: onGubbioMapsTap,
                    accentColor: accentColor,
                  ),
                  const SizedBox(width: 20),
                  _buildLocationMenuItem(
                    icon: Icons.my_location_rounded,
                    label: 'Dove sono',
                    onTap: onWhereAmITap,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// Singolo pulsante rotondo del menu
  Widget _buildLocationMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pulsante circolare
        Material(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: const CircleBorder(),
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Label sotto il pulsante
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ),
      ],
    );
  }
}
