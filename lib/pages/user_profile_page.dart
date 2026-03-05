import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_bottom_nav.dart';

/// Schermata profilo utente che mostra tutte le informazioni di registrazione
/// Header e footer sempre visibili
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: const CustomHeader(),
        body: const Center(
          child: Text('Nessun utente autenticato'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: const CustomHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titolo pagina
            const Text(
              'Profilo Utente',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB22222),
              ),
            ),
            const SizedBox(height: 24),

            // Header con icona
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB22222).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Color(0xFFB22222),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user.nomeCompleto,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: user.isCeraiolo
                          ? const Color(0xFFB22222)
                          : const Color(0xFF2F80ED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.isCeraiolo ? 'Ceraiolo' : 'Turista',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Card informazioni personali
            _buildInfoCard(
              title: 'Informazioni Personali',
              items: [
                _InfoItem(
                  icon: Icons.badge_outlined,
                  label: 'Nome',
                  value: user.nome,
                ),
                _InfoItem(
                  icon: Icons.badge_outlined,
                  label: 'Cognome',
                  value: user.cognome,
                ),
                _InfoItem(
                  icon: Icons.cake_outlined,
                  label: 'Età',
                  value: '${user.eta} anni',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Card informazioni ceraiolo
            _buildInfoCard(
              title: 'Dettagli Ceri',
              items: [
                _InfoItem(
                  icon: Icons.person_outline,
                  label: 'Ceraiolo',
                  value: user.isCeraiolo ? 'Sì' : 'No',
                ),
                if (user.isCeraiolo && user.cero != null)
                  _InfoItem(
                    icon: Icons.festival_rounded,
                    label: 'Cero scelto',
                    value: user.cero!,
                  ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: -1, // Nessuna tab selezionata (profilo aperto da menu)
        onTap: (index) => _handleNavigation(context, index, user.isCeraiolo),
        showMute: user.isCeraiolo,
      ),
    );
  }

  /// Gestisce la navigazione dal footer
  void _handleNavigation(BuildContext context, int index, bool isCeraiolo) {
    // Chiude il profilo e torna alla home
    Navigator.of(context).pop();
    // La navigazione verrà gestita dalla HomePage
  }

  Widget _buildInfoCard({
    required String title,
    required List<_InfoItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAEAEA)),
          ...items.map((item) => _buildInfoRow(item)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFB22222).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: const Color(0xFFB22222),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
