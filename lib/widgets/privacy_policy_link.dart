import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

/// URL pubblico dell'informativa sulla privacy, mostrato nello Store e
/// richiamato da qui. Aggiorna solo questa costante se l'indirizzo cambia.
const String kPrivacyPolicyUrl = 'https://visitgubbio.eu/privacy-policy.html';

/// URL pubblico dei termini e condizioni d'uso, mostrato nello Store e
/// richiamato da qui. Aggiorna solo questa costante se l'indirizzo cambia.
const String kTermsOfUseUrl = 'https://visitgubbio.eu/terms.html';

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Riga con i link discreti a Privacy Policy e Termini e Condizioni d'uso,
/// da mostrare nelle schermate di login e registrazione come richiesto
/// dalle policy di Google Play/App Store.
class LegalLinksRow extends StatelessWidget {
  final AppLocalizations l10n;

  const LegalLinksRow({super.key, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: Colors.grey[500],
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    const linkTextStyle =
        TextStyle(fontSize: 12, decoration: TextDecoration.underline);

    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: () => _openUrl(kPrivacyPolicyUrl),
            style: buttonStyle,
            child: Text(l10n.privacyPolicy, style: linkTextStyle),
          ),
          Text('•', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          TextButton(
            onPressed: () => _openUrl(kTermsOfUseUrl),
            style: buttonStyle,
            child: Text(l10n.termsOfUse, style: linkTextStyle),
          ),
        ],
      ),
    );
  }
}
