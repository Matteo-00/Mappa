import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

/// URL pubblico dell'informativa sulla privacy, mostrato nello Store e
/// richiamato da qui. Aggiorna solo questa costante se l'indirizzo cambia.
const String kPrivacyPolicyUrl = 'https://visitgubbio.eu/privacy-policy.html';

/// Link discreto all'informativa sulla privacy, da mostrare nelle schermate
/// di login e registrazione come richiesto dalle policy di Google Play/App Store.
class PrivacyPolicyLink extends StatelessWidget {
  final AppLocalizations l10n;

  const PrivacyPolicyLink({super.key, required this.l10n});

  Future<void> _open() async {
    final uri = Uri.parse(kPrivacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: _open,
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey[500],
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          l10n.privacyPolicy,
          style: const TextStyle(fontSize: 12, decoration: TextDecoration.underline),
        ),
      ),
    );
  }
}
