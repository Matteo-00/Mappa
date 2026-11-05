import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/favorites_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';

/// Cuore per aggiungere / togliere una scheda dai preferiti.
class FavoriteButton extends StatelessWidget {
  final String kind;
  final String id;

  /// true = cerchio bianco (sopra le foto), false = cerchio scuro trasparente.
  final bool light;

  const FavoriteButton({
    super.key,
    required this.kind,
    required this.id,
    this.light = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoritesService.instance,
      builder: (context, _) {
        final fav = FavoritesService.instance.isFavorite(kind, id);
        final l = AppLocalizations.of(
            context.read<LanguageService>().currentLanguageCode);
        return Material(
          color: light
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.black.withValues(alpha: 0.28),
          shape: const CircleBorder(),
          elevation: light ? 3 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              FavoritesService.instance.toggle(kind, id);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(l.t(fav ? 'favRemoved' : 'favAdded')),
                  duration: const Duration(seconds: 2),
                ));
            },
            child: Tooltip(
              message: l.t(fav ? 'favRemove' : 'favAdd'),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 23,
                  color: fav
                      ? AppColors.rossoGubbio
                      : (light ? AppColors.bluNotte : Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
