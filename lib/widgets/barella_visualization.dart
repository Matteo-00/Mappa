import 'package:flutter/material.dart';
import '../models/barella_model.dart';

/// Widget per visualizzare la barella con l'immagine e gli 11 ceraioli posizionati
class BarellaVisualization extends StatelessWidget {
  final BarellaCeraioli barella;

  const BarellaVisualization({
    super.key,
    required this.barella,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Composizione Barella',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Barella con ceraioli
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'Vista dall\'alto della Barella',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Barella con posizioni
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Immagine barella
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'barella.png',
                            width: 400,
                            height: 400,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 400,
                                height: 400,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Immagine barella non trovata',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Aggiungi barella.png nella root',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Posizionamento Ceraioli
                        SizedBox(
                          width: 500,
                          height: 500,
                          child: Stack(
                            children: [
                              // STANGA SINISTRA (sinistra dell'immagine)
                              // Punta Avanti SX (in alto a sinistra)
                              Positioned(
                                left: 0,
                                top: 80,
                                child: _buildCeraioloCard(
                                  barella.stangaSinistraPuntaAvanti,
                                  Alignment.centerRight,
                                ),
                              ),
                              // Ceppo Avanti SX
                              Positioned(
                                left: 0,
                                top: 160,
                                child: _buildCeraioloCard(
                                  barella.stangaSinistraCeppoAvanti,
                                  Alignment.centerRight,
                                ),
                              ),
                              // Ceppo Dietro SX
                              Positioned(
                                left: 0,
                                top: 260,
                                child: _buildCeraioloCard(
                                  barella.stangaSinistraCeppoDietro,
                                  Alignment.centerRight,
                                ),
                              ),
                              // Punta Dietro SX (in basso a sinistra)
                              Positioned(
                                left: 0,
                                top: 340,
                                child: _buildCeraioloCard(
                                  barella.stangaSinistraPuntaDietro,
                                  Alignment.centerRight,
                                ),
                              ),

                              // STANGA DESTRA (destra dell'immagine)
                              // Punta Avanti DX (in alto a destra)
                              Positioned(
                                right: 0,
                                top: 80,
                                child: _buildCeraioloCard(
                                  barella.stangaDestraPuntaAvanti,
                                  Alignment.centerLeft,
                                ),
                              ),
                              // Ceppo Avanti DX
                              Positioned(
                                right: 0,
                                top: 160,
                                child: _buildCeraioloCard(
                                  barella.stangaDestraCeppoAvanti,
                                  Alignment.centerLeft,
                                ),
                              ),
                              // Ceppo Dietro DX
                              Positioned(
                                right: 0,
                                top: 260,
                                child: _buildCeraioloCard(
                                  barella.stangaDestraCeppoDietro,
                                  Alignment.centerLeft,
                                ),
                              ),
                              // Punta Dietro DX (in basso a destra)
                              Positioned(
                                right: 0,
                                top: 340,
                                child: _buildCeraioloCard(
                                  barella.stangaDestraPuntaDietro,
                                  Alignment.centerLeft,
                                ),
                              ),

                              // CENTRO (sopra e sotto l'immagine)
                              // Capo 10 (in alto al centro)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _buildCeraioloCard(
                                    barella.centroCapo10,
                                    Alignment.center,
                                  ),
                                ),
                              ),
                              // Capo 5 (centro)
                              Positioned(
                                top: 220,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _buildCeraioloCard(
                                    barella.centroCapo5,
                                    Alignment.center,
                                  ),
                                ),
                              ),
                              // Barelone (in basso al centro)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: _buildCeraioloCard(
                                    barella.centroBarelone,
                                    Alignment.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Legenda
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Struttura Ufficiale',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '11 Ceraioli: 4 Stanga Sinistra, 4 Stanga Destra, 3 Centro',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCeraioloCard(CeraioloInfo ceraiolo, Alignment alignment) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ceraiolo.ruolo,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            ceraiolo.nomeCompleto,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
