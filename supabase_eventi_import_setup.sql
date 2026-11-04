-- ============================================================
-- VISIT GUBBIO - IMPORTAZIONE AUTOMATICA EVENTI DAL COMUNE
-- ============================================================
-- Esegui questo script nel "SQL Editor" di Supabase, TUTTO IN UNA
-- VOLTA, DOPO aver creato la Edge Function "import-eventi"
-- (supabase/functions/import-eventi/index.ts).
--
-- Cosa fa:
--   1. Aggiunge alla tabella "eventi" le colonne per gli eventi
--      importati: stato (bozza / pubblicato), fonte, link alla fonte,
--      id dell'evento sul sito del Comune (per non importarlo due volte).
--   2. Le BOZZE le vedono solo gli admin: gli utenti vedono solo gli
--      eventi pubblicati.
--   3. Crea la tabella "import_eventi_stato" con l'indirizzo del feed
--      del Comune e l'esito dell'ultima importazione.
--   4. Programma l'importazione automatica OGNI GIORNO alle 05:00 UTC
--      (le 6:00 d'inverno, le 7:00 d'estate, ora italiana).
--
-- Lo script è ri-eseguibile senza errori.
-- ============================================================


-- ============================================================
-- 1. NUOVE COLONNE DEGLI EVENTI
-- ============================================================

ALTER TABLE public.eventi
  ADD COLUMN IF NOT EXISTS stato TEXT NOT NULL DEFAULT 'pubblicato',
  ADD COLUMN IF NOT EXISTS fonte TEXT,
  ADD COLUMN IF NOT EXISTS fonte_id TEXT,
  ADD COLUMN IF NOT EXISTS fonte_url TEXT,
  ADD COLUMN IF NOT EXISTS date_da_verificare BOOLEAN NOT NULL DEFAULT false;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'eventi_stato_check' AND conrelid = 'public.eventi'::regclass
  ) THEN
    ALTER TABLE public.eventi
      ADD CONSTRAINT eventi_stato_check CHECK (stato IN ('bozza', 'pubblicato'));
  END IF;
END $$;

-- Lo stesso evento del Comune non viene importato due volte
-- (gli eventi inseriti a mano hanno fonte_id vuoto: non sono toccati)
CREATE UNIQUE INDEX IF NOT EXISTS idx_eventi_fonte_id
  ON public.eventi(fonte_id);


-- ============================================================
-- 2. LE BOZZE LE VEDONO SOLO GLI ADMIN
-- ============================================================

DROP POLICY IF EXISTS "read_eventi" ON public.eventi;
CREATE POLICY "read_eventi" ON public.eventi
  FOR SELECT TO authenticated
  USING (stato = 'pubblicato' OR public.is_admin());


-- ============================================================
-- 3. IMPOSTAZIONI ED ESITO DELL'IMPORTAZIONE
-- ============================================================
-- Una sola riga (id = 1).
--   feed_url: indirizzo del feed degli eventi del Comune. Se è vuoto la
--             funzione prova da sola gli indirizzi più comuni.
--   pubblica_subito: true = gli eventi con le date sicure compaiono
--             subito nell'app; quelli con date incerte restano BOZZE da
--             controllare. false = tutti gli eventi importati restano
--             bozze finché un admin non li pubblica.
--   importa_immagini: true = usa la foto dell'evento del Comune.

CREATE TABLE IF NOT EXISTS public.import_eventi_stato (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  feed_url TEXT,
  pubblica_subito BOOLEAN NOT NULL DEFAULT true,
  importa_immagini BOOLEAN NOT NULL DEFAULT true,
  ultimo_avvio TIMESTAMP WITH TIME ZONE,
  ultimo_esito JSONB
);

INSERT INTO public.import_eventi_stato (id) VALUES (1)
  ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.import_eventi_stato ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_read_import_stato" ON public.import_eventi_stato;
DROP POLICY IF EXISTS "admin_update_import_stato" ON public.import_eventi_stato;

CREATE POLICY "admin_read_import_stato" ON public.import_eventi_stato
  FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY "admin_update_import_stato" ON public.import_eventi_stato
  FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());


-- ============================================================
-- 4. PAROLA SEGRETA PER L'AVVIO AUTOMATICO
-- ============================================================
-- Viene generata da sola e salvata nel Vault di Supabase: serve perché
-- solo il programma automatico (o un admin) possa avviare l'importazione.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM vault.secrets WHERE name = 'import_eventi_secret') THEN
    PERFORM vault.create_secret(
      encode(gen_random_bytes(24), 'hex'),
      'import_eventi_secret',
      'Avvio automatico importazione eventi'
    );
  END IF;
END $$;

-- La funzione "import-eventi" controlla la parola segreta con questa
-- funzione (chiamabile solo dal server, non dall'app).
CREATE OR REPLACE FUNCTION public.verifica_segreto_import(segreto TEXT)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM vault.decrypted_secrets
    WHERE name = 'import_eventi_secret' AND decrypted_secret = segreto
  );
$$;

REVOKE ALL ON FUNCTION public.verifica_segreto_import(TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.verifica_segreto_import(TEXT) TO service_role;


-- ============================================================
-- 5. AVVIO AUTOMATICO OGNI GIORNO
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'import-eventi-comune') THEN
    PERFORM cron.unschedule('import-eventi-comune');
  END IF;
END $$;

SELECT cron.schedule(
  'import-eventi-comune',
  '0 5 * * *',
  $cron$
  SELECT net.http_post(
    url := 'https://kcoglivbakjyxszoruka.supabase.co/functions/v1/import-eventi',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      -- chiave pubblica dell'app (la stessa di lib/main.dart)
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtjb2dsaXZiYWtqeXhzem9ydWthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNDA0NTcsImV4cCI6MjA4ODYxNjQ1N30.ICFTE2V6Y62BjT2gagazjLvyW8RZIZUji_D575hC5sY',
      'x-import-secret', (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'import_eventi_secret'
      )
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  );
  $cron$
);
