-- ============================================
-- CONFIGURAZIONE DATABASE SUPABASE
-- ============================================

-- 1. Crea la tabella utenti
CREATE TABLE IF NOT EXISTS public.utenti (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  nome TEXT NOT NULL,
  cognome TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Abilita Row Level Security
ALTER TABLE public.utenti ENABLE ROW LEVEL SECURITY;

-- 3. Elimina policy esistenti (se ci sono)
DROP POLICY IF EXISTS "Users can view own data" ON public.utenti;
DROP POLICY IF EXISTS "Users can insert own data" ON public.utenti;
DROP POLICY IF EXISTS "Users can update own data" ON public.utenti;

-- 4. Crea le policy di sicurezza

-- Policy: gli utenti possono leggere solo i propri dati
CREATE POLICY "Users can view own data"
  ON public.utenti
  FOR SELECT
  USING (auth.uid() = id);

-- Policy: gli utenti possono inserire solo i propri dati
CREATE POLICY "Users can insert own data"
  ON public.utenti
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Policy: gli utenti possono aggiornare solo i propri dati
CREATE POLICY "Users can update own data"
  ON public.utenti
  FOR UPDATE
  USING (auth.uid() = id);

-- 5. Crea trigger per inserire automaticamente dati utente (OPZIONALE)
-- Questo trigger crea automaticamente un record in utenti quando viene creato un account
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.utenti (id, nome, cognome, email)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'nome', ''),
    COALESCE(new.raw_user_meta_data->>'cognome', ''),
    new.email
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Crea il trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- VERIFICA INSTALLAZIONE
-- ============================================

-- Testa la tabella
SELECT * FROM public.utenti;

-- Verifica le policy
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename = 'utenti';
