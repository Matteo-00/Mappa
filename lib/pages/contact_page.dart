import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';

/// Pagina "Contatti": un messaggio gentile, due inviti (collaborare, chiedere
/// aiuto) e l'indirizzo email di Visit Gubbio, da copiare o da aprire.
class ContactPage extends StatelessWidget {
  /// Indirizzo email di Visit Gubbio.
  static const String email = 'visitgubbioapp@gmail.com';

  const ContactPage({super.key});

  Future<void> _writeEmail(BuildContext context, String subject) async {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final uri =
        Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}');
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('contactCantOpen'))),
      );
    }
  }

  Future<void> _copyEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    await Clipboard.setData(const ClipboardData(text: email));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('contactCopied'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          PremiumHeader(title: l10n.t('menuContacts')),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _hero(l10n),
                const SizedBox(height: 18),
                _inviteCard(
                  emoji: '🤝',
                  color: const Color(0xFFFFF1E0),
                  title: l10n.t('contactJoinTitle'),
                  text: l10n.t('contactJoinText'),
                  button: l10n.t('contactWrite'),
                  onTap: () =>
                      _writeEmail(context, l10n.t('contactSubjectJoin')),
                ),
                const SizedBox(height: 14),
                _inviteCard(
                  emoji: '🙋',
                  color: const Color(0xFFE6F2EA),
                  title: l10n.t('contactHelpTitle'),
                  text: l10n.t('contactHelpText'),
                  button: l10n.t('contactWrite'),
                  onTap: () =>
                      _writeEmail(context, l10n.t('contactSubjectHelp')),
                ),
                const SizedBox(height: 14),
                _emailCard(context, l10n),
                const SizedBox(height: 22),
                Center(
                  child: Text(
                    l10n.t('contactThanks'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Saluto con tre omini sorridenti.
  Widget _hero(AppLocalizations l10n) {
    Widget face(String emoji, Color color, double size) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.tortora.withValues(alpha: 0.45),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                    offset: const Offset(-52, 8),
                    child: face('🙂', const Color(0xFFFFE9B8), 56)),
                Transform.translate(
                    offset: const Offset(52, 8),
                    child: face('😊', const Color(0xFFD7ECDD), 56)),
                face('👋', const Color(0xFFFFD9D2), 70),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.t('contactHello'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'serif',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: AppColors.bluNotte,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.t('contactIntro'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: AppColors.bluNotte,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inviteCard({
    required String emoji,
    required Color color,
    required String title,
    required String text,
    required String button,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: AppColors.bluNotte,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.5,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.mail_outline_rounded, size: 20),
              label: Text(button),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rossoGubbio,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle:
                    const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.bluNotte,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Text('✉️', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('contactEmailTitle'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                const SelectableText(
                  email,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _copyEmail(context),
            tooltip: l10n.t('contactCopy'),
            icon: const Icon(Icons.copy_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
