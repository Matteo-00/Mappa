import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant_model.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: AppTheme.vgAncientParchment,
      body: CustomScrollView(
        slivers: [
          // App bar con immagine
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.vgWarmBeige,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.vgDarkSlate,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: restaurant.imageUrl != null
                  ? Image.network(
                      restaurant.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
          
          // Contenuto
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con nome e info
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome
                      Text(
                        restaurant.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.vgDarkSlate,
                          height: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Info rapide
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.euro,
                            restaurant.priceRange,
                          ),
                          const SizedBox(width: 8),
                          if (restaurant.rating != null)
                            _buildInfoChip(
                              Icons.star,
                              restaurant.rating!.toString(),
                            ),
                          const SizedBox(width: 8),
                          if (restaurant.hasDiscount)
                            _buildDiscountChip(),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tipi di cucina
                      if (restaurant.cuisineTypes.isNotEmpty)
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
                                color: AppTheme.vgBronze.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.vgBronze.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.vgBronze,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Descrizione
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Descrizione',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.vgDarkSlate,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        restaurant.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppTheme.vgStoneGray,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Informazioni di contatto
                if (restaurant.phoneNumber != null || restaurant.website != null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contatti',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.vgDarkSlate,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Indirizzo
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Indirizzo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.vgDarkSlate,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        restaurant.address,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppTheme.vgStoneGray,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      
      // Pulsanti azione fissi in basso
      bottomNavigationBar: _buildActionButtons(context),
    );
  }
  
  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.vgWarmStone, AppTheme.vgStoneGray],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 100,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.vgWarmBeige,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.vgBronze),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.vgDarkSlate,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDiscountChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.vgOliveGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text(
            '5% SCONTO',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContactRow(IconData icon, String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.vgBronze),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.vgStoneGray,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppTheme.vgStoneGray,
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mostra sulla mappa
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Torna indietro alla pagina ristoranti con mappa
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.map),
                label: const Text('MOSTRA SULLA MAPPA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vgBronze,
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
                      foregroundColor: AppTheme.vgBronze,
                      side: const BorderSide(color: AppTheme.vgBronze),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                      foregroundColor: AppTheme.vgBronze,
                      side: const BorderSide(color: AppTheme.vgBronze),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
