import 'package:flutter/material.dart';
import '../pages/user_profile_page.dart';
import '../pages/login_page.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

/// Header fisso personalizzato elegante per l'app "15 Maggio"
/// Altezza: 60px
/// Sinistra: Icona casa + "15 Maggio"
/// Destra: Avatar utente con menu dropdown
class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  const CustomHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF), // Bianco
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEAEAEA), // Separatore grigio chiaro
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sinistra: Icona + Testo
          Row(
            children: [
              // Icona casa stilizzata rossa
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFB22222),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              // Testo "15 Maggio"
              const Text(
                '15 Maggio',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB22222), // Rosso principale
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          // Destra: Avatar utente con menu
          _buildUserMenu(context),
        ],
      ),
    );
  }

  /// Menu utente con avatar circolare
  Widget _buildUserMenu(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF424242).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          color: Color(0xFF424242),
          size: 22,
        ),
      ),
      onSelected: (value) {
        if (value == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const UserProfilePage(),
            ),
          );
        } else if (value == 'logout') {
          _handleLogout(context);
        }
      },
      color: const Color(0xFFF5F5F5),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: Color(0xFF424242),
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Utente',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.logout,
                  color: Color(0xFF424242),
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Gestisce il logout
  void _handleLogout(BuildContext context) async {
    final authService = context.read<AuthService>();
    await authService.logout();
    
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
