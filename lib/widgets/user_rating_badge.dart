import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/review_model.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';

/// Voto medio degli utenti nelle liste: "★ 4.3 · 12 recensioni", separato
/// dal voto Visit Gubbio.
class UserRatingBadge extends StatelessWidget {
  final ReviewStats stats;

  const UserRatingBadge({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5A623)),
          const SizedBox(width: 3),
          Text(
            stats.average.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.bluNotte,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '· ${l.count('rvCount', stats.count)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
