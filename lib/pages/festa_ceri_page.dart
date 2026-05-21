import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';

/// Pagina Festa dei Ceri - Programma e informazioni
class FestaCeriPage extends StatelessWidget {
  const FestaCeriPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomHeader(),
      body: Column(
        children: [
          // Header rosso con info festa
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade700,
                  Colors.red.shade500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        Icons.local_fire_department,
                        size: 48,
                        color: Colors.white,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Festa dei Ceri',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '15 Maggio - Gubbio',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La corsa più antica e spettacolare d\'Italia',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab selector
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTab('Programma', true),
                _buildTab('Storia', false),
              ],
            ),
          ),

          // Contenuto scrollabile - Programma
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Intro
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'La Festa dei Ceri si svolge ogni anno il 15 maggio',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Timeline eventi
                _buildTimelineItem(
                  time: '05:30',
                  title: 'Sveglia dei Ceraioli',
                  description: 'I ceraioli si svegliano e iniziano i preparativi per la giornata',
                  icon: Icons.wb_sunny_outlined,
                  isFirst: true,
                ),

                _buildTimelineItem(
                  time: '06:00',
                  title: 'Colazione del Capitano',
                  description: 'Colazione tradizionale presso la casa del Capitano',
                  icon: Icons.restaurant,
                ),

                _buildTimelineItem(
                  time: '11:30',
                  title: 'Alzata dei Ceri',
                  description: 'I tre Ceri vengono innalzati in Piazza Grande',
                  icon: Icons.arrow_upward,
                  highlight: true,
                ),

                _buildTimelineItem(
                  time: '12:00',
                  title: 'Prima Corsa',
                  description: 'I Ceri percorrono le vie del centro storico',
                  icon: Icons.directions_run,
                ),

                _buildTimelineItem(
                  time: '18:00',
                  title: 'Corsa Grande',
                  description: 'La spettacolare corsa finale dalla Piazza al Monte Ingino',
                  icon: Icons.local_fire_department,
                  highlight: true,
                ),

                _buildTimelineItem(
                  time: '19:30',
                  title: 'Arrivo alla Basilica',
                  description: 'I Ceri raggiungono la Basilica di Sant\'Ubaldo',
                  icon: Icons.church,
                  isLast: true,
                ),

                const SizedBox(height: 24),

                // I tre Ceri
                const Text(
                  'I Tre Ceri',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 16),

                _buildCeroCard(
                  name: 'Cero di Sant\'Ubaldo',
                  patron: 'Patrono di Gubbio',
                  color: Colors.yellow.shade700,
                  category: 'Muratori',
                ),

                const SizedBox(height: 12),

                _buildCeroCard(
                  name: 'Cero di San Giorgio',
                  patron: 'Protettore dei Commercianti',
                  color: Colors.blue.shade700,
                  category: 'Commercianti',
                ),

                const SizedBox(height: 12),

                _buildCeroCard(
                  name: 'Cero di Sant\'Antonio',
                  patron: 'Protettore dei Contadini',
                  color: Colors.black87,
                  category: 'Studenti e Contadini',
                ),
              ],
            ),
          ),

          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.red : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.red : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required String title,
    required String description,
    required IconData icon,
    bool isFirst = false,
    bool isLast = false,
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        SizedBox(
          width: 80,
          child: Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 20,
                  color: Colors.red.withOpacity(0.3),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: highlight ? Colors.red : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: highlight ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.red.withOpacity(0.3),
                ),
            ],
          ),
        ),

        // Contenuto
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16, left: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: highlight ? Colors.red.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlight
                    ? Colors.red.withOpacity(0.3)
                    : Colors.grey[200]!,
                width: highlight ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: highlight
                        ? Colors.red.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: highlight ? Colors.red : Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: highlight ? Colors.red.shade700 : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCeroCard({
    required String name,
    required String patron,
    required Color color,
    required String category,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  patron,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home,
                        color: Colors.grey[800],
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
