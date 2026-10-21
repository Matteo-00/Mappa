import '../widgets/distance_label.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant_model.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/rating_icons.dart';
import 'map_page.dart';

/// Pagina dettaglio ristorante
class RestaurantDetailPage extends StatelessWidget {
  final RestaurantModel restaurant;
  /// Icona mostrata quando manca la foto (ristorante di default).
  final IconData fallbackIcon;

  /// Tipo di punto sulla mappa ([MapKind]): ristorante, bar o hotel.
  final String mapKind;
  
  const RestaurantDetailPage({
    super.key,
    required this.restaurant,
    this.fallbackIcon = Icons.restaurant_menu,
    this.mapKind = MapKind.restaurant,
  });

  AppLocalizations _l10n(BuildContext context) => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
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
                  Text(
                    l10n.description,
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
                    Text(
                      l10n.contactsSection,
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
                        l10n.t('websiteLabel'),
                        () => _openWebsite(restaurant.website!),
                      ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppColors.grigioChiaro),
                  const SizedBox(height: 20),

                  // Indirizzo
                  Text(
                    l10n.t('addressLabel'),
                    style: const TextStyle(
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
                  const SizedBox(height: 8),
                  DistanceLabel(
                    target: restaurant.coordinates,
                    fontSize: 14,
                    suffix: true,
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
    return RatingSummary(rating: rating, iconSize: 22, fontSize: 15);
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
          fallbackIcon,
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
                    MaterialPageRoute(
                      builder: (_) => MapPage(
                        focus: MapFocus(
                          kind: mapKind,
                          id: restaurant.id,
                          position: restaurant.coordinates,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined),
                label: Text(_l10n(context).t('showOnMapBtn')),
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
                    label: Text(_l10n(context).t('walkBtn')),
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
                    label: Text(_l10n(context).t('carBtn')),
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
