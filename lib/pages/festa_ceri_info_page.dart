import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pagina informazioni storica sulla Festa dei Ceri
class FestaCeriInfoPage extends StatelessWidget {
  const FestaCeriInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fcLightBackground,
      appBar: AppBar(
        title: const Text('La Festa dei Ceri'),
        backgroundColor: AppTheme.fcWhite,
        foregroundColor: AppTheme.fcDeepRed,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine principale
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppTheme.fcDeepRed, AppTheme.fcBrightRed],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.celebration,
                  size: 80,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Introduzione
            _buildSection(
              title: 'Cos\'è la Festa dei Ceri?',
              content: 'La Festa dei Ceri è una delle manifestazioni folkloristiche '
                  'più antiche e spettacolari d\'Italia. Si svolge ogni anno a Gubbio '
                  'il 15 maggio, vigilia della festa di Sant\'Ubaldo, patrono della città.',
            ),
            
            const SizedBox(height: 24),
            
            // Origini
            _buildSection(
              title: 'Origini e Storia',
              content: 'La festa affonda le sue radici nel Medioevo, precisamente nel '
                  '1160, anno della morte del vescovo Ubaldo Baldassini. La tradizione '
                  'nasce come omaggio al santo che salvò la città dall\'assedio di '
                  'Federico Barbarossa.\n\n'
                  'Per oltre 860 anni, la festa si è tramandata di generazione in '
                  'generazione, mantenendo intatte le sue caratteristiche originali.',
            ),
            
            const SizedBox(height: 24),
            
            // I tre Ceri
            _buildSection(
              title: 'I Tre Ceri',
              content: 'I Ceri sono tre grandi strutture di legno ottagonali, alte '
                  'circa 4 metri e pesanti circa 280 kg ciascuno. Ogni Cero è dedicato '
                  'a un santo e rappresentato da un colore:',
            ),
            
            const SizedBox(height: 16),
            
            _buildCeroCard(
              color: AppTheme.fcYellow,
              title: 'Cero di Sant\'Ubaldo',
              subtitle: 'Giallo',
              description: 'Patrono di Gubbio, rappresenta i Muratori',
              icon: Icons.architecture,
            ),
            
            const SizedBox(height: 12),
            
            _buildCeroCard(
              color: AppTheme.fcBlue,
              title: 'Cero di San Giorgio',
              subtitle: 'Blu',
              description: 'Rappresenta i Commercianti',
              icon: Icons.store,
            ),
            
            const SizedBox(height: 12),
            
            _buildCeroCard(
              color: AppTheme.fcBlack,
              title: 'Cero di Sant\'Antonio',
              subtitle: 'Nero',
              description: 'Rappresenta i Contadini',
              icon: Icons.agriculture,
            ),
            
            const SizedBox(height: 24),
            
            // La Corsa
            _buildSection(
              title: 'La Corsa dei Ceri',
              content: 'Il momento culminante della festa è la corsa che si svolge nel '
                  'pomeriggio del 15 maggio. I tre Ceri vengono portati a spalla dai '
                  'ceraioli lungo un percorso di circa 4 km che attraversa le vie del '
                  'centro storico fino alla Basilica di Sant\'Ubaldo, sul Monte Ingino.\n\n'
                  'La corsa non è una competizione: l\'ordine di arrivo è sempre lo '
                  'stesso (Sant\'Ubaldo, San Giorgio, Sant\'Antonio) e rappresenta la '
                  'gerarchia corporativa medievale.',
            ),
            
            const SizedBox(height: 24),
            
            // I Ceraioli
            _buildSection(
              title: 'I Ceraioli',
              content: 'I ceraioli sono i protagonisti della festa. Vestiti con abiti '
                  'tradizionali del colore del proprio Cero, portano a spalla le pesanti '
                  'strutture in un\'impresa che richiede forza, coordinazione e profondo '
                  'senso di appartenenza.\n\n'
                  'Diventare ceraiolo è un grande onore e il ruolo si tramanda spesso '
                  'di padre in figlio.',
            ),
            
            const SizedBox(height: 24),
            
            // Significato
            _buildSection(
              title: 'Significato Culturale',
              content: 'La Festa dei Ceri non è solo una celebrazione religiosa, ma '
                  'rappresenta l\'identità stessa della città di Gubbio. È un momento '
                  'di coesione sociale, dove tutta la comunità si riunisce per '
                  'rinnovare un legame che attraversa i secoli.\n\n'
                  'Nel 2013 la festa è stata riconosciuta dall\'UNESCO come Patrimonio '
                  'Culturale Immateriale dell\'Umanità.',
            ),
            
            const SizedBox(height: 24),
            
            // Date importanti
            _buildSection(
              title: 'Il Programma',
              content: '15 Maggio - Giorno principale\n'
                  '• Mattina: Alzata dei Ceri in Piazza Grande\n'
                  '• Pomeriggio: La Corsa verso Monte Ingino\n'
                  '• Sera: Celebrazioni e festeggiamenti\n\n'
                  'La festa è preceduta da eventi preparatori nei giorni precedenti.',
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.fcDeepRed,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: AppTheme.fcBlack,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCeroCard({
    required Color color,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.fcBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
