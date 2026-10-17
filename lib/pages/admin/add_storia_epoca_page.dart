import 'package:flutter/material.dart';

import '../../models/storia_model.dart';
import '../../services/content_service.dart';
import '../../theme/app_colors.dart';
import 'admin_widgets.dart';

/// Form per aggiungere o modificare un'epoca della timeline di Gubbio
/// (nome, periodo, descrizione, date/eventi da ricordare, posizione).
class AddStoriaEpocaPage extends StatefulWidget {
  final StoriaEpoca? editEpoca;

  /// Ordine suggerito per una nuova epoca (di norma: in fondo alla lista).
  final int suggestedSortOrder;

  const AddStoriaEpocaPage({
    super.key,
    this.editEpoca,
    this.suggestedSortOrder = 0,
  });

  @override
  State<AddStoriaEpocaPage> createState() => _AddStoriaEpocaPageState();
}

class _AddStoriaEpocaPageState extends State<AddStoriaEpocaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _periodo = TextEditingController();
  final _descrizione = TextEditingController();
  final _eventi = TextEditingController();
  final _sortOrder = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.editEpoca != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editEpoca;
    if (e != null) {
      _nome.text = e.nome;
      _periodo.text = e.periodo;
      _descrizione.text = e.descrizione;
      _eventi.text = e.eventiImportanti.join('\n');
      _sortOrder.text = e.sortOrder.toString();
    } else {
      _sortOrder.text = widget.suggestedSortOrder.toString();
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _periodo.dispose();
    _descrizione.dispose();
    _eventi.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  String _slugify(String text) => text
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r"['’]"), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final eventi = _eventi.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // In modifica lo slug resta invariato (è un identificativo stabile).
      final slug = widget.editEpoca?.slug.isNotEmpty == true
          ? widget.editEpoca!.slug
          : _slugify(_nome.text);

      final epoca = StoriaEpoca(
        id: widget.editEpoca?.id ?? '',
        slug: slug,
        nome: _nome.text.trim(),
        periodo: _periodo.text.trim(),
        descrizione: _descrizione.text.trim(),
        eventiImportanti: eventi,
        sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
      );

      if (_isEditing) {
        await ContentService.updateStoriaEpoca(epoca);
      } else {
        await ContentService.addStoriaEpoca(epoca);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Epoca aggiornata!' : 'Epoca aggiunta!'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      appBar: AppBar(title: Text(_isEditing ? 'Modifica epoca' : 'Nuova epoca')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nome,
              textCapitalization: TextCapitalization.sentences,
              decoration: adminInputDecoration('Nome dell\'epoca *',
                  icon: Icons.history_edu_outlined),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Inserisci il nome' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _periodo,
              decoration: adminInputDecoration(
                'Periodo (es. "XI – XIV secolo")',
                icon: Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descrizione,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: adminInputDecoration(
                'Descrizione dell\'epoca',
                icon: Icons.notes,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _eventi,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: adminInputDecoration(
                'Da ricordare: date o eventi (uno per riga)',
                icon: Icons.flag_outlined,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _sortOrder,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: adminInputDecoration(
                'Posizione nella timeline (numero, più basso = prima)',
                icon: Icons.sort,
              ),
              validator: (v) => int.tryParse((v ?? '').trim()) == null
                  ? 'Inserisci un numero intero'
                  : null,
            ),
            const SizedBox(height: 24),
            AdminSaveButton(
              loading: _saving,
              onPressed: _save,
              label: _isEditing ? 'SALVA MODIFICHE' : 'SALVA',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
