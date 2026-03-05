import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../widgets/custom_header.dart';
import '../widgets/custom_bottom_nav.dart';

/// Pagina dettaglio evento con informazioni complete
/// Header e footer sempre visibili
class EventDetailPage extends StatelessWidget {
  final EventModel event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: const CustomHeader(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine grande in alto
            _buildEventImage(),
            
            // Contenuto dettagli
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Orario con icona
                  _buildTimeSection(),
                  const SizedBox(height: 16),
                  
                  // Titolo evento
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Descrizione completa
                  _buildDescriptionSection(),
                  const SizedBox(height: 24),
                  
                  // Informazioni storiche
                  _buildHistoricalSection(),
                  const SizedBox(height: 24),
                  
                  // Curiosità (se disponibili)
                  _buildCuriositySection(),
                  const SizedBox(height: 24),
                  
                  // Luogo
                  _buildLocationSection(context),
                  const SizedBox(height: 80), // Spazio per il footer
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: 2, // Programma selezionato
        onTap: (index) => _handleNavigation(context, index),
        showMute: false, // Da gestire dinamicamente se necessario
      ),
    );
  }

  /// Immagine evento (segnaposto)
  Widget _buildEventImage() {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFEAEAEA),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Segnaposto immagine
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.festival_rounded,
                  size: 80,
                  color: const Color(0xFF2F80ED).withOpacity(0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'Festa dei Ceri',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF6B6B6B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Sezione orario
  Widget _buildTimeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2F80ED).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: Color(0xFF2F80ED),
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            event.time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F80ED),
            ),
          ),
        ],
      ),
    );
  }

  /// Sezione descrizione
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descrizione',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          event.description.isNotEmpty
              ? event.description
              : 'Uno degli eventi più importanti della Festa dei Ceri di Gubbio, '
                  'una tradizione che si tramanda da secoli e che rappresenta '
                  'il cuore pulsante della città.',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF6B6B6B),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  /// Sezione informazioni storiche
  Widget _buildHistoricalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80ED).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF2F80ED),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Contesto Storico',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getHistoricalContext(event.id),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B6B6B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Sezione curiosità
  Widget _buildCuriositySection() {
    final curiosities = _getCuriosities(event.id);
    if (curiosities.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFB22222).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFB22222).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB22222).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFB22222),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lo sapevi che...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...curiosities.map((curiosity) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFFB22222),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        curiosity,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B6B6B),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  /// Sezione posizione
  Widget _buildLocationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Posizione',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEAEAEA),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF2F80ED),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.location,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Torna alla home e centra sulla mappa
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    // TODO: Centra mappa su event.coordinates
                  },
                  icon: const Icon(Icons.map_rounded, size: 20),
                  label: const Text('Vedi sulla mappa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F80ED),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Restituisce il contesto storico per un evento
  String _getHistoricalContext(String eventId) {
    final contexts = {
      'evt_1': 'La tradizione dei tamburi che svegliano i Capitani risale al Medioevo, '
          'quando era necessario radunare i ceraioli prima dell\'alba per prepararsi alla lunga giornata di celebrazioni.',
      'evt_2': 'Il Campanone del Palazzo dei Consoli, con il suo suono inconfondibile, '
          'risuona per tutta Gubbio annunciando ufficialmente l\'inizio della Festa dei Ceri.',
      'evt_4': 'La Messa dei Ceraioli nel Duomo è un momento di raccoglimento e spiritualità '
          'che precede l\'energica celebrazione della giornata.',
      'evt_6': 'L\'Alzata dei Ceri è il momento culminante della mattinata: i tre Ceri, '
          'alti 4 metri e pesanti circa 280 kg ciascuno, vengono issati sulle spalle dei ceraioli '
          'tra il boato della folla in Piazza Grande.',
      'evt_8': 'La Corsa dei Ceri è il momento più atteso: una sfida secolare dove i tre Ceri '
          'vengono portati di corsa dal centro storico fino alla Basilica di Sant\'Ubaldo sul Monte Ingino. '
          'Non è una gara di velocità, ma un atto di devozione e orgoglio.',
    };
    return contexts[eventId] ?? 
        'Un evento importante della tradizione eugubina che si tramanda di generazione in generazione.';
  }

  /// Restituisce curiosità per un evento
  List<String> _getCuriosities(String eventId) {
    final curiositiesMap = {
      'evt_6': [
        'Ogni Cero pesa circa 280 kg ed è alto oltre 4 metri',
        'I tre Ceri rappresentano i Santi Ubaldo, Giorgio e Antonio',
        'L\'ordine dei Ceri non cambia mai: Sant\'Ubaldo arriva sempre per primo',
      ],
      'evt_8': [
        'La corsa dura circa 30 minuti',
        'I ceraioli percorrono oltre 4 km in salita',
        'La festa ha origini medievali e risale al XII secolo',
      ],
    };
    return curiositiesMap[eventId] ?? [];
  }

  /// Gestisce la navigazione dal footer
  void _handleNavigation(BuildContext context, int index) {
    if (index == 0) {
      // Home - torna alla home
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 2) {
      // Programma - torna alla pagina programma
      Navigator.of(context).pop();
    }
    // Altri index gestiti dalla pagina chiamante
  }
}
