import 'package:flutter/material.dart';

/// Drawer menu laterale moderno stile Google Maps
/// Occupa circa metà schermo con animazione fluida
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.5,
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header drawer con X per chiudere
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.explore,
                      size: 32,
                      color: const Color(0xFF9C7355),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Visit Gubbio',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                    // Bottone X per chiudere
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[700],
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              // Voci menu
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.restaurant,
                      title: 'Ristoranti',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigare a pagina ristoranti
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.local_bar,
                      title: 'Bar',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigare a pagina bar
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.hotel,
                      title: 'Hotel',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigare a pagina hotel
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.history_edu,
                      title: 'Storia di Gubbio',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigare a pagina storia
                      },
                    ),
                    const Divider(height: 32, thickness: 1),
                    _buildMenuItem(
                      context,
                      icon: Icons.local_fire_department,
                      title: 'Festa dei Ceri',
                      titleColor: Colors.red,
                      iconColor: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigare a modalità Festa dei Ceri
                      },
                    ),
                  ],
                ),
              ),

              // Versione app in fondo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Versione 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.grey[700],
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: titleColor ?? Colors.grey[900],
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: Colors.grey[100],
    );
  }
}
