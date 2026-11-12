-- ============================================================
-- VISIT GUBBIO - LINK FACOLTATIVO NEI PARCHEGGI
-- ============================================================
-- Esegui questo script nel "SQL Editor" di Supabase, TUTTO IN UNA
-- VOLTA, PRIMA di salvare un parcheggio con titolo e link dall'app.
--
-- Aggiunge alla tabella "luoghi" due colonne facoltative usate solo dai
-- parcheggi: il titolo del link (es. "Prenota il posto") e il link.
-- Se restano vuote, nella scheda del parcheggio non si vede nulla.
-- Lo script è ri-eseguibile senza errori.
-- ============================================================

ALTER TABLE public.luoghi
  ADD COLUMN IF NOT EXISTS link_titolo TEXT,
  ADD COLUMN IF NOT EXISTS link_url TEXT;

-- Ricarica la cache dello schema, così le colonne si vedono subito
NOTIFY pgrst, 'reload schema';
