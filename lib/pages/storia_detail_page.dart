import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/storia_model.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import 'admin/add_storia_content_page.dart';
import 'admin/admin_widgets.dart';

/// Pagina di dettaglio di un contenuto storico (monumento, chiesa, palazzo...)
/// della sezione "Storia di Gubbio". Mostra solo le sezioni che hanno
/// realmente contenuto: Storia, Curiosità, Racconto da local, Galleria.
class StoriaDetailPage extends StatefulWidget {
  final StoriaContenuto contenuto;
  final StoriaEpoca? epoca;

  const StoriaDetailPage({super.key, required this.contenuto, this.epoca});

  @override
  State<StoriaDetailPage> createState() => _StoriaDetailPageState();
}

class _StoriaDetailPageState extends State<StoriaDetailPage> {
  late StoriaContenuto _contenuto;

  @override
  void initState() {
    super.initState();
    _contenuto = widget.contenuto;
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddStoriaContentPage(editContenuto: _contenuto),
      ),
    );
    if (updated == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDelete(context, _contenuto.title);
    if (!ok) return;
    try {
      await ContentService.deleteStoriaContenuto(_contenuto.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  Future<void> _openDirections(String travelMode) async {
    final c = _contenuto;
    if (!c.hasCoordinates) return;
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&destination=${c.latitude},${c.longitude}'
        '&travelmode=$travelMode';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;
    final c = _contenuto;

    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: AppColors.bluNotte,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: isAdmin
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      onPressed: _edit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white),
                      onPressed: _delete,
                    ),
                  ]
                : null,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (c.coverImage != null)
                    Image.network(c.coverImage!, fit: BoxFit.cover)
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(gradient: AppColors.heroFallback),
                      child: Center(
                        child: Icon(_categoryIcon(c.category),
                            size: 64, color: Colors.white.withOpacity(0.85)),
                      ),
                    ),
                  const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.heroOverlay)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.epoca != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.rossoGubbio,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              widget.epoca!.nome.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          c.title,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            color: Colors.white,
                          ),
                        ),
                        if (c.displayDate.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            c.displayDate,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.shortDescription.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.only(left: 16),
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: AppColors.tortora, width: 3)),
                      ),
                      child: Text(
                        c.shortDescription,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                          color: AppColors.bluNotte,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                  ],
                  if (c.hasCoordinates) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openDirections('walking'),
                            icon: const Icon(Icons.directions_walk, size: 20),
                            label: const Text('A piedi'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.rossoGubbio,
                              side: const BorderSide(color: AppColors.rossoGubbio),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openDirections('driving'),
                            icon: const Icon(Icons.directions_car, size: 20),
                            label: const Text('In auto'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.rossoGubbio,
                              side: const BorderSide(color: AppColors.rossoGubbio),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                  ],
                  if (c.fullDescription.isNotEmpty)
                    _buildSection(
                      icon: Icons.history_edu_outlined,
                      title: 'Storia',
                      child: Text(
                        c.fullDescription,
                        style: const TextStyle(fontSize: 15.5, height: 1.65, color: AppColors.bluNotte),
                      ),
                    ),
                  if (c.curiosity != null && c.curiosity!.trim().isNotEmpty)
                    _buildSection(
                      icon: Icons.lightbulb_outline,
                      title: 'Curiosità',
                      child: Text(
                        c.curiosity!,
                        style: const TextStyle(fontSize: 15, height: 1.6, color: AppColors.bluNotte),
                      ),
                    ),
                  if (c.localStory != null && c.localStory!.trim().isNotEmpty)
                    _buildSection(
                      icon: Icons.record_voice_over_outlined,
                      title: 'Racconto da local',
                      child: Text(
                        c.localStory!,
                        style: const TextStyle(fontSize: 15, height: 1.65, color: AppColors.bluNotte),
                      ),
                    ),
                  if (c.gallery.isNotEmpty)
                    _buildSection(
                      icon: Icons.photo_library_outlined,
                      title: 'Galleria',
                      child: SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: c.gallery.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, i) => ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              c.gallery[i],
                              width: 140,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (c.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: c.tags
                          .map((t) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.grigioChiaro,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.bluNotte,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.rossoGubbio),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluNotte,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'chiesa':
        return Icons.church_outlined;
      case 'palazzo':
        return Icons.account_balance_outlined;
      case 'piazza':
        return Icons.location_city_outlined;
      case 'natura':
        return Icons.park_outlined;
      default:
        return Icons.castle_outlined;
    }
  }
}

