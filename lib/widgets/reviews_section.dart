import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/review_model.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import 'rating_icons.dart';

/// Sezione "Recensioni degli utenti" delle schede (ristoranti, bar, hotel,
/// itinerari): media, pulsante per scrivere/modificare la propria recensione
/// e l'elenco con nome, voto e commento. Ogni recensione si può segnalare
/// agli admin oppure nascondere bloccandone l'autore.
class ReviewsSection extends StatefulWidget {
  /// Uno dei tipi di [ReviewService] (es. [ReviewService.restaurants]).
  final String entityType;
  final String entityId;
  final RatingKind kind;

  const ReviewsSection({
    super.key,
    required this.entityType,
    required this.entityId,
    this.kind = RatingKind.stelle,
  });

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  List<ReviewModel> _reviews = [];
  Set<String> _blocked = {};
  bool _loading = true;

  AppLocalizations get _l => AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ReviewService.fetch(widget.entityType, widget.entityId),
      ReviewService.blockedAuthors(),
    ]);
    if (!mounted) return;
    setState(() {
      _reviews = results[0] as List<ReviewModel>;
      _blocked = results[1] as Set<String>;
      _loading = false;
    });
  }

  ReviewModel? get _mine {
    final me = ReviewService.currentUserId;
    if (me == null) return null;
    for (final r in _reviews) {
      if (r.userId == me) return r;
    }
    return null;
  }

  List<ReviewModel> get _visible =>
      _reviews.where((r) => !_blocked.contains(r.userId)).toList();

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ------------------------------------------------------------ azioni

  Future<void> _write() async {
    final user = context.read<AuthService>().currentUser;
    final name = user == null
        ? ''
        : '${user.nome.trim()}'
            '${user.cognome.trim().isEmpty ? '' : ' ${user.cognome.trim()[0].toUpperCase()}.'}';
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.avorio,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReviewEditor(
        entityType: widget.entityType,
        entityId: widget.entityId,
        kind: widget.kind,
        existing: _mine,
        publicName: name,
      ),
    );
    if (saved == true && mounted) {
      _snack(_l.t('rvSaved'));
      _load();
    }
  }

  Future<void> _delete(ReviewModel r) async {
    final l = _l;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.t('rvDeleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.t('rvDelete'),
                style: const TextStyle(color: Color(0xFFB71C1C))),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ReviewService.delete(r.id);
      if (!mounted) return;
      _snack(l.t('rvDeleted'));
      _load();
    } catch (_) {
      if (mounted) _snack(l.t('rvGenericError'));
    }
  }

  Future<void> _report(ReviewModel r) async {
    final l = _l;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.t('rvReportTitle')),
        children: [
          for (final key in const [
            'rvReasonOffensive',
            'rvReasonSpam',
            'rvReasonFalse',
            'rvReasonOther',
          ])
            SimpleDialogOption(
              // Il motivo si salva in italiano: lo leggono gli admin.
              onPressed: () => Navigator.pop(
                  ctx, AppLocalizations.of('it').t(key)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(l.t(key), style: const TextStyle(fontSize: 15)),
              ),
            ),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await ReviewService.report(r.id, reason);
      if (mounted) _snack(l.t('rvReported'));
    } catch (_) {
      if (mounted) _snack(l.t('rvGenericError'));
    }
  }

  Future<void> _block(ReviewModel r) async {
    await ReviewService.blockAuthor(r.userId);
    if (!mounted) return;
    setState(() => _blocked = {..._blocked, r.userId});
    _snack(_l.fmt('rvBlocked', {'name': r.author}));
  }

  // ------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final isAdmin = context.watch<AuthService>().isAdmin;
    final loggedIn = ReviewService.currentUserId != null;
    final visible = _visible;
    final mine = _mine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.t('rvTitle'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
          ),
        ),
        const SizedBox(height: 10),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: AppColors.rossoGubbio),
              ),
            ),
          )
        else ...[
          if (visible.isEmpty)
            Text(
              l.t('rvEmpty'),
              style: const TextStyle(
                  fontSize: 14.5, height: 1.5, color: AppColors.textMuted),
            )
          else
            _summary(l, visible),
          if (loggedIn) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _write,
                icon: Icon(mine == null
                    ? Icons.rate_review_outlined
                    : Icons.edit_outlined),
                label: Text(l.t(mine == null ? 'rvWrite' : 'rvEditMine')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rossoGubbio,
                  side: const BorderSide(color: AppColors.rossoGubbio),
                  textStyle: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
          for (final r in visible) ...[
            const SizedBox(height: 14),
            _reviewCard(l, r, isAdmin: isAdmin),
          ],
        ],
      ],
    );
  }

  Widget _summary(AppLocalizations l, List<ReviewModel> reviews) {
    final avg =
        reviews.fold<int>(0, (sum, r) => sum + r.stars) / reviews.length;
    return Row(
      children: [
        RatingIcons(rating: avg, size: 20, kind: widget.kind),
        const SizedBox(width: 8),
        Text(
          avg.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '· ${l.count('rvCount', reviews.length)}',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(AppLocalizations l, ReviewModel r,
      {required bool isAdmin}) {
    final isMine = r.userId == ReviewService.currentUserId;
    final d = r.createdAt;
    final date = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
    final initial = r.author.trim().isEmpty ? '?' : r.author.trim()[0];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 14),
      decoration: BoxDecoration(
        color: AppColors.avorio,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMine
              ? AppColors.rossoGubbio.withOpacity(0.35)
              : AppColors.grigioChiaro,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.rossoGubbio.withOpacity(0.1),
                child: Text(
                  initial.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.rossoGubbio,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          r.author,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.bluNotte,
                          ),
                        ),
                        // Etichetta colorata sulla propria recensione.
                        if (isMine)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.rossoGubbio,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l.t('rvYours'),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      r.isEdited ? '$date · ${l.t('rvEdited')}' : date,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted, size: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      _write();
                      break;
                    case 'delete':
                      _delete(r);
                      break;
                    case 'report':
                      _report(r);
                      break;
                    case 'block':
                      _block(r);
                      break;
                  }
                },
                itemBuilder: (_) => [
                  if (isMine)
                    PopupMenuItem(value: 'edit', child: Text(l.t('rvEdit'))),
                  if (isMine || isAdmin)
                    PopupMenuItem(
                        value: 'delete', child: Text(l.t('rvDelete'))),
                  if (!isMine) ...[
                    PopupMenuItem(
                        value: 'report', child: Text(l.t('rvReport'))),
                    PopupMenuItem(value: 'block', child: Text(l.t('rvBlock'))),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          RatingIcons(
              rating: r.stars.toDouble(), size: 16, kind: widget.kind),
          if (r.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                r.comment,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: AppColors.bluNotte,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Foglio per scrivere o modificare la propria recensione: voto (1-5 icone
/// da toccare) e commento facoltativo.
class _ReviewEditor extends StatefulWidget {
  final String entityType;
  final String entityId;
  final RatingKind kind;
  final ReviewModel? existing;
  final String publicName;

  const _ReviewEditor({
    required this.entityType,
    required this.entityId,
    required this.kind,
    required this.existing,
    required this.publicName,
  });

  @override
  State<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<_ReviewEditor> {
  late int _stars = widget.existing?.stars ?? 0;
  late final _comment =
      TextEditingController(text: widget.existing?.comment ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l) async {
    if (_stars == 0 || _saving) return;
    setState(() => _saving = true);
    try {
      await ReviewService.save(
        entityType: widget.entityType,
        entityId: widget.entityId,
        stars: _stars,
        comment: _comment.text,
        existingId: widget.existing?.id,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.t('rvSaveError'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    return Padding(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grigioChiaro,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.t(widget.existing == null ? 'rvWrite' : 'rvEditMine'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.bluNotte,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.t('rvYourRating'),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _stars = i),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 12, 4),
                      child: RatingIcon(
                        kind: widget.kind,
                        size: 32,
                        filled: i <= _stars,
                      ),
                    ),
                  ),
              ],
            ),
            if (_stars == 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.t('rvSelectStars'),
                  style:
                      const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _comment,
              maxLines: 5,
              minLines: 3,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l.t('rvCommentHint'),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.grigioChiaro),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.grigioChiaro),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.rossoGubbio),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.public_rounded,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.fmt('rvPublicNote', {'name': widget.publicName}),
                    style: const TextStyle(
                        fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _stars == 0 || _saving ? null : () => _save(l),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rossoGubbio,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(
                        l.t('rvPublish'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
