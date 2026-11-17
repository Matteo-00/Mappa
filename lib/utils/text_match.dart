/// Confronto di testi per le ricerche nelle liste: ignora maiuscole, accenti
/// e apostrofi, così "citta" trova "Città" e "sant ubaldo" trova
/// "Sant'Ubaldo".
library;

/// Toglie maiuscole, accenti e apostrofi.
String normalizeText(String s) {
  const from = 'àáâäãåèéêëìíîïòóôöõùúûüçñ';
  const to = 'aaaaaaeeeeiiiiooooouuuucn';
  final buf = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    buf.write(i >= 0 ? to[i] : ch);
  }
  return buf
      .toString()
      .replaceAll(RegExp(r"[’'`´]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// true se ogni parola di [query] compare in almeno uno dei [fields].
/// Una ricerca vuota trova tutto.
bool textMatches(String query, Iterable<String?> fields) {
  final q = normalizeText(query);
  if (q.isEmpty) return true;
  final text = normalizeText(fields.whereType<String>().join(' '));
  return q.split(' ').every(text.contains);
}
