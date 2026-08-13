import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';

/// Pagina Storia di Gubbio - stile premium magazine
class StoriaPage extends StatelessWidget {
  const StoriaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          const PremiumHeader(title: 'Storia di Gubbio'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                // Hero card
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.bluNotte,
                        AppColors.bluNotte.withOpacity(0.75),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bluNotte.withOpacity(0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -10,
                        top: -10,
                        child: Icon(
                          Icons.castle,
                          size: 150,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.castle,
                                color: AppColors.tortora, size: 34),
                            const SizedBox(height: 12),
                            const Text(
                              'La Città dei Ceri',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Un viaggio nella storia millenaria',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Gubbio è una delle città medievali meglio conservate d\'Italia, situata sulle pendici del Monte Ingino in Umbria. La sua storia millenaria si intreccia con la leggenda e la tradizione, rendendola una meta imperdibile per chi ama l\'arte, la cultura e le antiche tradizioni italiane.',
                  style: TextStyle(
                    fontSize: 15.5,
                    color: AppColors.bluNotte,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 24),

                _buildSection(
                  title: 'Origini Antiche',
                  content:
                      'Le origini di Gubbio risalgono all\'epoca umbra, quando era conosciuta come Ikuvium. La città divenne poi un importante centro romano con il nome di Iguvium. Le famose Tavole Eugubine, sette tavole di bronzo che documentano le lingue umbra e latina, testimoniano l\'importanza religiosa e culturale della città in epoca romana.',
                  icon: Icons.history_edu,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Il Medioevo d\'Oro',
                  content:
                      'Durante il Medioevo, Gubbio raggiunse il suo massimo splendore. Il Palazzo dei Consoli, costruito nel XIV secolo, è uno dei più impressionanti palazzi comunali d\'Italia. La città si arricchì di chiese, torri e palazzi nobiliari che ancora oggi caratterizzano il suo profilo urbanistico.',
                  icon: Icons.church,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'San Francesco e il Lupo',
                  content:
                      'Gubbio è famosa anche per la leggenda di San Francesco e il lupo. Secondo la tradizione, San Francesco ammansì un lupo feroce che terrorizzava la città, facendo patto con l\'animale davanti alla popolazione. Questa storia è diventata uno dei racconti più celebri legati al santo di Assisi.',
                  icon: Icons.pets,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'La Festa dei Ceri',
                  content:
                      'La manifestazione più importante di Gubbio è la Festa dei Ceri, che si svolge ogni anno il 15 maggio. Questa corsa spettacolare con enormi strutture di legno dedicate ai santi patroni della città (Sant\'Ubaldo, San Giorgio e Sant\'Antonio) è una delle feste più antiche e sentite d\'Italia, patrimonio immateriale dell\'umanità.',
                  icon: Icons.local_fire_department,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.tortora.withOpacity(0.45),
                  AppColors.avorio,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: AppColors.rossoGubbio),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bluNotte,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.55,
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
