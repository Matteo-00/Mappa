import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant_model.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import 'map_page.dart';

/// Pagina dettaglio ristorante
class RestaurantDetailPage extends StatelessWidget {
  final RestaurantModel restaurant;
  
  const RestaurantDetailPage({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: CustomScrollView(
        slivers: [
          // App bar con immagine
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.avorio,
            leading: const Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child: HomeButton(light: true),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: restaurant.imageUrl != null
                  ? _buildHeroImage(restaurant.imageUrl!)
                  : _buildImagePlaceholder(),
            ),
          ),
          
          // Contenuto
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.bluNotte,
                      height: 1.2,
                    ),
                  ),

                  if (restaurant.rating != null) ...[
                    const SizedBox(height: 10),
                    _buildRatingRow(context, restaurant.rating!),
                  ],

                  if (restaurant.cuisineTypes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: restaurant.cuisineTypes.map((type) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.rossoGubbio.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.rossoGubbio.withOpacity(0.25),
                            ),
                          ),
                          child: Text(
                            type,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.rossoGubbio,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.grigioChiaro),
                  const SizedBox(height: 20),

                  // Descrizione
                  const Text(
                    'Descrizione',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bluNotte,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.textMuted,
                    ),
                  ),

                  if (restaurant.phoneNumber != null ||
                      restaurant.website != null) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.grigioChiaro),
                    const SizedBox(height: 20),

                    // Informazioni di contatto
                    const Text(
                      'Contatti',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bluNotte,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (restaurant.phoneNumber != null)
                      _buildContactRow(
                        Icons.phone,
                        restaurant.phoneNumber!,
                        () => _makePhoneCall(restaurant.phoneNumber!),
                      ),
                    if (restaurant.website != null)
                      _buildContactRow(
                        Icons.language,
                        'Sito web',
                        () => _openWebsite(restaurant.website!),
                      ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.grigioChiaro),
                  const SizedBox(height: 20),

                  // Indirizzo
                  const Text(
                    'Indirizzo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bluNotte,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant.address,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: AppColors.textMuted,
                    ),
                  ),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Pulsanti azione fissi in basso
      bottomNavigationBar: _buildActionButtons(context),
    );
  }

  Widget _buildRatingRow(BuildContext context, double rating) {
    final fullStars = rating.floor();
    return Row(
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < fullStars ? Icons.star_rounded : Icons.star_outline_rounded,
            color: const Color(0xFFF2A93B),
            size: 22,
          );
        }),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('Valutazione'),
                content: const Text(
                  'Questa valutazione è una media indicativa calcolata dai '
                  'punteggi presenti su TripAdvisor e Google Maps, per '
                  'aiutarti a capire che si tratta di dati reali.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.textMuted.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.tortora.withOpacity(0.6),
            AppColors.avorio,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_menu,
          size: 92,
          color: AppColors.rossoGubbio.withOpacity(0.5),
        ),
      ),
    );
  }

  /// Mostra la foto intera senza tagliarla: sfondo sfocato (riempito con la
  /// stessa immagine in cover) e la foto completa in primo piano con
  /// `BoxFit.contain`.
  Widget _buildHeroImage(String url) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(color: Colors.black.withOpacity(0.15)),
        ),
        Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ],
    );
  }
  
  Widget _buildContactRow(IconData icon, String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.rossoGubbio),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.bluNotte,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color: AppColors.tortora,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mostra sulla mappa
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapPage()),
                  );
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('MOSTRA SULLA MAPPA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rossoGubbio,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Pulsanti navigazione
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openWalkingDirections(),
                    icon: const Icon(Icons.directions_walk, size: 20),
                    label: const Text('A piedi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rossoGubbio,
                      side: const BorderSide(color: AppColors.rossoGubbio),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDrivingDirections(),
                    icon: const Icon(Icons.directions_car, size: 20),
                    label: const Text('In auto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.rossoGubbio,
                      side: const BorderSide(color: AppColors.rossoGubbio),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _openWalkingDirections() async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${restaurant.coordinates.latitude},${restaurant.coordinates.longitude}&travelmode=walking';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
  
  void _openDrivingDirections() async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${restaurant.coordinates.latitude},${restaurant.coordinates.longitude}&travelmode=driving';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
  
  void _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
  
  void _openWebsite(String website) async {
    if (await canLaunchUrl(Uri.parse(website))) {
      await launchUrl(Uri.parse(website), mode: LaunchMode.externalApplication);
    }
  }
}
