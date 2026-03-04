import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

/// Schermata profilo utente che mostra tutte le informazioni di registrazione
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profilo'),
        ),
        body: const Center(
          child: Text('Nessun utente autenticato'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profilo Utente'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icona
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC00000).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: Color(0xFFC00000),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.nomeCompleto,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.isCeraiolo ? 'Ceraiolo' : 'Turista',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Card informazioni personali
            _buildInfoCard(
              title: 'Informazioni Personali',
              items: [
                _InfoItem(
                  icon: Icons.badge,
                  label: 'Nome',
                  value: user.nome,
                ),
                _InfoItem(
                  icon: Icons.badge_outlined,
                  label: 'Cognome',
                  value: user.cognome,
                ),
                _InfoItem(
                  icon: Icons.cake,
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
                    icon: Icons.local_fire_department,
                    label: 'Cero',
                    value: user.cero!,
                  ),
              ],
            ),

            const SizedBox(height: 32),

            // Pulsante modifica (placeholder)
            // SizedBox(
            //   width: double.infinity,
            //   child: OutlinedButton.icon(
            //     onPressed: () {
            //       // TODO: Implementare modifica profilo
            //       ScaffoldMessenger.of(context).showSnackBar(
            //         const SnackBar(
            //           content: Text('Funzionalità in arrivo'),
            //         ),
            //       );
            //     },
            //     icon: const Icon(Icons.edit),
            //     label: const Text('Modifica'),
            //     style: OutlinedButton.styleFrom(
            //       foregroundColor: const Color(0xFFC00000),
            //       side: const BorderSide(color: Color(0xFFC00000)),
            //       padding: const EdgeInsets.symmetric(vertical: 16),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<_InfoItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => _buildInfoRow(item)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            item.icon,
            size: 20,
            color: const Color(0xFFC00000),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
