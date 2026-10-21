import 'package:flutter/material.dart';

import '../../models/storia_model.dart';
import '../../theme/app_colors.dart';

/// Apre un elenco con ricerca per scegliere **uno o più** contenuti di
/// "Storia di Gubbio" da collegare (es. a una tappa di un itinerario).
///
/// Restituisce gli id scelti (nell'ordine in cui sono stati selezionati), o
/// `null` se si chiude senza confermare.
Future<List<String>?> showStoriaPicker(
  BuildContext context, {
  required List<StoriaContenuto> all,
  required List<String> selected,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.avorio,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _StoriaPickerSheet(all: all, initiallySelected: selected),
  );
}

class _StoriaPickerSheet extends StatefulWidget {
  final List<StoriaContenuto> all;
  final List<String> initiallySelected;

  const _StoriaPickerSheet({
    required this.all,
    required this.initiallySelected,
  });

  @override
  State<_StoriaPickerSheet> createState() => _StoriaPickerSheetState();
}

class _StoriaPickerSheetState extends State<_StoriaPickerSheet> {
  final _search = TextEditingController();
  late final List<String> _selected = [...widget.initiallySelected];
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<StoriaContenuto> get _visible {
    final q = _query.trim().toLowerCase();
    final list = widget.all.where((c) {
      if (q.isEmpty) return true;
      return c.title.toLowerCase().contains(q) ||
          c.displayDate.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q);
    }).toList();
    // Prima i già scelti, poi in ordine di timeline.
    list.sort((a, b) {
      final sa = _selected.contains(a.id) ? 0 : 1;
      final sb = _selected.contains(b.id) ? 0 : 1;
      if (sa != sb) return sa.compareTo(sb);
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return list;
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.85;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final items = _visible;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grigioChiaro,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Collega eventi storici',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bluNotte,
                      ),
                    ),
                  ),
                  Text(
                    '${_selected.length} scelti',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.rossoGubbio,
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Puoi sceglierne più di uno. Chi apre la tappa potrà arrivare '
                  'direttamente a quel punto della storia di Gubbio.',
                  style: TextStyle(
                      fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Cerca per titolo, data o tipo...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.rossoGubbio),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Nessun contenuto storico trovato.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final c = items[i];
                        final checked = _selected.contains(c.id);
                        return CheckboxListTile(
                          value: checked,
                          onChanged: (_) => _toggle(c.id),
                          activeColor: AppColors.rossoGubbio,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            c.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.bluNotte,
                            ),
                          ),
                          subtitle: c.displayDate.isEmpty
                              ? null
                              : Text(c.displayDate),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.bluNotte,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Annulla'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, _selected),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.rossoGubbio,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Conferma',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
