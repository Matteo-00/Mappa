# 🚨 Risoluzione Errore 429 - Too Many Requests

## Problema
Quando provi a registrarti, ricevi l'errore:
```
POST https://jqvsfnkypvnjymrnubdv.supabase.co/auth/v1/signup? 429 (Too Many Requests)
```

## ❗ Causa
Supabase ha **limiti di rate** (numero massimo di richieste per periodo) per:
- Prevenire spam
- Proteggere il servizio
- Limitazioni del piano gratuito

Hai fatto troppe registrazioni in poco tempo.

---

## ✅ SOLUZIONE RAPIDA

### 1. Aspetta 5-10 Minuti ⏱️
Il limite si resetta automaticamente dopo qualche minuto. Semplicemente **aspetta** e riprova.

### 2. Configura Supabase per Sviluppo 🛠️

Vai su **https://supabase.com/dashboard** e accedi al tuo progetto.

#### A. Disabilita Email Confirmation (Sviluppo)

1. Vai su **Authentication** → **Settings** (nella sidebar)
2. Scorri fino a **Email Auth**
3. **Disabilita** "Enable email confirmations"
4. Clicca **Save**

Questo permette di testare senza dover verificare ogni email.

#### B. Disabilita o Configura CAPTCHA

**Opzione 1 - Disabilita (Più semplice per sviluppo)**
1. Vai su **Authentication** → **Settings**
2. Scorri fino a **Security and Protection**
3. **Disabilita** "Enable Captcha protection"
4. Clicca **Save**

**Opzione 2 - Configura reCAPTCHA v3 (Per produzione)**
1. Vai su [Google reCAPTCHA](https://www.google.com/recaptcha/admin)
2. Crea un nuovo sito con reCAPTCHA v3
3. Ottieni **Site Key** e **Secret Key**
4. In Supabase: **Authentication** → **Settings** → **Security and Protection**
5. Inserisci le chiavi reCAPTCHA
6. Abilita "Enable Captcha protection"

#### C. Controlla Rate Limits

1. Vai su **Project Settings** (icona ingranaggio in basso)
2. Clicca su **API Settings**
3. Guarda la sezione **Rate Limits**
4. Verifica i limiti del tuo piano

**Piano Gratuito tipicamente:**
- 60 richieste/minuto per IP
- 20 registrazioni/ora

---

## 🔧 Cosa Ho Corretto nel Codice

Ho migliorato la gestione errori in:
- **register_page.dart**: Mostra messaggi chiari per errore 429
- **login_page.dart**: Gestisce meglio gli errori di autenticazione

Ora quando ricevi l'errore 429, vedrai:
```
Troppe richieste! Attendi 5-10 minuti e riprova.
Supabase ha limiti di rate per prevenire spam.
```

---

## 📋 Checklist Configurazione Supabase

Per un ambiente di sviluppo ottimale:

- [ ] Email Confirmation: **DISABILITATA**
- [ ] CAPTCHA Protection: **DISABILITATA** (o configurata)
- [ ] Verificato Rate Limits
- [ ] Tabella `utenti` creata con RLS
- [ ] Policy configurate correttamente

---

## 🧪 Test Dopo Configurazione

1. **Aspetta 10 minuti** dall'ultimo tentativo fallito
2. **Riavvia l'app** con `flutter run`
3. Prova a **registrarti con una NUOVA email** (non quella già usata)
4. Se funziona, prova il **login**

---

## 🐛 Altri Possibili Errori

### "Email already registered"
L'email è già stata usata. Usa il login invece di registrarti di nuovo.

### "Invalid email"
Controlla che l'email sia nel formato corretto: `nome@dominio.com`

### "Weak password"
La password deve avere:
- Minimo 8 caratteri
- 1 maiuscola
- 1 numero
- 1 carattere speciale (!@#$%^&*)

### "Network error"
Controlla la connessione internet.

---

## 📊 Monitoraggio su Supabase

Per vedere cosa sta succedendo:

1. **Logs**: Vai su **Logs** → **Auth Logs**
2. Vedrai tutti i tentativi di registrazione/login
3. Controlla gli errori in dettaglio

---

## 🚀 Per Produzione

Quando metti l'app in produzione:

1. ✅ **Riabilita** Email Confirmation
2. ✅ **Configura** reCAPTCHA v3
3. ✅ Considera **upgrade** a piano a pagamento per rate limits più alti
4. ✅ Implementa **retry logic** nel codice per gestire rate limits
5. ✅ Aggiungi **logging** per monitorare errori

---

## 💡 Tips

- Durante sviluppo, usa **poche email di test** (es: test1@test.com, test2@test.com)
- Non fare **registrazioni ripetute** rapidamente
- Se stai testando, **elimina gli utenti** dal database tra i test
- Usa **hot reload** invece di riavviare l'app ogni volta

---

**Se il problema persiste dopo 10 minuti**, potrebbe essere un problema di configurazione Supabase. Controlla:
1. Che le **chiavi API** in main.dart siano corrette
2. Che il **progetto Supabase** sia attivo
3. I **logs di Supabase** per errori specifici
