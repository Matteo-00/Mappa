-- =====================================================================
-- content_translations
-- =====================================================================
-- Tabella unica che ospita le traduzioni automatiche (EN/FR/DE) di tutti
-- i contenuti dinamici inseriti dagli admin in italiano (eventi,
-- ristoranti, bar, itinerari, storia_epoche, storia_contenuti, ...).
--
-- Viene popolata esclusivamente dalla Edge Function `translate-content`.
-- L'app Flutter la legge in sola lettura per mostrare la versione
-- straniera dei contenuti, con fallback all'italiano se manca una riga.
-- =====================================================================

CREATE TABLE IF NOT EXISTS public.content_translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  language_code TEXT NOT NULL CHECK (language_code IN ('en', 'fr', 'de')),
  content JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (entity_type, entity_id, language_code)
);

CREATE INDEX IF NOT EXISTS idx_content_translations_lookup
  ON public.content_translations (entity_type, language_code, entity_id);

DROP TRIGGER IF EXISTS trg_content_translations_updated_at
  ON public.content_translations;
CREATE TRIGGER trg_content_translations_updated_at
  BEFORE UPDATE ON public.content_translations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.content_translations ENABLE ROW LEVEL SECURITY;

-- Lettura pubblica: le traduzioni seguono le stesse regole di visibilità
-- dei contenuti originali (tutti gli utenti autenticati/anonimi possono
-- leggere la versione tradotta già approvata dall'admin in italiano).
DROP POLICY IF EXISTS "read_content_translations" ON public.content_translations;
CREATE POLICY "read_content_translations" ON public.content_translations
  FOR SELECT USING (true);

-- Scrittura riservata al service role (usato solo dalla Edge Function
-- translate-content, mai dal client Flutter).
DROP POLICY IF EXISTS "service_write_content_translations" ON public.content_translations;
CREATE POLICY "service_write_content_translations" ON public.content_translations
  FOR ALL USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');
