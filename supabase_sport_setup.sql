-- ============================================================
-- Sezione "Sport" (impianti sportivi, stessa struttura delle botteghe)
-- Da eseguire nell'SQL Editor di Supabase. Si può rieseguire.
-- ============================================================

-- 1) Nuovo tipo ammesso in "luoghi"
ALTER TABLE public.luoghi
  DROP CONSTRAINT IF EXISTS luoghi_tipo_check;

ALTER TABLE public.luoghi
  ADD CONSTRAINT luoghi_tipo_check
  CHECK (tipo IN ('chiesa', 'museo', 'negozio', 'sport', 'parcheggio', 'agriturismo', 'ascensore', 'bagno'));

-- 2) Ricarica la cache dello schema
NOTIFY pgrst, 'reload schema';
