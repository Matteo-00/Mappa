import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../pages/user_profile_page.dart';

/// Header moderno stile Google Maps
/// Semi-trasparente con blur effect
/// Hamburger menu a sinistra, avatar utente a destra, "Visit Gubbio" centrato
class ModernHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuTap;
  final String? userInitials;

  const ModernHeader({
    super.key,
    required this.onMenuTap,
    this.userInitials,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // App name centrato
                  Center(
                    child: Text(
                      'Visit Gubbio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  
                  // Hamburger e Avatar ai lati
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hamburger menu button
                      _buildMenuButton(),
                      
                      // User avatar button con dropdown
                      _buildAvatarButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onMenuTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.menu,
            size: 24,
            color: Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarButton(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        switch (value) {
          case 'profilo':
            // Naviga al profilo utente
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const UserProfilePage(),
              ),
            );
            break;
          case 'lingua':
            // Mostra dialog per cambiare lingua
            _showLanguageDialog(context);
            break;
          case 'esci':
            // Logout
            final authService = context.read<AuthService>();
            authService.logout();
            Navigator.of(context).pushReplacementNamed('/');
            break;
        }
      },
      offset: const Offset(0, 50),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'profilo',
          child: Row(
            children: const [
              Icon(Icons.person_outline, size: 20, color: Colors.black87),
              SizedBox(width: 12),
              Text('Profilo'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'lingua',
          child: Row(
            children: const [
              Icon(Icons.language, size: 20, color: Colors.black87),
              SizedBox(width: 12),
              Text('Lingua'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'esci',
          child: Row(
            children: const [
              Icon(Icons.logout, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Esci', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey[800]!.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            userInitials ?? 'U',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final langService = context.read<LanguageService>();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleziona Lingua'),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                context,
                '🇮🇹',
                'Italiano',
                'it',
                langService.currentLanguageCode == 'it',
                () {
                  langService.setLanguage('it');
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 12),
              _buildLanguageOption(
                context,
                '🇬🇧',
                'English',
                'en',
                langService.currentLanguageCode == 'en',
                () {
                  langService.setLanguage('en');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String flagEmoji,
    String languageName,
    String code,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9C7355).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF9C7355) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flagEmoji,
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                languageName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF9C7355) : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF9C7355),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
