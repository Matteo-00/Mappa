-- ============================================================
-- VISIT GUBBIO - AGGIORNAMENTI DATABASE (da eseguire una volta)
-- ============================================================
-- Esegui TUTTO nel "SQL Editor" di Supabase. Si può rilanciare senza errori.
--
-- 1) Agriturismi: nella tabella "luoghi" il tipo "agriturismo" deve essere
--    ammesso.
-- 2) Storia di Gubbio: aggiunge le colonne della posizione (latitudine e
--    longitudine), che servono per poter modificare e salvare un contenuto
--    ("could not find the 'latitudine' column ... in the schema cache").
-- 3) Ricarica la cache dello schema di Supabase, così le novità si vedono subito.
-- ============================================================

-- 1) Tipi ammessi in "luoghi" (aggiunge 'agriturismo')
ALTER TABLE public.luoghi
  DROP CONSTRAINT IF EXISTS luoghi_tipo_check;

ALTER TABLE public.luoghi
  ADD CONSTRAINT luoghi_tipo_check
  CHECK (tipo IN ('chiesa', 'museo', 'negozio', 'parcheggio', 'agriturismo'));

-- 2) Posizione dei contenuti di Storia di Gubbio
ALTER TABLE public.storia_contenuti
  ADD COLUMN IF NOT EXISTS latitudine DOUBLE PRECISION;

ALTER TABLE public.storia_contenuti
  ADD COLUMN IF NOT EXISTS longitudine DOUBLE PRECISION;

-- 3) Aggiorna la cache dello schema (PostgREST)
NOTIFY pgrst, 'reload schema';
