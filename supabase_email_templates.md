# Email di Supabase in 4 lingue (conferma registrazione e recupero password)

Le email di conferma e di recupero password **le invia Supabase**, non l'app:
il testo si imposta nella dashboard. L'app salva la lingua scelta dall'utente
(`lang`: `it`, `en`, `de`, `fr`) nei suoi dati su Supabase, alla registrazione e
a ogni accesso. Il modello sceglie quindi la lingua giusta.

Grafica: la stessa dell'email di conferma che già usi (intestazione blu notte,
pulsante rosso Gubbio, piè di pagina avorio).

## Dove si imposta
Supabase → **Authentication → Emails** → apri il modello → cancella tutto,
incolla il codice qui sotto → **Save**.

Note:
- Un utente che non ha ancora `lang` (registrato prima dell'aggiornamento e non
  ancora rientrato nell'app) riceve l'email in **italiano**.
- L'**oggetto** (Subject) resta uno solo (es. "Visit Gubbio"): se la tua versione
  di Supabase lo permette puoi usare la stessa condizione, altrimenti lascialo neutro.

---

## 1) Modello "Confirm signup" (conferma registrazione)

Oggetto suggerito: `Visit Gubbio ✉️`

```html
<div style="background-color:#e5e1db; padding:32px 16px; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px; margin:0 auto; background-color:#ffffff; border-radius:16px; overflow:hidden;">
    <tr>
      <td style="background-color:#162b3d; padding:28px 32px; text-align:center;">
        <span style="color:#ffffff; font-size:18px; font-weight:700; letter-spacing:0.3px;">Visit Gubbio</span>
      </td>
    </tr>

    <tr>
      <td style="padding:36px 32px 28px; text-align:center;">
        {{ if eq .Data.lang "en" }}
          <h2 style="margin:0 0 12px; color:#162b3d; font-size:20px; font-weight:700;">Confirm your email address</h2>
          <p style="margin:0 0 24px; color:#8c857d; font-size:14px; line-height:1.6;">
            Thank you for signing up to Visit Gubbio. Tap the button below to confirm your email address and complete your account registration.
          </p>
          <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#b13b2e; color:#ffffff; text-decoration:none; font-size:15px; font-weight:700; padding:14px 32px; border-radius:10px;">Confirm email</a>
          <p style="margin:28px 0 0; color:#8c857d; font-size:12.5px; line-height:1.6;">If you did not create a Visit Gubbio account, you can safely ignore this email.</p>

        {{ else if eq .Data.lang "de" }}
          <h2 style="margin:0 0 12px; color:#162b3d; font-size:20px; font-weight:700;">Bestätige deine E-Mail-Adresse</h2>
          <p style="margin:0 0 24px; color:#8c857d; font-size:14px; line-height:1.6;">
            Danke für deine Registrierung bei Visit Gubbio. Tippe auf die Schaltfläche unten, um deine E-Mail-Adresse zu bestätigen und die Registrierung deines Kontos abzuschließen.
          </p>
          <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#b13b2e; color:#ffffff; text-decoration:none; font-size:15px; font-weight:700; padding:14px 32px; border-radius:10px;">E-Mail bestätigen</a>
          <p style="margin:28px 0 0; color:#8c857d; font-size:12.5px; line-height:1.6;">Wenn du kein Visit-Gubbio-Konto erstellt hast, kannst du diese E-Mail unbesorgt ignorieren.</p>

        {{ else if eq .Data.lang "fr" }}
          <h2 style="margin:0 0 12px; color:#162b3d; font-size:20px; font-weight:700;">Confirmez votre adresse e-mail</h2>
          <p style="margin:0 0 24px; color:#8c857d; font-size:14px; line-height:1.6;">
            Merci de vous être inscrit à Visit Gubbio. Appuyez sur le bouton ci-dessous pour confirmer votre adresse e-mail et finaliser l'inscription de votre compte.
          </p>
          <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#b13b2e; color:#ffffff; text-decoration:none; font-size:15px; font-weight:700; padding:14px 32px; border-radius:10px;">Confirmer l'e-mail</a>
          <p style="margin:28px 0 0; color:#8c857d; font-size:12.5px; line-height:1.6;">Si vous n'avez pas créé de compte Visit Gubbio, vous pouvez ignorer cet e-mail en toute sécurité.</p>

        {{ else }}
          <h2 style="margin:0 0 12px; color:#162b3d; font-size:20px; font-weight:700;">Conferma il tuo indirizzo email</h2>
          <p style="margin:0 0 24px; color:#8c857d; font-size:14px; line-height:1.6;">
            Grazie per esserti registrato a Visit Gubbio. Clicca sul pulsante qui sotto per confermare il tuo indirizzo email e completare la registrazione del tuo account.
          </p>
          <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#b13b2e; color:#ffffff; text-decoration:none; font-size:15px; font-weight:700; padding:14px 32px; border-radius:10px;">Conferma email</a>
          <p style="margin:28px 0 0; color:#8c857d; font-size:12.5px; line-height:1.6;">Se non hai creato tu un account Visit Gubbio, puoi ignorare questa email in tutta sicurezza.</p>
        {{ end }}
      </td>
    </tr>

    <tr>
      <td style="padding:20px 32px; text-align:center; background-color:#f7f4ef;">
        <span style="color:#8c857d; font-size:11.5px;">Visit Gubbio · Scopri. Vivi. Ricorda.</span>
      </td>
    </tr>
  </table>
</div>
```

---

## 2) Modello "Reset password" (recupero password)

Oggetto suggerito: `Visit Gubbio 🔑`

```html
<div style="background-color:#e5e1db; padding:32px 16px; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px; margin:0 auto; background-color:#ffffff; border-radius:16px; overflow:hidden;">
    <tr>
      <td style="background-color:#162b3d; padding:28px 32px; text-align:center;">
        <span style="color:#ffffff; font-size:18px; font-weight:700; letter-spacing:0.3px;">Visit Gubbio</span>
      </td>
    </tr>

    <tr>
      <td style="padding:36px 32px 28px; text-align:center;">
        {{ if eq .Data.lang "en" }}
          <h2 style="margin:0 0 12px; color:#162b3d; font-size:20px; font-weight:700;">Reset your password</h2>
          <p style="margin:0 0 24px; color:#8c857d; font-size:14px; line-height:1.6;">
            We received a request to reset the password of your Visit Gubbio account. Tap the button below to choose a new one.
          </p>
          <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#b13b2e; color:#ffffff; text-decoration:none; font-size:15px; font-weight:700; padding:14px 32px; border-radius:10px;">Reset password</a>
          <p style="margin:28px 0 0; color:#8c857d; font-size:12.5px; line-height:1.6;">The link expires shortly. If you did not request this, you can safely ignore this email: your password will not change.</p>

        {{ else if eq .Data.lang "de" }}
          <h2 style="margin:0 0 12px; color:#162b3d; font-size:20px; font-weight:700;">Passwort zurücksetzen</h2>
          <p style="margin:0 0 24px; color:#8c857d; font-size:14px; line-height:1.6;">
            Wir haben eine Anfrage zum Zurücksetzen des Passworts deines Visit-Gubbio-Kontos erhalten. Tippe auf die Schaltfläche unten, um ein neues zu wählen.
          </p>
          <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#b13b2e; color:#ffffff; text-decoration:none; font-size:15px; font-weight:700; padding:14px 32px; border-radius:10px;">Passwort zurücksetzen</a>
          <p style="margin:28px 0 0; color:#8c857d; font-size:12.5px; line-height:1.6;">Der Link läuft in Kürze ab. Wenn du das nicht angefordert hast, ignoriere diese E-Mail einfach: dein Passwort bleibt unverändert.</p>

        {{ else if eq .Data.lang "fr" }}
          <h2 style="margin:0 0 12px; color:#162b3d; font-size:20px; font-weight:700;">Réinitialisez votre mot de passe</h2>
          <p style="margin:0 0 24px; color:#8c857d; font-size:14px; line-height:1.6;">
            Nous avons reçu une demande de réinitialisation du mot de passe de votre compte Visit Gubbio. Appuyez sur le bouton ci-dessous pour en choisir un nouveau.
          </p>
          <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#b13b2e; color:#ffffff; text-decoration:none; font-size:15px; font-weight:700; padding:14px 32px; border-radius:10px;">Réinitialiser le mot de passe</a>
          <p style="margin:28px 0 0; color:#8c857d; font-size:12.5px; line-height:1.6;">Le lien expire bientôt. Si vous n'êtes pas à l'origine de cette demande, ignorez simplement cet e-mail : votre mot de passe ne changera pas.</p>

        {{ else }}
          <h2 style="margin:0 0 12px; color:#162b3d; font-size:20px; font-weight:700;">Reimposta la tua password</h2>
          <p style="margin:0 0 24px; color:#8c857d; font-size:14px; line-height:1.6;">
            Abbiamo ricevuto una richiesta per reimpostare la password del tuo account Visit Gubbio. Clicca sul pulsante qui sotto per sceglierne una nuova.
          </p>
          <a href="{{ .ConfirmationURL }}" style="display:inline-block; background-color:#b13b2e; color:#ffffff; text-decoration:none; font-size:15px; font-weight:700; padding:14px 32px; border-radius:10px;">Reimposta password</a>
          <p style="margin:28px 0 0; color:#8c857d; font-size:12.5px; line-height:1.6;">Il link scade tra breve. Se non hai richiesto tu questa operazione, puoi ignorare questa email in tutta sicurezza: la tua password non cambierà.</p>
        {{ end }}
      </td>
    </tr>

    <tr>
      <td style="padding:20px 32px; text-align:center; background-color:#f7f4ef;">
        <span style="color:#8c857d; font-size:11.5px;">Visit Gubbio · Scopri. Vivi. Ricorda.</span>
      </td>
    </tr>
  </table>
</div>
```

---

## Pagine web collegate
Dopo aver toccato il pulsante l'utente arriva su `https://visitgubbio.eu/confirm-email.html`
(e per il recupero password su `reset-password.html`). Quelle pagine sono sul sito,
non nell'app: se vuoi che siano multilingua vanno tradotte lì.
