# 🚀 GUIDA SETUP SUPABASE - PASSO PER PASSO

## ⚠️ IMPORTANTE: Esegui questi passaggi IN ORDINE!

---

## 📝 STEP 1: Apri SQL Editor

1. Vai su **Supabase Dashboard**: https://supabase.com/dashboard
2. Seleziona il tuo progetto
3. Nel menu laterale, clicca su **SQL Editor**
4. Clicca **"+ New query"**

---

## 📋 STEP 2: Esegui lo script SQL

1. Apri il file `supabase_setup.sql` nella root del progetto
2. **Copia TUTTO il contenuto**
3. Incollalo nel SQL Editor di Supabase
4. Clicca **"Run"** (in basso a destra)

Dovresti vedere: ✅ **Success. No rows returned**

---

## 🔐 STEP 3: Disabilita conferma email

1. Nel menu laterale, vai su **Authentication**
2. Clicca su **Settings**  
3. Scorri fino a **"Email Auth"**
4. Trova **"Confirm email"**
5. **DISATTIVA** il toggle (deve essere GRIGIO/OFF)
6. Clicca **"Save"** in fondo alla pagina

---

## ✅ STEP 4: Verifica Email Provider

1. Sempre in **Authentication**
2. Clicca su **Providers**
3. Verifica che **Email** sia abilitato (toggle verde)
4. Se non lo è, cliccalo e attivalo

---

## 🧪 STEP 5: Verifica la tabella

1. Nel menu laterale, vai su **Table Editor**
2. Dovresti vedere la tabella **"utenti"**
3. Cliccala per vedere le colonne:
   - ✅ id (UUID)
   - ✅ nome (TEXT)
   - ✅ cognome (TEXT)
   - ✅ email (TEXT)
   - ✅ created_at (TIMESTAMP)

---

## 🔍 STEP 6: Verifica le Policy

1. Nel **Table Editor**, con la tabella "utenti" aperta
2. Clicca sul tab **"Policies"** in alto
3. Dovresti vedere 3 policy:
   - ✅ "Users can view own data"
   - ✅ "Users can insert own data"  
   - ✅ "Users can update own data"

---

## ✨ FATTO!

Ora puoi testare la registrazione:

1. Chiudi tutte le finestre di Chrome
2. Nel terminale, esegui: `.\run.ps1`
3. Vai alla pagina di registrazione
4. Compila il form e registrati!

---

## 🐛 Problemi?

### Errore "relation utenti does not exist"
→ Lo script SQL non è stato eseguito. Ripeti STEP 2

### Errore "permission denied"  
→ Le policy non sono attive. Verifica STEP 6

### Email già esistente
→ Vai su **Authentication** → **Users** e cancella l'utente di test

### Conferma email richiesta
→ Ripeti STEP 3 e assicurati di salvare

---

## 📞 Supporto

Se qualcosa non funziona:
1. Controlla la console di Chrome (F12)
2. Guarda gli errori nel terminale Flutter
3. Verifica i log in Supabase → **Logs** → **Error Logs**
