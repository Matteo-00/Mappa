import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';

/// Mostra un dialog di conferma per eliminare un elemento.
Future<bool> confirmDelete(BuildContext context, String name) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Elimina'),
      content: Text('Vuoi eliminare "$name"? L\'operazione è irreversibile.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annulla'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.rossoGubbio),
          child: const Text('Elimina'),
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

  const ImagePickerField({super.key, required this.onChanged});

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
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 44, color: AppColors.rossoGubbio.withOpacity(0.7)),
                  const SizedBox(height: 10),
                  const Text(
                    'Tocca per scegliere una foto',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
