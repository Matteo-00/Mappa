import 'package:flutter/material.dart';
import '../widgets/custom_header.dart';

/// Pagina Bar - Mostra lista bar a Gubbio
class BarsPage extends StatelessWidget {
  const BarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomHeader(),
      body: Column(
        children: [
          // Titolo pagina
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bar',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'I migliori bar di Gubbio',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Lista bar
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBarCard(
                  context,
                  name: 'Caffè del Centro',
                  address: 'Piazza Grande, Gubbio',
                  description: 'Bar storico nel cuore di Gubbio. Ottimo caffè e pasticceria artigianale.',
                  rating: 4.6,
                  imageIcon: Icons.local_cafe,
                ),
                const SizedBox(height: 16),
                _buildBarCard(
                  context,
                  name: 'Bar San Francesco',
                  address: 'Via Cairoli, 15, Gubbio',
                  description: 'Bar moderno con terrazza panoramica. Aperitivi e cocktail.',
                  rating: 4.4,
                  imageIcon: Icons.local_bar,
                ),
                const SizedBox(height: 16),
                _buildBarCard(
                  context,
                  name: 'Caffetteria dei Ceri',
                  address: 'Corso Garibaldi, 32, Gubbio',
                  description: 'Caffetteria tradizionale con specialità locali. Ambiente familiare.',
                  rating: 4.5,
                  imageIcon: Icons.coffee,
                ),
              ],
            ),
          ),

          // Footer con Home
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildBarCard(
    BuildContext context, {
    required String name,
    required String address,
    required String description,
    required double rating,
    required IconData imageIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Immagine placeholder
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF9C7355).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Icon(
              imageIcon,
              size: 64,
              color: const Color(0xFF9C7355),
            ),
          ),

          // Contenuto
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome e rating
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Indirizzo
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Descrizione
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 12),

                // Azioni
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Mostra $name sulla mappa'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: const Color(0xFF9C7355),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.map,
                        size: 18,
                      ),
                      label: const Text('Mappa'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF9C7355),
                      ),
                    ),
                  ],
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
