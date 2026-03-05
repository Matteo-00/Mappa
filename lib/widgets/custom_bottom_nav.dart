import 'package:flutter/material.dart';

/// Footer fisso con navigation bar personalizzata
/// Altezza: 70px
/// Icone: Home | Dove sono | Programma | Mute (solo ceraioli)
class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final bool showMute; // Mostra l'icona Mute solo se ceraiolo

  const CustomBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.showMute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          top: BorderSide(
            color: Color(0xFFEAEAEA), // Separatore grigio
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_rounded,
            label: 'Home',
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.location_on_rounded,
            label: 'Dove sono',
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.calendar_today_rounded,
            label: 'Programma',
            isSelected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          // Mute - solo se ceraiolo
          if (showMute)
            _buildNavItem(
              index: 3,
              icon: Icons.groups_rounded,
              label: 'Mute',
              isSelected: selectedIndex == 3,
              onTap: () => onTap(3),
            ),
        ],
      ),
    );
  }

  /// Crea un singolo item della navigazione
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected
        ? const Color(0xFF2F80ED) // Blu quando selezionato
        : const Color(0xFF6B6B6B); // Grigio quando non selezionato

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF2F80ED).withOpacity(0.1),
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
}
