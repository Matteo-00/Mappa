-- ============================================================
-- VISIT GUBBIO - EVENTI E NOTIZIE DAL COMUNE
-- ============================================================
-- Esegui questo script nel "SQL Editor" di Supabase, TUTTO IN UNA
-- VOLTA, PRIMA di ripubblicare la funzione "import-eventi" (nuova
-- versione).
--
-- Il Comune pubblica gli eventi tra le "Novità" del sito: l'importazione
-- ora prende TUTTE le novità e le divide in
--   - "evento":  ha una data futura (es. "Il 14 e 15 novembre") e non è
--                un avviso (viabilità, uffici, bandi...);
--   - "notizia": tutto il resto (data = data di pubblicazione).
-- Nell'app compaiono in due schede: Eventi e Notizie.
--
-- Gli eventi inseriti a mano restano "evento".
-- Lo script è ri-eseguibile senza errori.
-- ============================================================

ALTER TABLE public.eventi
  ADD COLUMN IF NOT EXISTS tipo TEXT NOT NULL DEFAULT 'evento';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'eventi_tipo_check' AND conrelid = 'public.eventi'::regclass
  ) THEN
    ALTER TABLE public.eventi
      ADD CONSTRAINT eventi_tipo_check CHECK (tipo IN ('evento', 'notizia'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_eventi_tipo ON public.eventi(tipo);
