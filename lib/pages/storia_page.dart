import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';

/// Pagina Storia di Gubbio - Magazine style
class StoriaPage extends StatelessWidget {
  const StoriaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomHeader(),
      body: Column(
        children: [
          // Header con immagine
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF9C7355).withOpacity(0.2),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Stack(
              children: [
                // Placeholder immagine
                Center(
                  child: Icon(
                    Icons.castle,
                    size: 80,
                    color: const Color(0xFF9C7355).withOpacity(0.6),
                  ),
                ),
                // Titolo sovrapposto
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: const Text(
                    'Storia di Gubbio',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      shadows: [
                        Shadow(
                          color: Colors.white,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenuto scrollabile
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Introduzione
                const Text(
                  'La Città dei Ceri',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Gubbio è una delle città medievali meglio conservate d\'Italia, situata sulle pendici del Monte Ingino in Umbria. La sua storia millenaria si intreccia con la leggenda e la tradizione, rendendola una meta imperdibile per chi ama l\'arte, la cultura e le antiche tradizioni italiane.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 32),

                // Sezione Origini
                _buildSection(
                  title: 'Origini Antiche',
                  content: 'Le origini di Gubbio risalgono all\'epoca umbra, quando era conosciuta come Ikuvium. La città divenne poi un importante centro romano con il nome di Iguvium. Le famose Tavole Eugubine, sette tavole di bronzo che documentano le lingue umbra e latina, testimoniano l\'importanza religiosa e culturale della città in epoca romana.',
                  icon: Icons.history_edu,
                ),

                const SizedBox(height: 24),

                // Sezione Medioevo
                _buildSection(
                  title: 'Il Medioevo d\'Oro',
                  content: 'Durante il Medioevo, Gubbio raggiunse il suo massimo splendore. Il Palazzo dei Consoli, costruito nel XIV secolo, è uno dei più impressionanti palazzi comunali d\'Italia. La città si arricchì di chiese, torri e palazzi nobiliari che ancora oggi caratterizzano il suo profilo urbanistico.',
                  icon: Icons.church,
                ),

                const SizedBox(height: 24),

                // Sezione San Francesco
                _buildSection(
                  title: 'San Francesco e il Lupo',
                  content: 'Gubbio è famosa anche per la leggenda di San Francesco e il lupo. Secondo la tradizione, San Francesco ammansì un lupo feroce che terrorizzava la città, facendo patto con l\'animale davanti alla popolazione. Questa storia è diventata uno dei racconti più celebri legati al santo di Assisi.',
                  icon: Icons.pets,
                ),

                const SizedBox(height: 24),

                // Sezione Festa dei Ceri
                _buildSection(
                  title: 'La Festa dei Ceri',
                  content: 'La manifestazione più importante di Gubbio è la Festa dei Ceri, che si svolge ogni anno il 15 maggio. Questa corsa spettacolare con enormi strutture di legno dedicate ai santi patroni della città (Sant\'Ubaldo, San Giorgio e Sant\'Antonio) è una delle feste più antiche e sentite d\'Italia, patrimonio immateriale dell\'umanità.',
                  icon: Icons.local_fire_department,
                  iconColor: Colors.red,
                ),

                const SizedBox(height: 32),

                // Call to action
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C7355).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF9C7355).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.explore,
                        size: 48,
                        color: Color(0xFF9C7355),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Scopri di più',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Visita i luoghi storici sulla mappa interattiva',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
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

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFF9C7355)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 28,
            color: iconColor ?? const Color(0xFF9C7355),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
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
