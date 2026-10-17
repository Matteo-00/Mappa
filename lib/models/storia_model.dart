/// Un'epoca della timeline storica di Gubbio (es. "Il Libero Comune").
class StoriaEpoca {
  final String id;
  final String slug;
  final String nome;
  final String periodo;
  final String descrizione;
  final List<String> eventiImportanti;
  final int sortOrder;

  const StoriaEpoca({
    required this.id,
    required this.slug,
    required this.nome,
    required this.periodo,
    required this.descrizione,
    this.eventiImportanti = const [],
    this.sortOrder = 0,
  });

  factory StoriaEpoca.fromJson(Map<String, dynamic> json) {
    return StoriaEpoca(
      id: json['id'].toString(),
      slug: (json['slug'] ?? '') as String,
      nome: (json['nome'] ?? '') as String,
      periodo: (json['periodo'] ?? '') as String,
      descrizione: (json['descrizione'] ?? '') as String,
      eventiImportanti: (json['eventi_importanti'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'nome': nome,
      'periodo': periodo,
      'descrizione': descrizione,
      'eventi_importanti': eventiImportanti,
      'sort_order': sortOrder,
    };
  }
}

/// Testi e foto di copertina della pagina "Storia di Gubbio"
/// (modificabili dagli admin). I valori predefiniti sono quelli storici.
class StoriaIntro {
  static const defaultTitolo = 'La storia di Gubbio';
  static const defaultSottotitolo =
      'Più di 2.000 anni da attraversare, epoca dopo epoca';
  static const defaultTesto =
      'Dall\'antica Iguvium al Libero Comune, dal Rinascimento dei '
      'Montefeltro ai giorni nostri: scorri la linea del tempo oppure '
      'filtra per epoca e tipo di luogo.';

  final String titolo;
  final String sottotitolo;
  final String testo;
  final String? imageUrl;

  const StoriaIntro({
    this.titolo = defaultTitolo,
    this.sottotitolo = defaultSottotitolo,
    this.testo = defaultTesto,
    this.imageUrl,
  });

  /// I campi vuoti ricadono sui testi predefiniti.
  factory StoriaIntro.fromJson(Map<String, dynamic> json) {
    String pick(String key, String fallback) {
      final v = (json[key] as String?)?.trim() ?? '';
      return v.isEmpty ? fallback : v;
    }

    final img = (json['image_url'] as String?)?.trim();
    return StoriaIntro(
      titolo: pick('titolo', defaultTitolo),
      sottotitolo: pick('sottotitolo', defaultSottotitolo),
      testo: pick('testo', defaultTesto),
      imageUrl: (img == null || img.isEmpty) ? null : img,
    );
  }
}

/// Un contenuto storico (monumento, chiesa, palazzo, luogo...) collegato
/// a un'epoca della timeline di Gubbio.
class StoriaContenuto {
  final String id;
  final String? eraId;
  final String title;
  final String slug;
  final String category;
  final String displayDate;
  final int? startYear;
  final int? endYear;
  final String shortDescription;
  final String fullDescription;
  final String? localStory;
  final String? curiosity;
  final List<String> tags;
  final String? coverImage;
  final List<String> gallery;
  final int sortOrder;
  final bool isPublished;
  final double? latitude;
  final double? longitude;

  const StoriaContenuto({
    required this.id,
    this.eraId,
    required this.title,
    required this.slug,
    this.category = 'monumento',
    this.displayDate = '',
    this.startYear,
    this.endYear,
    this.shortDescription = '',
    this.fullDescription = '',
    this.localStory,
    this.curiosity,
    this.tags = const [],
    this.coverImage,
    this.gallery = const [],
    this.sortOrder = 0,
    this.isPublished = true,
    this.latitude,
    this.longitude,
  });

  /// true se l'admin ha già impostato una posizione per le indicazioni stradali.
  bool get hasCoordinates => latitude != null && longitude != null;

  factory StoriaContenuto.fromJson(Map<String, dynamic> json) {
    return StoriaContenuto(
      id: json['id'].toString(),
      eraId: json['era_id']?.toString(),
      title: (json['title'] ?? '') as String,
      slug: (json['slug'] ?? '') as String,
      category: (json['category'] ?? 'monumento') as String,
      displayDate: (json['display_date'] ?? '') as String,
      startYear: (json['start_year'] as num?)?.toInt(),
      endYear: (json['end_year'] as num?)?.toInt(),
      shortDescription: (json['short_description'] ?? '') as String,
      fullDescription: (json['full_description'] ?? '') as String,
      localStory: json['local_story'] as String?,
      curiosity: json['curiosity'] as String?,
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      coverImage: json['cover_image'] as String?,
      gallery:
          (json['gallery'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isPublished: (json['is_published'] as bool?) ?? true,
      latitude: (json['latitudine'] as num?)?.toDouble(),
      longitude: (json['longitudine'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'era_id': eraId,
      'title': title,
      'slug': slug,
      'category': category,
      'display_date': displayDate,
      'start_year': startYear,
      'end_year': endYear,
      'short_description': shortDescription,
      'full_description': fullDescription,
      'local_story': localStory,
      'curiosity': curiosity,
      'tags': tags,
      'cover_image': coverImage,
      'gallery': gallery,
      'sort_order': sortOrder,
      'is_published': isPublished,
      'latitudine': latitude,
      'longitudine': longitude,
    };
  }

  /// Testo aggregato usato per la ricerca per parole chiave.
  String get searchableText => [
        title,
        shortDescription,
        fullDescription,
        localStory ?? '',
        curiosity ?? '',
        displayDate,
        ...tags,
      ].join(' ').toLowerCase();
}
