import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import 'map_page.dart';

/// Pagina dettaglio evento con informazioni complete
class EventDetailPage extends StatelessWidget {
  final EventModel event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          const PremiumHeader(title: 'Evento'),
          Expanded(
            child: SingleChildScrollView(
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
                            color: AppColors.bluNotte,
                            height: 1.25,
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
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Immagine evento (segnaposto)
  Widget _buildEventImage() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.tortora.withOpacity(0.4),
            AppColors.avorio,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.festival_outlined,
              size: 72,
              color: AppColors.rossoGubbio.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Festa dei Ceri',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sezione orario
  Widget _buildTimeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.rossoGubbio.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: AppColors.rossoGubbio,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            event.time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.rossoGubbio,
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
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
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
            color: AppColors.textMuted,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  /// Sezione informazioni storiche
  Widget _buildHistoricalSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.rossoGubbio.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.rossoGubbio,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Contesto Storico',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluNotte,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getHistoricalContext(event.id),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textMuted,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.rossoGubbio.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.rossoGubbio.withOpacity(0.18),
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
                  color: AppColors.rossoGubbio.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.rossoGubbio,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lo sapevi che...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluNotte,
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
                        color: AppColors.rossoGubbio,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        curiosity,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textMuted,
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
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.bluNotte.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.rossoGubbio,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.location,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.bluNotte,
                        fontWeight: FontWeight.w600,
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MapPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 20),
                  label: const Text('Vedi sulla mappa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rossoGubbio,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
}
