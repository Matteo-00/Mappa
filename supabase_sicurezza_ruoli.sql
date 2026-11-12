-- ============================================================
-- VISIT GUBBIO - SICUREZZA: IL RUOLO ADMIN NON SI PUÒ AUTOASSEGNARE
-- ============================================================
-- Esegui questo script nel "SQL Editor" di Supabase, TUTTO IN UNA
-- VOLTA, il prima possibile.
--
-- Il problema: la regola "Users can update own data" permetteva a ogni
-- utente di modificare la PROPRIA riga di "utenti" senza limiti sui
-- campi. Con la chiave pubblica dell'app (che chiunque può leggere) un
-- utente poteva quindi scrivere ruolo = 'admin' e diventare
-- amministratore, con accesso a tutte le funzioni di modifica.
--
-- La correzione:
--   1. un trigger impedisce di cambiare "ruolo" a chiunque non sia già
--      admin (il SQL Editor di Supabase e le Edge Function restano
--      liberi: lì si nominano gli admin);
--   2. chi crea la propria riga da app parte sempre come "utente";
--   3. la regola di modifica ora controlla anche la riga dopo la
--      modifica (WITH CHECK).
--
-- L'app non modifica mai la tabella "utenti": nessun cambiamento lato app.
-- Lo script è ri-eseguibile senza errori.
-- ============================================================


-- ============================================================
-- 1. IL RUOLO LO CAMBIANO SOLO GLI ADMIN (O IL SERVER)
-- ============================================================

CREATE OR REPLACE FUNCTION public.proteggi_ruolo_utenti()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Dall'app (utente collegato o anonimo): niente ruoli autoassegnati.
  -- Il SQL Editor (postgres) e le Edge Function (service_role) non passano
  -- da qui perché il loro ruolo non è "authenticated"/"anon".
  IF coalesce(auth.role(), '') IN ('authenticated', 'anon') THEN
    IF TG_OP = 'INSERT' THEN
      NEW.ruolo := 'utente';
    ELSIF NEW.ruolo IS DISTINCT FROM OLD.ruolo AND NOT public.is_admin() THEN
      RAISE EXCEPTION 'Non è permesso cambiare il ruolo'
        USING ERRCODE = '42501';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_proteggi_ruolo_utenti ON public.utenti;
CREATE TRIGGER trg_proteggi_ruolo_utenti
  BEFORE INSERT OR UPDATE ON public.utenti
  FOR EACH ROW EXECUTE FUNCTION public.proteggi_ruolo_utenti();


-- ============================================================
-- 2. REGOLE DELLA TABELLA UTENTI (con WITH CHECK)
-- ============================================================

DROP POLICY IF EXISTS "Users can insert own data" ON public.utenti;
CREATE POLICY "Users can insert own data"
  ON public.utenti FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own data" ON public.utenti;
CREATE POLICY "Users can update own data"
  ON public.utenti FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);


-- ============================================================
-- 3. CONTROLLO: CHI È ADMIN ADESSO?
-- ============================================================
-- Il risultato deve contenere SOLO gli amministratori che conosci.
-- Se c'è qualcuno che non dovrebbe esserci, riportalo a "utente":
--   UPDATE public.utenti SET ruolo = 'utente' WHERE email = '...';

SELECT email, nome, cognome, ruolo
FROM public.utenti
WHERE ruolo = 'admin'
ORDER BY email;
