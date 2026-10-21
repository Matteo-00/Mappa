import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/consent_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import 'login_page.dart';

/// Prima schermata per un nuovo utente: informativa privacy e condizioni d'uso.
/// Tutti i testi sono tradotti (it / en / de / fr) e la lingua si può cambiare
/// già da qui, prima di accettare.
class PrivacyConsentPage extends StatefulWidget {
  const PrivacyConsentPage({super.key});

  @override
  State<PrivacyConsentPage> createState() => _PrivacyConsentPageState();
}

class _PrivacyConsentPageState extends State<PrivacyConsentPage> {
  bool _privacyRead = false;
  bool _termsAccepted = false;
  bool _saving = false;

  Future<void> _continue() async {
    if (!_privacyRead || !_termsAccepted || _saving) return;

    setState(() => _saving = true);

    await ConsentService.setPrivacyAccepted();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);

    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.rossoGubbio,
                    size: 40,
                  ),
                  const Spacer(),
                  const _LanguagePicker(),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                l10n.t('csTitle'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluNotte,
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.t('csIntro'),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.bluNotte,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _Bullet(
                        title: l10n.t('csRegTitle'),
                        text: l10n.t('csRegText'),
                      ),

                      _Bullet(
                        title: l10n.t('csPosTitle'),
                        text: l10n.t('csPosText'),
                      ),

                      _Bullet(
                        title: l10n.t('csPlacesTitle'),
                        text: l10n.t('csPlacesText'),
                      ),

                      _Bullet(
                        title: 'Supabase',
                        text: l10n.t('csSupabaseText'),
                      ),

                      _Bullet(
                        title: 'Google Maps',
                        text: l10n.t('csMapsText'),
                      ),

                      _Bullet(
                        title: l10n.t('csRightsTitle'),
                        text: l10n.t('csRightsText'),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        '${l10n.t('csPolicyLabel')}\n'
                        'https://visitgubbio.eu/privacy-policy.html\n\n'
                        '${l10n.t('csTermsLabel')}\n'
                        'https://visitgubbio.eu/terms.html',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textMuted,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        l10n.t('csLocationOptional'),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.rossoGubbio,
                value: _privacyRead,
                onChanged: (v) {
                  setState(() => _privacyRead = v ?? false);
                },
                title: Text(
                  l10n.t('csCheckPrivacy'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.bluNotte,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.rossoGubbio,
                value: _termsAccepted,
                onChanged: (v) {
                  setState(() => _termsAccepted = v ?? false);
                },
                title: Text(
                  l10n.t('csCheckTerms'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.bluNotte,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      _privacyRead && _termsAccepted && !_saving
                          ? _continue
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rossoGubbio,
                    disabledBackgroundColor:
                        AppColors.rossoGubbio.withOpacity(0.35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          l10n.t('csContinue'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Selettore della lingua (bandiera + menu) per cambiare lingua prima di
/// accettare l'informativa.
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  static const _languages = [
    ('it', '🇮🇹', 'Italiano'),
    ('en', '🇬🇧', 'English'),
    ('de', '🇩🇪', 'Deutsch'),
    ('fr', '🇫🇷', 'Français'),
  ];

  @override
  Widget build(BuildContext context) {
    final service = context.watch<LanguageService>();
    final current = _languages.firstWhere(
      (l) => l.$1 == service.currentLanguageCode,
      orElse: () => _languages.first,
    );

    return PopupMenuButton<String>(
      tooltip: 'Language',
      onSelected: service.setLanguage,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (_) => [
        for (final lang in _languages)
          PopupMenuItem<String>(
            value: lang.$1,
            child: Row(
              children: [
                Text(lang.$2, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Text(lang.$3),
                if (lang.$1 == service.currentLanguageCode) ...[
                  const Spacer(),
                  const Icon(Icons.check_rounded,
                      size: 18, color: AppColors.rossoGubbio),
                ],
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.grigioChiaro),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(current.$2, style: const TextStyle(fontSize: 20)),
            const Icon(Icons.arrow_drop_down_rounded,
                color: AppColors.bluNotte),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String title;
  final String text;

  const _Bullet({
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.rossoGubbio,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.bluNotte,
            ),
          ),
        ],
      ),
    );
  }
}
