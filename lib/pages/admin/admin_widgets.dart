import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../services/language_service.dart';
import '../../l10n/app_localizations.dart';

/// Mostra un dialog di conferma per eliminare un elemento.
Future<bool> confirmDelete(BuildContext context, String name) async {
  final l10n = AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.delete),
      content: Text(l10n.deleteConfirmMessage(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.rossoGubbio),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return res ?? false;
}

/// Pulsante rotondo per eliminare un elemento (solo admin).
class DeleteIconButton extends StatelessWidget {
  final VoidCallback onPressed;

  const DeleteIconButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: AppColors.rossoGubbio.withOpacity(0.10),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const Icon(Icons.delete_outline,
              size: 20, color: AppColors.rossoGubbio),
        ),
      ),
    );
  }
}

/// Pulsante rotondo per modificare un elemento (solo admin).
class EditIconButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EditIconButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: AppColors.bluNotte.withOpacity(0.08),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const Icon(Icons.edit_outlined,
              size: 18, color: AppColors.bluNotte),
        ),
      ),
    );
  }
}

/// Decorazione uniforme per i campi dei form admin.
InputDecoration adminInputDecoration(String label, {IconData? icon}) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    prefixIcon: icon != null ? Icon(icon, color: AppColors.rossoGubbio) : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E1DB), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.rossoGubbio, width: 1.4),
    ),
  );
}

/// Campo per selezionare un'immagine dalla galleria.
class ImagePickerField extends StatefulWidget {
  final void Function(Uint8List? bytes, String? fileName) onChanged;

  /// URL di un'immagine già esistente da mostrare in modalità modifica.
  final String? initialImageUrl;

  const ImagePickerField({
    super.key,
    required this.onChanged,
    this.initialImageUrl,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  Uint8List? _bytes;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _bytes = bytes);
    widget.onChanged(bytes, file.name);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pick,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E1DB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: _bytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(_bytes!, fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: _pick,
                      ),
                    ),
                  ),
                ],
              )
            : (widget.initialImageUrl != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(widget.initialImageUrl!, fit: BoxFit.cover),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.white, size: 20),
                            onPressed: _pick,
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 44,
                          color: AppColors.rossoGubbio.withOpacity(0.7)),
                      const SizedBox(height: 10),
                      const Text(
                        'Tocca per scegliere una foto',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )),
      ),
    );
  }
}

/// Pulsante di salvataggio a piena larghezza con stato di caricamento.
class AdminSaveButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;
  final String label;

  const AdminSaveButton({
    super.key,
    required this.loading,
    required this.onPressed,
    this.label = 'SALVA',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rossoGubbio,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Un'immagine di galleria in attesa di upload (bytes) o già salvata (url).
class GalleryImageItem {
  final Uint8List? bytes;
  final String? fileName;
  final String? url;

  const GalleryImageItem({this.bytes, this.fileName, this.url});
}

/// Campo per gestire una galleria di più immagini (aggiunta/rimozione).
class GalleryPickerField extends StatefulWidget {
  final List<String> initialUrls;
  final void Function(List<GalleryImageItem> items) onChanged;

  const GalleryPickerField({
    super.key,
    this.initialUrls = const [],
    required this.onChanged,
  });

  @override
  State<GalleryPickerField> createState() => _GalleryPickerFieldState();
}

class _GalleryPickerFieldState extends State<GalleryPickerField> {
  late List<GalleryImageItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.initialUrls.map((u) => GalleryImageItem(url: u)).toList();
  }

  Future<void> _pickMore() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80, maxWidth: 1600);
    if (files.isEmpty) return;
    final newItems = <GalleryImageItem>[];
    for (final f in files) {
      final bytes = await f.readAsBytes();
      newItems.add(GalleryImageItem(bytes: bytes, fileName: f.name));
    }
    setState(() => _items = [..._items, ...newItems]);
    widget.onChanged(_items);
  }

  void _remove(int index) {
    setState(() => _items = [..._items]..removeAt(index));
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < _items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 90,
                          height: 90,
                          child: _items[i].bytes != null
                              ? Image.memory(_items[i].bytes!, fit: BoxFit.cover)
                              : Image.network(_items[i].url!, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: GestureDetector(
                          onTap: () => _remove(i),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: _pickMore,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E1DB)),
                  ),
                  child: Icon(Icons.add_photo_alternate_outlined,
                      color: AppColors.rossoGubbio.withOpacity(0.7)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
