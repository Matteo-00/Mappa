-- ============================================================
-- VISIT GUBBIO - CHIESE, MUSEI, NEGOZI E PARCHEGGI
-- ============================================================
-- Esegui questo script nel "SQL Editor" di Supabase, TUTTO IN UNA
-- VOLTA, dopo aver già eseguito supabase_admin_setup.sql (serve la
-- funzione public.is_admin()) e supabase_storia_setup.sql (serve la
-- funzione public.set_updated_at()).
--
-- Crea UNA sola tabella "luoghi" che contiene tutti e 4 i tipi
-- (colonna "tipo": chiesa, museo, negozio, parcheggio).
--   - chiese e musei: collegamenti a "Storia di Gubbio" (storia_ids)
--   - negozi: valutazione in stelle (rating)
--   - parcheggi: titolo, descrizione, indirizzo e posizione
--
-- RLS: lettura per tutti gli utenti autenticati, scrittura
-- (insert/update/delete) solo per gli ADMIN.
-- Lo script è ri-eseguibile senza errori.
-- ============================================================


-- ============================================================
-- 1. TABELLA
-- ============================================================

CREATE TABLE IF NOT EXISTS public.luoghi (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tipo TEXT NOT NULL CHECK (tipo IN ('chiesa', 'museo', 'negozio', 'parcheggio')),
  nome TEXT NOT NULL,
  descrizione TEXT NOT NULL DEFAULT '',
  indirizzo TEXT NOT NULL DEFAULT '',
  latitudine DOUBLE PRECISION NOT NULL DEFAULT 43.3519,
  longitudine DOUBLE PRECISION NOT NULL DEFAULT 12.5773,
  image_url TEXT,
  telefono TEXT,
  sito_web TEXT,
  tags TEXT[] NOT NULL DEFAULT '{}',
  rating NUMERIC(2,1),
  -- id dei contenuti di "Storia di Gubbio" collegati (solo chiese e musei)
  storia_ids JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_luoghi_tipo ON public.luoghi(tipo);

-- Aggiorna automaticamente updated_at ad ogni modifica
DROP TRIGGER IF EXISTS trg_luoghi_updated_at ON public.luoghi;
CREATE TRIGGER trg_luoghi_updated_at
  BEFORE UPDATE ON public.luoghi
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


-- ============================================================
-- 2. ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.luoghi ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "read_luoghi" ON public.luoghi;
DROP POLICY IF EXISTS "admin_insert_luoghi" ON public.luoghi;
DROP POLICY IF EXISTS "admin_update_luoghi" ON public.luoghi;
DROP POLICY IF EXISTS "admin_delete_luoghi" ON public.luoghi;

CREATE POLICY "read_luoghi" ON public.luoghi
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "admin_insert_luoghi" ON public.luoghi
  FOR INSERT TO authenticated WITH CHECK (public.is_admin());

CREATE POLICY "admin_update_luoghi" ON public.luoghi
  FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY "admin_delete_luoghi" ON public.luoghi
  FOR DELETE TO authenticated USING (public.is_admin());
