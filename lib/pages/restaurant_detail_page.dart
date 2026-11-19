import '../widgets/distance_label.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/restaurant_model.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import '../widgets/rating_icons.dart';
import '../widgets/reviews_section.dart';
import '../widgets/favorite_button.dart';
import '../services/content_service.dart';
import '../services/review_service.dart';
import 'map_page.dart';

/// Pagina dettaglio ristorante
class RestaurantDetailPage extends StatelessWidget {
  final RestaurantModel restaurant;

  /// Icona mostrata quando manca la foto (ristorante di default).
  final IconData fallbackIcon;

  /// Tipo di punto sulla mappa ([MapKind]): ristorante, bar, hotel, chiesa...
  final String mapKind;

  /// Sezione in più dopo la descrizione (es. i collegamenti alla Storia di
  /// Gubbio di chiese e musei). Si occupa da sola dei propri margini.
  final Widget? extraSection;

  const RestaurantDetailPage({
    super.key,
    required this.restaurant,
    this.fallbackIcon = Icons.restaurant_menu,
    this.mapKind = MapKind.restaurant,
    this.extraSection,
  });

  /// Tipo per le recensioni degli utenti: solo ristoranti, bar e hotel
  /// salvati su Supabase (null = niente recensioni).
  String? get _reviewsEntity {
    if (!ContentService.isRemoteId(restaurant.id)) return null;
    switch (mapKind) {
      case MapKind.restaurant:
        return ReviewService.restaurants;
      case MapKind.bar:
        return ReviewService.bars;
      case MapKind.hotel:
        return ReviewService.hotels;
      default:
        return null;
    }
  }

  AppLocalizations _l10n(BuildContext context) =>
      AppLocalizations.of(context.read<LanguageService>().currentLanguageCode);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
      context.watch<LanguageService>().currentLanguageCode,
    );
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
            leadingWidth: NavButtons.widthFor(context) + 8,
            leading: const Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: NavButtons(light: true),
              ),
            ),
            actions: [
              if (ContentService.isRemoteId(restaurant.id))
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 4),
                  child: FavoriteButton(kind: mapKind, id: restaurant.id),
                ),
            ],
            // Foto grande con il nome sopra: scorrendo si restringe e il
            // nome passa nella barra in alto.
            flexibleSpace: LayoutBuilder(
              builder: (context, c) {
                final top = MediaQuery.of(context).padding.top;
                final t =
                    ((c.maxHeight - kToolbarHeight - top) /
                            (300 - kToolbarHeight))
                        .clamp(0.0, 1.0);
                final navWidth = NavButtons.widthFor(context) + 16;
                // ClipRect: la sfocatura della foto resta dentro la barra.
                return ClipRect(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Opacity(
                        opacity: t,
                        child: restaurant.imageUrl != null
                            ? _buildHeroImage(restaurant.imageUrl!)
                            : _buildImagePlaceholder(),
                      ),
                      Opacity(
                        opacity: t,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x55000000),
                                Color(0x00000000),
                                Color(0xCC000000),
                              ],
                              stops: [0, 0.4, 1],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20 + (1 - t) * (navWidth - 20),
                        right: 70,
                        bottom: 12 + t * 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (t > 0.5 && restaurant.cuisineTypes.isNotEmpty)
                              Opacity(
                                opacity: (t - 0.5) * 2,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.rossoGubbio,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    restaurant.cuisineTypes.first.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 0.9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            Text(
                              restaurant.name,
                              maxLines: t > 0.5 ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 19 + 9 * t,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                                color: Color.lerp(
                                  AppColors.bluNotte,
                                  Colors.white,
                                  t,
                                ),
                                shadows: t > 0.5
                                    ? const [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                  if (restaurant.rating != null) ...[
                    const SizedBox(height: 10),
                    // Con le recensioni si distingue il voto della redazione
                    // da quello degli utenti.
                    if (_reviewsEntity != null)
                      Text(
                        l10n.t('rvOfficialRating'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    _buildRatingRow(context, restaurant.rating!),
                  ],

                  const SizedBox(height: 18),
                  _buildQuickActions(context),

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
                            color: AppColors.rossoGubbio.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.rossoGubbio.withValues(
                                alpha: 0.25,
                              ),
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

                  if (extraSection != null) extraSection!,

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

                  if (_reviewsEntity != null) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: AppColors.grigioChiaro),
                    const SizedBox(height: 20),
                    ReviewsSection(
                      entityType: _reviewsEntity!,
                      entityId: restaurant.id,
                      kind: _ratingKind,
                    ),
                  ],

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ogni tipo di luogo ha la sua icona: crescia, Amaro Matto, Palazzo dei Consoli.
  RatingKind get _ratingKind => mapKind == MapKind.bar
      ? RatingKind.amaro
      : mapKind == MapKind.hotel
      ? RatingKind.palazzo
      : (mapKind == MapKind.negozio ||
            mapKind == MapKind.sport ||
            mapKind == MapKind.agriturismo)
      ? RatingKind.stelle
      : RatingKind.crescia;

  Widget _buildRatingRow(BuildContext context, double rating) {
    return RatingSummary(
      rating: rating,
      kind: _ratingKind,
      iconSize: 22,
      fontSize: 15,
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tortora.withValues(alpha: 0.6), AppColors.avorio],
        ),
      ),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: 92,
          color: AppColors.rossoGubbio.withValues(alpha: 0.5),
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
          child: Container(color: Colors.black.withValues(alpha: 0.15)),
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

  /// Pulsanti rapidi tondi: Chiama, Indicazioni, Mappa, Sito, Condividi
  /// (Chiama e Sito solo se ci sono).
  Widget _buildQuickActions(BuildContext context) {
    final l = _l10n(context);
    final phone = restaurant.phoneNumber?.trim() ?? '';
    final site = restaurant.website?.trim() ?? '';
    final actions = <(IconData, String, VoidCallback)>[
      if (phone.isNotEmpty)
        (Icons.call_outlined, l.t('actCall'), () => _makePhoneCall(phone)),
      (Icons.directions_outlined, l.t('actDirections'), _openWalkingDirections),
      (
        Icons.map_outlined,
        l.t('actMap'),
        () => Navigator.push(
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
        ),
      ),
      if (site.isNotEmpty)
        (Icons.language_rounded, l.t('actWebsite'), () => _openWebsite(site)),
      (Icons.share_outlined, l.t('evShare'), () => _share(context)),
    ];
    return Row(
      children: [
        for (final (icon, label, onTap) in actions)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.avorio,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.grigioChiaro),
                      ),
                      child: Icon(icon, color: AppColors.rossoGubbio),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.bluNotte,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _share(BuildContext context) {
    final p = restaurant.coordinates;
    final text = [
      restaurant.name,
      if (restaurant.address.trim().isNotEmpty) restaurant.address.trim(),
      'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}',
    ].join('\n');
    SharePlus.instance.share(ShareParams(text: text, subject: restaurant.name));
  }

  void _openWalkingDirections() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${restaurant.coordinates.latitude},${restaurant.coordinates.longitude}&travelmode=walking';
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
