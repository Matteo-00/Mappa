import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/itinerario_model.dart';
import '../../services/content_service.dart';
import '../../services/language_service.dart';
import '../../theme/app_colors.dart';
import 'admin_widgets.dart';
import '../../widgets/loading_screen.dart';

/// Schermata admin: sceglie quali itinerari (massimo 3) compaiono nella
/// vetrina "Itinerari consigliati" della home. L'ordine in cui li selezioni
/// è l'ordine in cui compaiono.
class ScegliVetrinaPage extends StatefulWidget {
  const ScegliVetrinaPage({super.key});

  @override
  State<ScegliVetrinaPage> createState() => _ScegliVetrinaPageState();
}

class _ScegliVetrinaPageState extends State<ScegliVetrinaPage> {
  static const int _max = 3;

  List<ItinerarioModel> _all = [];
  final List<String> _selected = []; // id in ordine di vetrina
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loadingStart = DateTime.now();
    final lang = context.read<LanguageService>().currentLanguageCode;
    final all = await ContentService.fetchItinerari(languageCode: lang);
    final current = await ContentService.fetchItinerariVetrina(languageCode: lang);
    // La crescia resta almeno un secondo, così non "lampeggia".
    if (_loading) await LoadingScreen.waitMinimum(loadingStart);
    if (!mounted) return;
    setState(() {
      _all = all;
      _selected
        ..clear()
        ..addAll(current.map((i) => i.id));
      _loading = false;
    });
  }

  void _toggle(ItinerarioModel it) {
    setState(() {
      if (_selected.contains(it.id)) {
        _selected.remove(it.id);
      } else if (_selected.length >= _max) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hai già scelto 3 itinerari: togline uno per sceglierne un altro.'),
          ),
        );
      } else {
        _selected.add(it.id);
      }
    });
  }

  Future<void> _save() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ContentService.setItinerariVetrina(_selected);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vetrina aggiornata!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final missing = e.toString().contains('vetrina_ordine');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(missing
              ? 'Manca la colonna della vetrina: esegui lo script '
                  'supabase_itinerari_vetrina.sql nel SQL Editor di Supabase.'
              : 'Errore: $e'),
          backgroundColor: const Color(0xFFB71C1C),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      appBar: AppBar(title: const Text('Itinerari in vetrina')),
      body: _loading
          ? LoadingScreen(fullPage: false, onRetry: _load)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tocca gli itinerari da mostrare nella home. '
                          'L\'ordine in cui li scegli è l\'ordine in vetrina.',
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: AppColors.bluNotte.withOpacity(0.75),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selected.length == _max
                              ? AppColors.verdeSalvia
                              : AppColors.tortora.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_selected.length}/$_max',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _selected.length == _max
                                ? Colors.white
                                : AppColors.bluNotte,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _all.isEmpty
                      ? const Center(
                          child: Text('Non ci sono ancora itinerari da scegliere.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          itemCount: _all.length,
                          itemBuilder: (context, i) => _tile(_all[i]),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: SafeArea(
                    top: false,
                    child: AdminSaveButton(
                      loading: _saving,
                      onPressed: _selected.isEmpty ? () {} : _save,
                      label: _selected.isEmpty
                          ? 'SCEGLI ALMENO UN ITINERARIO'
                          : 'SALVA VETRINA',
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _tile(ItinerarioModel it) {
    final position = _selected.indexOf(it.id); // -1 se non scelto
    final isSelected = position >= 0;
    final disabled = !isSelected && _selected.length >= _max;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.rossoGubbio : AppColors.grigioChiaro,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _toggle(it),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: it.imageUrl != null
                          ? Image.network(
                              it.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _thumbPlaceholder(it),
                            )
                          : _thumbPlaceholder(it),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.titolo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.bluNotte,
                          ),
                        ),
                        if (it.tema.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            it.tema,
                            style: const TextStyle(
                                fontSize: 12.5, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.rossoGubbio : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.rossoGubbio
                            : AppColors.grigioChiaro,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Text(
                            '${position + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(ItinerarioModel it) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.grigioChiaro, AppColors.tortora],
        ),
      ),
      child: Icon(it.icona, color: Colors.white.withOpacity(0.9)),
    );
  }
}
