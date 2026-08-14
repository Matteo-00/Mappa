-- ============================================================
-- VISIT GUBBIO - CONFIGURAZIONE ADMIN + CONTENUTI
-- ============================================================
-- Esegui questo script nel "SQL Editor" di Supabase.
-- Aggiunge il ruolo utente (admin/utente), le tabelle dei
-- contenuti (ristoranti, bar, eventi, itinerari), le policy
-- di sicurezza (RLS) e il bucket per le immagini.
-- ============================================================


-- ============================================================
-- 1. RUOLO UTENTE (admin / utente)
-- ============================================================

-- Aggiunge la colonna "ruolo" alla tabella utenti.
-- Ogni nuovo iscritto parte come 'utente'.
ALTER TABLE public.utenti
  ADD COLUMN IF NOT EXISTS ruolo TEXT NOT NULL DEFAULT 'utente';

-- Aggiorna il trigger di creazione utente per impostare il ruolo di default.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.utenti (id, nome, cognome, email, ruolo)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'nome', ''),
    COALESCE(new.raw_user_meta_data->>'cognome', ''),
    new.email,
    'utente'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Funzione helper: true se l'utente collegato è admin.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.utenti
    WHERE id = auth.uid() AND ruolo = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;


-- ============================================================
-- 2. TABELLE CONTENUTI
-- ============================================================

-- Ristoranti
CREATE TABLE IF NOT EXISTS public.ristoranti (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  descrizione TEXT NOT NULL DEFAULT '',
  indirizzo TEXT NOT NULL DEFAULT '',
  latitudine DOUBLE PRECISION NOT NULL DEFAULT 43.3519,
  longitudine DOUBLE PRECISION NOT NULL DEFAULT 12.5773,
  image_url TEXT,
  telefono TEXT,
  sito_web TEXT,
  tags TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Bar (stessi campi dei ristoranti)
CREATE TABLE IF NOT EXISTS public.bar (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome TEXT NOT NULL,
  descrizione TEXT NOT NULL DEFAULT '',
  indirizzo TEXT NOT NULL DEFAULT '',
  latitudine DOUBLE PRECISION NOT NULL DEFAULT 43.3519,
  longitudine DOUBLE PRECISION NOT NULL DEFAULT 12.5773,
  image_url TEXT,
  telefono TEXT,
  sito_web TEXT,
  tags TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Eventi
CREATE TABLE IF NOT EXISTS public.eventi (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titolo TEXT NOT NULL,
  descrizione TEXT NOT NULL DEFAULT '',
  luogo TEXT NOT NULL DEFAULT '',
  latitudine DOUBLE PRECISION NOT NULL DEFAULT 43.3519,
  longitudine DOUBLE PRECISION NOT NULL DEFAULT 12.5773,
  image_url TEXT,
  telefono TEXT,
  sito_web TEXT,
  data_inizio TIMESTAMP WITH TIME ZONE NOT NULL,
  data_fine TIMESTAMP WITH TIME ZONE NOT NULL,
  categoria TEXT NOT NULL DEFAULT 'Eventi',
  tags TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Itinerari (le tappe sono salvate come JSON)
CREATE TABLE IF NOT EXISTS public.itinerari (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titolo TEXT NOT NULL,
  sottotitolo TEXT NOT NULL DEFAULT '',
  descrizione TEXT NOT NULL DEFAULT '',
  durata TEXT NOT NULL DEFAULT '',
  difficolta TEXT NOT NULL DEFAULT '',
  tema TEXT NOT NULL DEFAULT '',
  image_url TEXT,
  tappe JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);


-- ============================================================
-- 3. ROW LEVEL SECURITY (RLS)
-- Lettura: tutti gli utenti autenticati.
-- Scrittura/Modifica/Cancellazione: solo admin.
-- ============================================================

DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['ristoranti', 'bar', 'eventi', 'itinerari'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY;', t);

    -- Rimuove eventuali policy preesistenti (rende lo script ri-eseguibile)
    EXECUTE format('DROP POLICY IF EXISTS "read_%1$s" ON public.%1$I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "admin_insert_%1$s" ON public.%1$I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "admin_update_%1$s" ON public.%1$I;', t);
    EXECUTE format('DROP POLICY IF EXISTS "admin_delete_%1$s" ON public.%1$I;', t);

    -- Lettura: chiunque sia autenticato
    EXECUTE format(
      'CREATE POLICY "read_%1$s" ON public.%1$I FOR SELECT TO authenticated USING (true);',
      t
    );
    -- Inserimento: solo admin
    EXECUTE format(
      'CREATE POLICY "admin_insert_%1$s" ON public.%1$I FOR INSERT TO authenticated WITH CHECK (public.is_admin());',
      t
    );
    -- Modifica: solo admin
    EXECUTE format(
      'CREATE POLICY "admin_update_%1$s" ON public.%1$I FOR UPDATE TO authenticated USING (public.is_admin()) WITH CHECK (public.is_admin());',
      t
    );
    -- Cancellazione: solo admin
    EXECUTE format(
      'CREATE POLICY "admin_delete_%1$s" ON public.%1$I FOR DELETE TO authenticated USING (public.is_admin());',
      t
    );
  END LOOP;
END $$;


-- ============================================================
-- 4. STORAGE (immagini dei contenuti)
-- Bucket pubblico in lettura, scrittura solo admin.
-- ============================================================

-- Crea il bucket "immagini" (pubblico in lettura)
INSERT INTO storage.buckets (id, name, public)
VALUES ('immagini', 'immagini', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "immagini_read" ON storage.objects;
DROP POLICY IF EXISTS "immagini_admin_insert" ON storage.objects;
DROP POLICY IF EXISTS "immagini_admin_update" ON storage.objects;
DROP POLICY IF EXISTS "immagini_admin_delete" ON storage.objects;

-- Lettura pubblica delle immagini del bucket
CREATE POLICY "immagini_read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'immagini');

-- Solo admin possono caricare
CREATE POLICY "immagini_admin_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'immagini' AND public.is_admin());

-- Solo admin possono aggiornare
CREATE POLICY "immagini_admin_update"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'immagini' AND public.is_admin());

-- Solo admin possono eliminare
CREATE POLICY "immagini_admin_delete"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'immagini' AND public.is_admin());


-- ============================================================
-- 5. COME RENDERE UN UTENTE AMMINISTRATORE
-- ============================================================
-- Dopo che l'utente si è registrato normalmente dall'app,
-- esegui questa query sostituendo l'email con quella giusta:
--
--   UPDATE public.utenti
--   SET ruolo = 'admin'
--   WHERE email = 'tua-email@esempio.com';
--
-- Per riportarlo a utente normale:
--
--   UPDATE public.utenti
--   SET ruolo = 'utente'
--   WHERE email = 'tua-email@esempio.com';
--
-- Verifica:
--   SELECT email, ruolo FROM public.utenti;
-- ============================================================
