# 🎯 CONFIGURAZIONE SUPABASE - VERSIONE SEMPLIFICATA

Se lo script completo `supabase_setup.sql` dà problemi, esegui questi comandi UNO ALLA VOLTA nel SQL Editor di Supabase.

---

## 📋 STEP 1: Crea la tabella utenti

```sql
CREATE TABLE public.utenti (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  nome TEXT NOT NULL,
  cognome TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

Clicca **Run**. Dovresti vedere: ✅ Success

---

## 🔐 STEP 2: Abilita Row Level Security

```sql
ALTER TABLE public.utenti ENABLE ROW LEVEL SECURITY;
```

Clicca **Run**. Dovresti vedere: ✅ Success

---

## 👀 STEP 3: Policy per leggere i propri dati

```sql
CREATE POLICY "Users can view own data"
  ON public.utenti
  FOR SELECT
  USING (auth.uid() = id);
```

Clicca **Run**. Dovresti vedere: ✅ Success

---

## ✍️ STEP 4: Policy per inserire i propri dati

```sql
CREATE POLICY "Users can insert own data"
  ON public.utenti
  FOR INSERT
  WITH CHECK (auth.uid() = id);
```

Clicca **Run**. Dovresti vedere: ✅ Success

---

## 🔄 STEP 5: Policy per aggiornare i propri dati

```sql
CREATE POLICY "Users can update own data"
  ON public.utenti
  FOR UPDATE
  USING (auth.uid() = id);
```

Clicca **Run**. Dovresti vedere: ✅ Success

---

## ✅ VERIFICA

Controlla che tutto sia stato creato:

```sql
SELECT * FROM public.utenti;
```

Dovresti vedere la struttura della tabella (anche se vuota).

---

## 🎉 FATTO!

Ora vai su:
- **Authentication** → **Settings** → Disattiva "Confirm email"
- Salva le modifiche
- Chiudi Supabase
- Avvia l'app con `.\run.ps1`
- Testa la registrazione!

---

## 🆘 PROBLEMI COMUNI

### "relation already exists"
→ La tabella è già stata creata. Vai direttamente allo step successivo.

### "permission denied"
→ Assicurati di essere admin del progetto Supabase.

### "syntax error"
→ Hai copiato il comando in modo errato. Copia di nuovo e assicurati di includere il punto e virgola finale.
