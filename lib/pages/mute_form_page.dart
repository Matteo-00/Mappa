import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/muta_model.dart';
import '../data/mute_data.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';

/// Pagina per creare o modificare una muta
class MuteFormPage extends StatefulWidget {
  final MutaModel? muta;

  const MuteFormPage({
    super.key,
    this.muta,
  });

  @override
  State<MuteFormPage> createState() => _MuteFormPageState();
}

class _MuteFormPageState extends State<MuteFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nomeController;
  late TextEditingController _zoneController;
  late TextEditingController _capoMutaController;
  late TextEditingController _capocorsaController;
  
  // Controllers per esterni sinistra
  late List<TextEditingController> _esterniSinistraControllers;
  
  // Controllers per esterni destra
  late List<TextEditingController> _esterniDestraControllers;
  
  // Controllers per interni posteriori
  late List<TextEditingController> _interniPosterioriControllers;
  
  late LatLng _selectedCoordinates;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.muta != null;
    
    // Inizializza i controllers
    _nomeController = TextEditingController(text: widget.muta?.name ?? '');
    _zoneController = TextEditingController(text: widget.muta?.zone ?? '');
    _capoMutaController = TextEditingController(text: widget.muta?.capoMuta ?? '');
    _capocorsaController = TextEditingController(text: widget.muta?.capocorsa ?? '');
    
    _esterniSinistraControllers = List.generate(
      4,
      (index) => TextEditingController(
        text: widget.muta?.esterniSinistra[index] ?? '',
      ),
    );
    
    _esterniDestraControllers = List.generate(
      4,
      (index) => TextEditingController(
        text: widget.muta?.esterniDestra[index] ?? '',
      ),
    );
    
    _interniPosterioriControllers = List.generate(
      2,
      (index) => TextEditingController(
        text: widget.muta?.interniPosteriori[index] ?? '',
      ),
    );
    
    _selectedCoordinates = widget.muta?.coordinates ?? 
        const LatLng(43.35190, 12.57730); // Default: Piazza Grande
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _zoneController.dispose();
    _capoMutaController.dispose();
    _capocorsaController.dispose();
    for (var controller in _esterniSinistraControllers) {
      controller.dispose();
    }
    for (var controller in _esterniDestraControllers) {
      controller.dispose();
    }
    for (var controller in _interniPosterioriControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? l10n.editMutaTitle : l10n.newMuta),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informazioni generali
            _buildSectionHeader(l10n.generalInfoSection),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nomeController,
              label: l10n.mutaNameLabel,
              icon: Icons.people,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.nameRequiredError;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _zoneController,
              label: l10n.zoneLocationLabel,
              icon: Icons.location_on_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.zoneRequiredError;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _capoMutaController,
              label: l10n.capoMutaLabel,
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.capoMutaRequiredError;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Capocorsa
            _buildSectionHeader(l10n.capocorsaFrontSection),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _capocorsaController,
              label: l10n.capocorsaLabel,
              icon: Icons.star,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.capocorsaRequiredError;
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Esterni Sinistra
            _buildSectionHeader(l10n.leftExternsSection),
            const SizedBox(height: 8),
            ..._esterniSinistraControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTextField(
                  controller: entry.value,
                  label: l10n.externalLeftLabel(entry.key + 1),
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.requiredField;
                    }
                    return null;
                  },
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Esterni Destra
            _buildSectionHeader(l10n.rightExternsSection),
            const SizedBox(height: 8),
            ..._esterniDestraControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTextField(
                  controller: entry.value,
                  label: l10n.externalRightLabel(entry.key + 1),
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.requiredField;
                    }
                    return null;
                  },
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Interni Posteriori
            _buildSectionHeader(l10n.rearInternsSection),
            const SizedBox(height: 8),
            ..._interniPosterioriControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTextField(
                  controller: entry.value,
                  label: l10n.internalRearLabel(entry.key + 1),
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.requiredField;
                    }
                    return null;
                  },
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Pulsante salva
            ElevatedButton(
              onPressed: _saveMuta,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEditMode ? l10n.saveChangesButton : l10n.createMutaButton,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            if (_isEditMode) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _deleteMuta,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.deleteMutaButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFFB71C1C),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
        ),
      ),
      validator: validator,
    );
  }

  void _saveMuta() {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fillAllRequiredFields),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newMuta = MutaModel(
      id: widget.muta?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nomeController.text,
      zone: _zoneController.text,
      info: 'Muta configurata', // Info di default
      coordinates: _selectedCoordinates,
      capoMuta: _capoMutaController.text,
      capocorsa: _capocorsaController.text,
      esterniSinistra: _esterniSinistraControllers.map((c) => c.text).toList(),
      esterniDestra: _esterniDestraControllers.map((c) => c.text).toList(),
      interniPosteriori: _interniPosterioriControllers.map((c) => c.text).toList(),
    );

    if (_isEditMode) {
      // Modifica muta esistente
      final index = muteData.indexWhere((m) => m.id == widget.muta!.id);
      if (index != -1) {
        muteData[index] = newMuta;
      }
    } else {
      // Aggiungi nuova muta
      muteData.add(newMuta);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditMode ? l10n.mutaUpdatedSuccess : l10n.mutaCreatedSuccess),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  void _deleteMuta() {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMutaButton),
        content: Text(l10n.deleteMutaConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              muteData.removeWhere((m) => m.id == widget.muta!.id);
              Navigator.pop(context); // Chiudi dialog
              Navigator.pop(context); // Torna alla lista
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.mutaDeletedSuccess),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
