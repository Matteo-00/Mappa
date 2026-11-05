-- ============================================================
-- VISIT GUBBIO - ORARI DELL'IMPORTAZIONE EVENTI
-- ============================================================
-- Esegui questo script nel "SQL Editor" di Supabase, TUTTO IN UNA
-- VOLTA, DOPO supabase_eventi_import_setup.sql e DOPO aver ripubblicato
-- la funzione "import-eventi" (nuova versione).
--
-- Cosa cambia:
--   - ore 11:00 (ora italiana): importa da solo gli eventi nuovi del
--     Comune, che arrivano come BOZZE;
--   - fino alle 13:00 puoi modificarli, pubblicarli o eliminarli
--     dall'app (Eventi > bozze);
--   - ore 13:00 (ora italiana): le bozze che nessuno ha toccato
--     vengono PUBBLICATE così come sono (e tradotte).
--
-- Gli orari seguono l'ora italiana anche col cambio ora legale/solare:
-- il programma parte a entrambi gli orari UTC possibili e agisce solo
-- quando in Italia sono davvero le 11 (o le 13).
-- Lo script è ri-eseguibile senza errori.
-- ============================================================

-- Le nuove importazioni restano sempre bozze
UPDATE public.import_eventi_stato SET pubblica_subito = false WHERE id = 1;

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'import-eventi-comune') THEN
    PERFORM cron.unschedule('import-eventi-comune');
  END IF;
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'pubblica-eventi-comune') THEN
    PERFORM cron.unschedule('pubblica-eventi-comune');
  END IF;
END $$;

-- 11:00 italiane = 10:00 UTC (inverno) o 09:00 UTC (estate)
SELECT cron.schedule(
  'import-eventi-comune',
  '0 9,10 * * *',
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
  )
  WHERE extract(hour FROM (now() AT TIME ZONE 'Europe/Rome')) = 11;
  $cron$
);

-- 13:00 italiane = 12:00 UTC (inverno) o 11:00 UTC (estate)
SELECT cron.schedule(
  'pubblica-eventi-comune',
  '0 11,12 * * *',
  $cron$
  SELECT net.http_post(
    url := 'https://kcoglivbakjyxszoruka.supabase.co/functions/v1/import-eventi',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtjb2dsaXZiYWtqeXhzem9ydWthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNDA0NTcsImV4cCI6MjA4ODYxNjQ1N30.ICFTE2V6Y62BjT2gagazjLvyW8RZIZUji_D575hC5sY',
      'x-import-secret', (
        SELECT decrypted_secret FROM vault.decrypted_secrets
        WHERE name = 'import_eventi_secret'
      )
    ),
    body := '{"azione": "pubblica"}'::jsonb,
    timeout_milliseconds := 60000
  )
  WHERE extract(hour FROM (now() AT TIME ZONE 'Europe/Rome')) = 13;
  $cron$
);
