# ⚡ QUICK START - LEGGI QUESTO PRIMA DI TUTTO

## 🔴 PROBLEMA CORRENTE: Registrazione non funziona

**CAUSA:** Manca la configurazione del database Supabase

---

## ✅ SOLUZIONE IN 3 PASSI:

### 1️⃣ CONFIGURA SUPABASE (5 minuti)

Apri: **[SETUP_SUPABASE_GUIDA.md](SETUP_SUPABASE_GUIDA.md)** ← Segui questa guida passo-passo

**In sintesi:**
- Vai su https://supabase.com/dashboard
- Apri **SQL Editor**
- Copia e incolla tutto da `supabase_setup.sql`
- Clicca **Run**
- Vai su **Authentication** → **Settings** → Disattiva "Confirm email"

### 2️⃣ AVVIA L'APP

```powershell
.\run.ps1
```

⚠️ **NON usare** `flutter run -d chrome` (darà errore!)

### 3️⃣ TESTA LA REGISTRAZIONE

1. Apri Chrome (si aprirà automaticamente)
2. Clicca "Registrati"
3. Compila: Nome, Cognome, Email, Password
4. Dovrebbe funzionare! ✅

---

## 🐛 Se hai problemi:

### "Email already in use"
→ Vai su Supabase → **Authentication** → **Users** → Cancella l'utente di test

### "Table utenti doesn't exist"  
→ Non hai eseguito lo script SQL. Torna al passo 1️⃣

### "Confirm email required"
→ Vai su **Authentication** → **Settings** → Disattiva "Confirm email" → **Save**

---

## 📁 File importanti:

- `SETUP_SUPABASE_GUIDA.md` ← Guida setup database
- `supabase_setup.sql` ← Script SQL da eseguire
- `run.ps1` ← Script per avviare l'app
- `COME_AVVIARE.md` ← Comandi durante sviluppo

---

## 🎯 Dopo aver configurato Supabase:

Tutto funzionerà:
- ✅ Registrazione
- ✅ Login  
- ✅ Password dimenticata
- ✅ Cambio lingua IT/EN
- ✅ Profilo utente

Buon lavoro! 🚀
