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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          color: AppColors.bluNotte,
                          height: 1.2,
                        ),
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
                  ),
                ),
                
                const SizedBox(height: 12),
                
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.bluNotte,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        restaurant.description,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
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
                            fontWeight: FontWeight.w700,
                            color: AppColors.bluNotte,
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
                
                const SizedBox(height: 12),
                
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.bluNotte,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        restaurant.address,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.textMuted,
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
