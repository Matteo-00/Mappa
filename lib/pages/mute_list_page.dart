import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/muta_model.dart';
import '../data/mute_data.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_bottom_nav.dart';
import 'mute_form_page.dart';

/// Pagina lista mute - visibile solo ai Ceraioli
/// Header e footer sempre visibili
class MuteListPage extends StatefulWidget {
  final Function(LatLng, double, MutaModel)? onNavigateToMuta;

  const MuteListPage({
    super.key,
    this.onNavigateToMuta,
  });

  @override
  State<MuteListPage> createState() => _MuteListPageState();
}

class _MuteListPageState extends State<MuteListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: const CustomHeader(),
      body: Column(
        children: [
          // Titolo e pulsante aggiungi
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mute',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB22222),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded),
                  iconSize: 32,
                  color: const Color(0xFF2F80ED),
                  tooltip: 'Nuova Muta',
                  onPressed: () => _navigateToCreateMuta(),
                ),
              ],
            ),
          ),
          // Lista mute
          Expanded(
            child: muteData.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: muteData.length,
                    itemBuilder: (context, index) {
                      final muta = muteData[index];
                      return _buildMutaCard(muta);
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: 3, // Mute selezionato
        onTap: (index) => _handleNavigation(context, index),
        showMute: true,
        onLocationMenuTap: () {}, // Non utilizzato in questa pagina
        isLocationMenuOpen: false,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: const Color(0xFF2F80ED).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nessuna muta presente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B6B6B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea la prima muta',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateMuta(),
            icon: const Icon(Icons.add),
            label: const Text('Nuova Muta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F80ED), // Blu invece di rosso
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutaCard(MutaModel muta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToEditMuta(muta),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F80ED).withOpacity(0.1), // Blu
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Color(0xFF2F80ED), // Blu
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          muta.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Nero invece di rosso
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Capo Muta: ${muta.capoMuta}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    muta.zone,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _goToMapLocation(muta),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Vai sulla mappa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2F80ED), // Blu
                        side: const BorderSide(color: Color(0xFF2F80ED)), // Blu
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    color: Colors.grey[700],
                    tooltip: 'Modifica',
                    onPressed: () => _navigateToEditMuta(muta),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToMapLocation(MutaModel muta) {
    if (widget.onNavigateToMuta != null) {
      // Naviga alla mappa e centra sulla muta con zoom 18
      widget.onNavigateToMuta!(muta.coordinates, 18.0, muta);
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funzione non disponibile'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _navigateToCreateMuta() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MuteFormPage(),
      ),
    ).then((_) {
      // Ricarica la lista dopo la creazione
      setState(() {});
    });
  }

  void _navigateToEditMuta(MutaModel muta) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MuteFormPage(muta: muta),
      ),
    ).then((_) {
      // Ricarica la lista dopo la modifica
      setState(() {});
    });
  }

  /// Gestisce la navigazione dal footer
  void _handleNavigation(BuildContext context, int index) {
    if (index == 0 || index == 1 || index == 2) {
      // Home, Dove sono, Programma - torna alla home
      Navigator.of(context).pop();
    }
    // index 3 è Mute, già qui
  }
}
