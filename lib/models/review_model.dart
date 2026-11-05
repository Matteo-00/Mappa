/// Una recensione di un utente (stelle + commento) su ristoranti, bar,
/// hotel o itinerari. Tabella `recensioni` su Supabase.
class ReviewModel {
  final String id;
  final String userId;

  /// Nome pubblico dell'autore (es. "Matteo R."), scritto dal database.
  final String author;

  /// Da 1 a 5.
  final int stars;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewModel({
    required this.id,
    required this.userId,
    required this.author,
    required this.stars,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEdited => updatedAt.difference(createdAt).inMinutes >= 1;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.now();
    return ReviewModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      author: (json['autore'] ?? '') as String,
      stars: (json['stelle'] as num?)?.toInt() ?? 0,
      comment: (json['commento'] ?? '') as String,
      createdAt: created.toLocal(),
      updatedAt: (DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
              created)
          .toLocal(),
    );
  }
}

/// Recensione segnalata (solo per gli admin): la recensione e i motivi.
class ReportedReview {
  final String reviewId;
  final String entityType;
  final String entityId;
  final ReviewModel review;
  final List<String> reasons;

  const ReportedReview({
    required this.reviewId,
    required this.entityType,
    required this.entityId,
    required this.review,
    required this.reasons,
  });
}

/// Media e numero delle recensioni degli utenti di una scheda.
class ReviewStats {
  final double average;
  final int count;
  const ReviewStats(this.average, this.count);
}
