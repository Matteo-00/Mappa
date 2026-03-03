import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/muta_model.dart';
import '../data/mute_data.dart';
import 'mute_form_page.dart';

/// Pagina lista mute - visibile solo ai Ceraioli
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
      appBar: AppBar(
        title: const Text('Mute'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuova Muta',
            onPressed: () => _navigateToCreateMuta(),
          ),
        ],
      ),
      body: muteData.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: muteData.length,
              itemBuilder: (context, index) {
                final muta = muteData[index];
                return _buildMutaCard(muta);
              },
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nessuna muta presente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea la prima muta',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToCreateMuta(),
            icon: const Icon(Icons.add),
            label: const Text('Nuova Muta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                      color: const Color(0xFFB71C1C).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Color(0xFFB71C1C),
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
                            color: Color(0xFFB71C1C),
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
                        foregroundColor: const Color(0xFFB71C1C),
                        side: const BorderSide(color: Color(0xFFB71C1C)),
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
}
