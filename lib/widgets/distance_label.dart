import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';

import '../services/user_location_service.dart';
import '../theme/app_colors.dart';

/// Distanza dall'utente a un punto ("350 m", "1,4 km").
///
/// Se la posizione non è disponibile mostra, al suo posto, un invito
/// toccabile ("Abilita la posizione per vedere la distanza") che chiede il
/// permesso o apre le impostazioni. Si aggiorna da sola quando la posizione
/// cambia.
class DistanceLabel extends StatefulWidget {
  final LatLng target;
  final double fontSize;

  /// Se true, anche quando la posizione è disponibile aggiunge "da te".
  final bool suffix;

  const DistanceLabel({
    super.key,
    required this.target,
    this.fontSize = 12.5,
    this.suffix = false,
  });

  @override
  State<DistanceLabel> createState() => _DistanceLabelState();
}

class _DistanceLabelState extends State<DistanceLabel> {
  @override
  void initState() {
    super.initState();
    // Primo utilizzo: controlla la posizione (in silenzio, senza richieste).
    if (!UserLocationService.instance.checked) {
      UserLocationService.instance.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final fontSize = widget.fontSize;
    final suffix = widget.suffix;
    final service = UserLocationService.instance;
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        // Prima del primo controllo non mostra nulla (evita un lampeggio).
        if (!service.checked) return const SizedBox.shrink();

        final distance = formattedDistanceTo(target);
        if (distance != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.near_me_rounded,
                  size: fontSize + 1.5, color: AppColors.rossoGubbio),
              const SizedBox(width: 4),
              Text(
                suffix ? l10n.fmt('distanceFromYou', {'d': distance}) : distance,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.rossoGubbio,
                ),
              ),
            ],
          );
        }

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => service.enable(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off_outlined,
                    size: fontSize + 1.5, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    service.availability == LocationAvailability.serviceDisabled
                        ? l10n.t('enableGpsForDistance')
                        : l10n.t('enableLocationForDistance'),
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
