import 'package:flutter/material.dart';

import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rating_icons.dart';

/// Schermata admin: recensioni segnalate dagli utenti. Per ognuna si può
/// eliminare la recensione oppure ignorare le segnalazioni (se va bene).
class ReviewReportsPage extends StatefulWidget {
  const ReviewReportsPage({super.key});

  @override
  State<ReviewReportsPage> createState() => _ReviewReportsPageState();
}

class _ReviewReportsPageState extends State<ReviewReportsPage> {
  List<ReportedReview> _items = [];
  bool _loading = true;
  String? _error;

  static const _sections = {
    ReviewService.restaurants: 'Ristorante',
    ReviewService.bars: 'Bar',
    ReviewService.hotels: 'Hotel',
    ReviewService.itineraries: 'Itinerario',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ReviewService.fetchReported();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossibile caricare le segnalazioni: $e';
        _loading = false;
      });
    }
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  Future<void> _deleteReview(ReportedReview item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare la recensione?'),
        content: Text(
            'La recensione di ${item.review.author} verrà eliminata per tutti.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina',
                style: TextStyle(color: Color(0xFFB71C1C))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => ReviewService.delete(item.reviewId), 'Recensione eliminata');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      appBar: AppBar(title: const Text('Recensioni segnalate')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.rossoGubbio))
          : RefreshIndicator(
              color: AppColors.rossoGubbio,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  if (_error != null)
                    Text(_error!,
                        style: const TextStyle(color: Color(0xFFB71C1C)))
                  else if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Text(
                        'Nessuna recensione segnalata.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textMuted),
                      ),
                    ),
                  for (final item in _items) ...[
                    _card(item),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _card(ReportedReview item) {
    final r = item.review;
    final reasons = <String, int>{};
    for (final m in item.reasons) {
      final k = m.isEmpty ? 'Senza motivo' : m;
      reasons[k] = (reasons[k] ?? 0) + 1;
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_sections[item.entityType] ?? item.entityType} · '
            '${item.reasons.length} '
            '${item.reasons.length == 1 ? 'segnalazione' : 'segnalazioni'}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.rossoGubbio,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reasons.entries
                .map((e) => e.value > 1 ? '${e.key} (${e.value})' : e.key)
                .join(' · '),
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          const Divider(height: 22, color: AppColors.grigioChiaro),
          Text(
            r.author,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte,
            ),
          ),
          const SizedBox(height: 4),
          RatingIcons(
              rating: r.stars.toDouble(), size: 15, kind: RatingKind.stelle),
          if (r.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r.comment,
              style: const TextStyle(
                  fontSize: 14.5, height: 1.5, color: AppColors.bluNotte),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _run(
                    () => ReviewService.dismissReports(item.reviewId),
                    'Segnalazioni ignorate',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.bluNotte,
                    side: const BorderSide(color: AppColors.grigioChiaro),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Va bene, ignora'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _deleteReview(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Elimina'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
