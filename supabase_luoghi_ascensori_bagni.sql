-- ============================================================
-- VISIT GUBBIO - ASCENSORI E BAGNI PUBBLICI
-- ============================================================
-- Da eseguire UNA volta nel "SQL Editor" di Supabase se la tabella
-- "luoghi" esiste già (creata con supabase_luoghi_setup.sql).
--
-- Aggiunge i tipi "ascensore" e "bagno" ai valori ammessi nella
-- colonna "tipo", così gli admin possono inserirli dall'app
-- (sezione "Info utili", accanto ai parcheggi).
-- Lo script è ri-eseguibile senza errori.
-- ============================================================

DO $$
DECLARE
  c TEXT;
BEGIN
  -- Rimuove il vecchio controllo sui tipi (qualunque sia il suo nome).
  FOR c IN
    SELECT conname FROM pg_constraint
    WHERE conrelid = 'public.luoghi'::regclass
      AND contype = 'c'
      AND pg_get_constraintdef(oid) ILIKE '%tipo%'
  LOOP
    EXECUTE format('ALTER TABLE public.luoghi DROP CONSTRAINT %I', c);
  END LOOP;
END $$;

ALTER TABLE public.luoghi
  ADD CONSTRAINT luoghi_tipo_check
  CHECK (tipo IN ('chiesa', 'museo', 'negozio', 'sport', 'parcheggio', 'agriturismo', 'ascensore', 'bagno'));
