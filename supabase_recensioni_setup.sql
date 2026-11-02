-- ============================================================
-- VISIT GUBBIO - RECENSIONI DEGLI UTENTI
-- ============================================================
-- Esegui questo script nel "SQL Editor" di Supabase, TUTTO IN UNA
-- VOLTA, dopo aver già eseguito supabase_setup.sql (tabella "utenti")
-- e supabase_admin_setup.sql (funzione public.is_admin()).
--
-- Crea:
--   - "recensioni": stelle (1-5) e commento degli utenti su
--     ristoranti, bar, hotel e itinerari. Il nome mostrato
--     ("Matteo R.") lo scrive il database dal profilo dell'utente,
--     così nessuno può firmarsi con il nome di un altro.
--   - "segnalazioni_recensioni": le segnalazioni di recensioni
--     offensive, visibili solo agli ADMIN.
--
-- RLS:
--   - recensioni: le leggono tutti gli utenti autenticati; ognuno
--     può scrivere UNA recensione per scheda e modificare/eliminare
--     solo la propria; gli admin possono eliminarle tutte.
--   - segnalazioni: ogni utente può segnalare (una volta per
--     recensione); solo gli admin le leggono e le eliminano.
--
-- Cancellazione account: recensioni e segnalazioni dell'utente si
-- cancellano da sole insieme all'account (ON DELETE CASCADE).
-- Lo script è ri-eseguibile senza errori.
-- ============================================================


-- ============================================================
-- 1. TABELLE
-- ============================================================

CREATE TABLE IF NOT EXISTS public.recensioni (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type TEXT NOT NULL
    CHECK (entity_type IN ('ristoranti', 'bar', 'hotel', 'itinerari')),
  entity_id TEXT NOT NULL,
  user_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Nome pubblico (es. "Matteo R."), impostato dal trigger qui sotto
  autore TEXT NOT NULL DEFAULT '',
  stelle SMALLINT NOT NULL CHECK (stelle BETWEEN 1 AND 5),
  commento TEXT NOT NULL DEFAULT '' CHECK (char_length(commento) <= 1000),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  -- Una sola recensione per utente su ogni scheda
  UNIQUE (entity_type, entity_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_recensioni_entity
  ON public.recensioni(entity_type, entity_id);

CREATE TABLE IF NOT EXISTS public.segnalazioni_recensioni (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recensione_id UUID NOT NULL
    REFERENCES public.recensioni(id) ON DELETE CASCADE,
  user_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  motivo TEXT NOT NULL DEFAULT '' CHECK (char_length(motivo) <= 500),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  -- Ogni utente segnala la stessa recensione una sola volta
  UNIQUE (recensione_id, user_id)
);


-- ============================================================
-- 2. AUTORE E DATA SCRITTI DAL DATABASE
-- ============================================================
-- L'autore è sempre l'utente collegato e il nome viene dal suo
-- profilo: "Nome" + iniziale del cognome.

CREATE OR REPLACE FUNCTION public.set_recensione_autore()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  n TEXT;
  c TEXT;
BEGIN
  NEW.user_id := auth.uid();
  SELECT trim(nome), trim(cognome) INTO n, c
    FROM public.utenti WHERE id = NEW.user_id;
  NEW.autore := trim(
    coalesce(n, '') ||
    CASE WHEN coalesce(c, '') <> '' THEN ' ' || upper(left(c, 1)) || '.' ELSE '' END
  );
  IF TG_OP = 'UPDATE' THEN
    -- Scheda e data di creazione non si possono cambiare
    NEW.entity_type := OLD.entity_type;
    NEW.entity_id := OLD.entity_id;
    NEW.created_at := OLD.created_at;
    NEW.updated_at := timezone('utc'::text, now());
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_recensioni_autore ON public.recensioni;
CREATE TRIGGER trg_recensioni_autore
  BEFORE INSERT OR UPDATE ON public.recensioni
  FOR EACH ROW EXECUTE FUNCTION public.set_recensione_autore();


-- ============================================================
-- 3. PULIZIA QUANDO UN ADMIN ELIMINA UNA SCHEDA
-- ============================================================
-- Eliminando un ristorante, bar, hotel o itinerario si eliminano
-- anche le sue recensioni.

CREATE OR REPLACE FUNCTION public.delete_recensioni_entity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.recensioni
   WHERE entity_type = TG_TABLE_NAME AND entity_id = OLD.id::text;
  RETURN OLD;
END;
$$;

DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['ristoranti', 'bar', 'hotel', 'itinerari'] LOOP
    IF to_regclass('public.' || t) IS NOT NULL THEN
      EXECUTE format('DROP TRIGGER IF EXISTS trg_%1$s_recensioni ON public.%1$I;', t);
      EXECUTE format(
        'CREATE TRIGGER trg_%1$s_recensioni AFTER DELETE ON public.%1$I '
        'FOR EACH ROW EXECUTE FUNCTION public.delete_recensioni_entity();', t);
    END IF;
  END LOOP;
END $$;


-- ============================================================
-- 4. RLS
-- ============================================================

ALTER TABLE public.recensioni ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.segnalazioni_recensioni ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "read_recensioni" ON public.recensioni;
DROP POLICY IF EXISTS "insert_own_recensione" ON public.recensioni;
DROP POLICY IF EXISTS "update_own_recensione" ON public.recensioni;
DROP POLICY IF EXISTS "delete_own_or_admin_recensione" ON public.recensioni;

CREATE POLICY "read_recensioni" ON public.recensioni
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "insert_own_recensione" ON public.recensioni
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "update_own_recensione" ON public.recensioni
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "delete_own_or_admin_recensione" ON public.recensioni
  FOR DELETE TO authenticated
  USING (user_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "insert_own_segnalazione" ON public.segnalazioni_recensioni;
DROP POLICY IF EXISTS "admin_read_segnalazioni" ON public.segnalazioni_recensioni;
DROP POLICY IF EXISTS "admin_delete_segnalazioni" ON public.segnalazioni_recensioni;

CREATE POLICY "insert_own_segnalazione" ON public.segnalazioni_recensioni
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "admin_read_segnalazioni" ON public.segnalazioni_recensioni
  FOR SELECT TO authenticated USING (public.is_admin());

CREATE POLICY "admin_delete_segnalazioni" ON public.segnalazioni_recensioni
  FOR DELETE TO authenticated USING (public.is_admin());
