import 'package:flutter/material.dart';
import '../services/consent_service.dart';
import '../theme/app_colors.dart';
import 'login_page.dart';

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
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Icon(
                Icons.privacy_tip_outlined,
                color: AppColors.rossoGubbio,
                size: 40,
              ),

              const SizedBox(height: 16),

              const Text(
                'Privacy e condizioni d\'uso',
                style: TextStyle(
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
                    children: const [
                      Text(
                        'Prima di utilizzare Visit Gubbio, ti forniamo alcune '
                        'informazioni essenziali sul trattamento dei dati personali '
                        'e sulle condizioni di utilizzo dell\'App.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.bluNotte,
                        ),
                      ),

                      SizedBox(height: 16),

                      _Bullet(
                        title: 'Dati di registrazione',
                        text:
                            'Per creare e gestire il tuo account trattiamo nome, '
                            'cognome ed email. Le credenziali sono gestite dal '
                            'sistema di autenticazione e la password non viene '
                            'memorizzata in chiaro.',
                      ),

                      _Bullet(
                        title: 'Posizione',
                        text:
                            'Se autorizzi la localizzazione, la posizione viene '
                            'utilizzata per mostrarti sulla mappa e individuare '
                            'luoghi vicini. Visit Gubbio non memorizza la posizione '
                            'del tuo dispositivo nel proprio database.',
                      ),

                      _Bullet(
                        title: 'Luoghi, attività ed eventi',
                        text:
                            'Gli amministratori inseriscono manualmente informazioni, '
                            'immagini e coordinate di ristoranti, bar, eventi e altri '
                            'punti di interesse. Le coordinate salvate riguardano '
                            'i luoghi e non la posizione degli utenti.',
                      ),

                      _Bullet(
                        title: 'Supabase',
                        text:
                            'Visit Gubbio utilizza Supabase per autenticazione, '
                            'database e archiviazione nell\'ambito '
                            'dell\'infrastruttura tecnica.',
                      ),

                      _Bullet(
                        title: 'Google Maps',
                        text:
                            'L\'App utilizza Google Maps per mostrare mappe e '
                            'contenuti cartografici. Google può trattare alcuni '
                            'dati tecnici secondo le proprie condizioni e '
                            'la propria Privacy Policy.',
                      ),

                      _Bullet(
                        title: 'Cancellazione e diritti',
                        text:
                            'Puoi cancellare il tuo account dalla sezione Profilo '
                            '→ "Elimina il mio account" e puoi esercitare i diritti '
                            'previsti dal GDPR scrivendo a '
                            'visitgubbioapp@gmail.com.',
                      ),

                      SizedBox(height: 10),

                      Text(
                        'Informativa completa:\n'
                        'https://visitgubbio.eu/privacy-policy.html\n\n'
                        'Termini e Condizioni:\n'
                        'https://visitgubbio.eu/terms.html',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textMuted,
                        ),
                      ),

                      SizedBox(height: 12),

                      Text(
                        'Il permesso di localizzazione è facoltativo e viene '
                        'richiesto separatamente quando utilizzi le funzioni '
                        'che ne hanno bisogno.',
                        style: TextStyle(
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
                title: const Text(
                  'Ho preso visione dell\'Informativa sulla Privacy',
                  style: TextStyle(
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
                title: const Text(
                  'Accetto i Termini e Condizioni d\'Uso',
                  style: TextStyle(
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
                      : const Text(
                          'Continua',
                          style: TextStyle(
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