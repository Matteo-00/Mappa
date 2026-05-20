# 🔧 Configurazione Supabase - Guida Completa

## 📋 Problema Riscontrato

Errore durante la registrazione con status 429 o errori CORS. Ecco come risolvere definitivamente.

## ✅ 1. Configurazione Authentication

### Disabilita Email Confirmation (per sviluppo)

1. Vai su **Supabase Dashboard** → https://app.supabase.com
2. Seleziona il tuo progetto
3. Vai su **Authentication** → **Settings**
4. Trova **"Enable email confirmations"**
5. **DISABILITA** questa opzione
6. Clicca **Save**

### Configurazione Email (opzionale per produzione)

Se vuoi abilitare l'email confirmation in produzione:
1. **Authentication** → **Email Templates**
2. Configura i template per:
   - Confirm signup
   - Reset password
3. Aggiungi il tuo domino in **Authentication** → **URL Configuration** → **Redirect URLs**

## ✅ 2. Aggiorna Schema Database

Esegui questo SQL nel **SQL Editor** di Supabase:

```sql
-- Elimina la vecchia tabella se esiste
DROP TABLE IF EXISTS utenti CASCADE;

-- Crea la nuova tabella utenti semplificata
CREATE TABLE utenti (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome TEXT NOT NULL,
  cognome TEXT NOT NULL,
  data_nascita TIMESTAMPTZ,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Abilita Row Level Security
ALTER TABLE utenti ENABLE ROW LEVEL SECURITY;

-- Policy per lettura (solo il proprio profilo)
CREATE POLICY "Users can read own profile"
ON utenti
FOR SELECT
USING (auth.uid() = id);

-- Policy per inserimento (durante registrazione)
CREATE POLICY "Users can insert own profile"
ON utenti
FOR INSERT
WITH CHECK (auth.uid() = id);

-- Policy per aggiornamento (solo il proprio profilo)
CREATE POLICY "Users can update own profile"
ON utenti
FOR UPDATE
USING (auth.uid() = id);

-- Policy per eliminazione (solo il proprio profilo)
CREATE POLICY "Users can delete own profile"
ON utenti
FOR DELETE
USING (auth.uid() = id);

-- Crea indice per performance
CREATE INDEX idx_utenti_email ON utenti(email);
```

## ✅ 3. Configurazione Rate Limiting

Se ricevi errori 429 (Too Many Requests):

1. **Authentication** → **Rate Limits**
2. Aumenta i limiti per sviluppo:
   - **Email signups**: 100/hour
   - **Password resets**: 100/hour
   - **Verifications**: 100/hour

⚠️ **IMPORTANTE**: In produzione, riporta questi valori a limiti più bassi per sicurezza.

## ✅ 4. Configurazione CORS (opzionale per web)

Se stai sviluppando per web:

1. Vai su **Storage** → **Buckets** (anche se non usi storage)
2. Oppure configura CORS nelle **Project Settings** → **API**
3. Aggiungi `http://localhost:*` ai **Allowed Origins**

## ✅ 5. Verifica le Credenziali nell'App

Controlla che in `lib/main.dart` ci siano:

```dart
await Supabase.initialize(
  url: 'https://jqvsfnkypvnjymrnubdv.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxdnNmbmt5cHZuanltcm51YmR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI1NDc2NzIsImV4cCI6MjA4ODEyMzY3Mn0.l0QlcFdwZhrhgxollQ1F-n2bTmQTwhtGWilw_EBdZZo',
);
```

✅ Le credenziali sono già configurate correttamente!

## 🧪 6. Test della Configurazione

### Test 1: Registrazione

1. Apri l'app in emulatore/dispositivo
2. Clicca su **"Registrati"**
3. Compila i campi:
   - Nome: Mario
   - Cognome: Rossi
   - Data di nascita: 01/01/2000
   - Email: mario.rossi@example.com
   - Password: Test123!
   - Conferma password: Test123!
4. Clicca **"Registrati"**

**Risultato atteso**: Messaggio "Registrazione completata! Effettua il login."

### Test 2: Login

1. Inserisci email e password appena create
2. Clicca **"Accedi"**

**Risultato atteso**: Accesso alla home page

### Test 3: Password Dimenticata

1. Clicca su **"Password dimenticata?"**
2. Inserisci email
3. Clicca **"Invia Link"**

**Risultato atteso**: Messaggio "Link di recupero inviato!"

## 🔍 7. Risoluzione Problemi Comuni

### Errore: "Email already in use"

✅ **Soluzione**: L'email è già registrata. Usa un'altra email o fai login.

### Errore: "Too many requests" (429)

✅ **Soluzioni**:
1. Aumenta rate limits su Supabase (vedi punto 3)
2. Aspetta 5-10 minuti prima di riprovare
3. Verifica che non ci siano loop di richieste nel codice

### Errore: "Row Level Security policy violation"

✅ **Soluzione**: Esegui nuovamente lo script SQL del punto 2 per ricreare le policy.

### Errore: "Invalid email or password"

✅ **Soluzioni**:
1. Verifica che l'email sia corretta
2. Controlla che la password abbia minimo 6 caratteri
3. Se hai appena registrato, aspetta qualche secondo

### Errore: "Email not confirmed"

✅ **Soluzione**: Disabilita email confirmation (vedi punto 1)

## 📊 8. Verifica Dati su Supabase

1. **Table Editor** → **utenti**
2. Dovresti vedere i dati inseriti:
   - id (UUID)
   - nome
   - cognome
   - data_nascita
   - email
   - created_at

3. **Authentication** → **Users**
4. Dovresti vedere gli utenti registrati con email

## 🎯 9. Checklist Finale

- [ ] Email confirmation disabilitata
- [ ] Tabella `utenti` creata con nuovi campi
- [ ] Row Level Security e Policy configurate
- [ ] Rate limits aumentati (sviluppo)
- [ ] Credenziali corrette in `main.dart`
- [ ] Test registrazione OK
- [ ] Test login OK
- [ ] Test password dimenticata OK

## 🚀 10. Deploy in Produzione

Quando sei pronto per il deploy:

1. **Abilita** email confirmation
2. **Riduci** rate limits
3. Configura **redirect URLs** per reset password
4. Abilita **MFA** (Multi-Factor Authentication) se necessario
5. Monitora i log in **Logs** → **Auth Logs**

---

✅ **Tutto configurato!** Il sistema di autenticazione è ora completamente funzionale.
