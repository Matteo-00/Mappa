import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mappa/models/event_model.dart';
import 'package:mappa/services/search_service.dart';

/// Chiavi definite per ogni lingua in lib/l10n/app_localizations.dart.
Map<String, Set<String>> _keysByLanguage() {
  final src = File('lib/l10n/app_localizations.dart').readAsStringSync();
  final result = <String, Set<String>>{};
  String? current;
  final langRe = RegExp(r"^    '(it|en|de|fr)': \{");
  final keyRe = RegExp(r"^      '([A-Za-z0-9_]+)':");
  for (final line in src.split('\n')) {
    final lang = langRe.firstMatch(line);
    if (lang != null) {
      current = lang.group(1);
      result[current!] = {};
      continue;
    }
    final key = keyRe.firstMatch(line);
    if (current != null && key != null) result[current]!.add(key.group(1)!);
  }
  return result;
}

void main() {
  test('ogni testo esiste in tutte e 4 le lingue', () {
    final keys = _keysByLanguage();
    expect(keys.keys, containsAll(['it', 'en', 'de', 'fr']));
    for (final lang in ['en', 'de', 'fr']) {
      final missing = keys['it']!.difference(keys[lang]!);
      final extra = keys[lang]!.difference(keys['it']!);
      expect(missing, isEmpty, reason: 'mancano in $lang');
      expect(extra, isEmpty, reason: 'in più in $lang');
    }
  });

  test('un evento importato in bozza dal Comune viene letto correttamente', () {
    final e = EventModel.fromJson({
      'id': 'abc-1',
      'titolo': 'Concerto',
      'data_inizio': '2026-11-21T17:00:00Z',
      'data_fine': '2026-11-21T19:00:00Z',
      'stato': 'bozza',
      'fonte': 'comune_gubbio',
      'fonte_url': 'https://www.comune.gubbio.pg.it/it/events/1',
      'date_da_verificare': true,
    });
    expect(e.isDraft, isTrue);
    expect(e.isFromComune, isTrue);
    expect(e.datesToVerify, isTrue);
    expect(e.location, '');
  });

  test('un evento inserito a mano resta pubblicato', () {
    final e = EventModel.fromJson({
      'id': 'abc-2',
      'titolo': 'Festa',
      'data_inizio': '2026-05-15T08:00:00Z',
      'data_fine': '2026-05-15T20:00:00Z',
    });
    expect(e.isDraft, isFalse);
    expect(e.isFromComune, isFalse);
  });

  test('la ricerca ignora maiuscole, accenti e apostrofi', () {
    expect(SearchService.normalize("Città"), 'citta');
    expect(SearchService.normalize("Sant'Ubaldo"), 'sant ubaldo');
    expect(SearchService.normalize('  Basilica   di  SAN  '), 'basilica di san');
  });

  test('una notizia del Comune non è un evento', () {
    final n = EventModel.fromJson({
      'id': 'abc-3',
      'titolo': 'Modifiche alla circolazione',
      'data_inizio': '2026-11-03T11:00:00Z',
      'data_fine': '2026-11-03T11:00:00Z',
      'tipo': 'notizia',
      'fonte': 'comune_gubbio',
    });
    expect(n.isNews, isTrue);
    expect(n.isFromComune, isTrue);
  });
}
