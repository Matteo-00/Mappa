import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferiti dell'utente (ristoranti, bar, hotel, luoghi, itinerari, eventi),
/// salvati solo su questo dispositivo, come la lingua.
///
/// Ogni preferito è "tipo:id", dove il tipo è uno dei valori di `MapKind`
/// (restaurant, bar, hotel, chiesa, museo, ..., itinerary, event).
class FavoritesService extends ChangeNotifier {
  FavoritesService._() {
    _ready = _load();
  }

  /// Lettura dei preferiti salvati, attesa prima di ogni modifica (così un
  /// tocco sul cuore appena aperta l'app non va perso).
  late final Future<void> _ready;

  static final FavoritesService instance = FavoritesService._();

  static const _key = 'favorites_v1';
  final List<String> _items = [];

  /// Preferiti dal più recente.
  List<String> get items => List.unmodifiable(_items.reversed);
  int get count => _items.length;

  static String keyFor(String kind, String id) => '$kind:$id';

  bool isFavorite(String kind, String id) => _items.contains(keyFor(kind, id));

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _items
        ..clear()
        ..addAll(prefs.getStringList(_key) ?? const []);
      notifyListeners();
    } catch (_) {
      // Nessun preferito salvato.
    }
  }

  Future<void> toggle(String kind, String id) async {
    await _ready;
    final k = keyFor(kind, id);
    if (!_items.remove(k)) _items.add(k);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, _items);
    } catch (_) {
      // Resta in memoria fino alla chiusura dell'app.
    }
  }
}
