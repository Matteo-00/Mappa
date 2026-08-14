import 'package:flutter/material.dart';
import '../services/consent_service.dart';
import '../theme/app_colors.dart';
import 'login_page.dart';

/// Schermata di informativa privacy da accettare prima del login.
/// Viene mostrata una sola volta: una volta accettata non ricompare.
class PrivacyConsentPage extends StatefulWidget {
  const PrivacyConsentPage({super.key});

  @override
  State<PrivacyConsentPage> createState() => _PrivacyConsentPageState();
}

class _PrivacyConsentPageState extends State<PrivacyConsentPage> {
  bool _accepted = false;
  bool _saving = false;

  Future<void> _continue() async {
    if (!_accepted || _saving) return;
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
              Icon(Icons.privacy_tip_outlined,
                  color: AppColors.rossoGubbio, size: 40),
              const SizedBox(height: 16),
              const Text(
                'Informativa sulla privacy',
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
                        'Per usare Visit Gubbio raccogliamo alcuni dati personali. '
                        'Ti spieghiamo come li trattiamo:',
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
                            'Nome, cognome, email e password vengono salvati in modo '
                            'sicuro per creare e gestire il tuo account.',
                      ),
                      _Bullet(
                        title: 'Posizione',
                        text:
                            'Se acconsenti, usiamo la posizione del dispositivo solo '
                            'per mostrarti dove ti trovi sulla mappa e i punti di '
                            'interesse vicini. Non la salviamo sui nostri server.',
                      ),
                      _Bullet(
                        title: 'I tuoi diritti',
                        text:
                            'Puoi richiedere in qualsiasi momento l\'accesso, la '
                            'modifica o la cancellazione dei tuoi dati. I permessi '
                            'della posizione sono gestibili dalle impostazioni del '
                            'telefono.',
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Proseguendo dichiari di aver letto e compreso questa '
                        'informativa ai sensi del Regolamento (UE) 2016/679 (GDPR).',
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
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setState(() => _accepted = !_accepted),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _accepted,
                        activeColor: AppColors.rossoGubbio,
                        onChanged: (v) =>
                            setState(() => _accepted = v ?? false),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Ho letto e accetto l\'informativa sulla privacy',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.bluNotte,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _accepted && !_saving ? _continue : null,
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
                          'Accetta e continua',
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
  const _Bullet({required this.title, required this.text});

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
