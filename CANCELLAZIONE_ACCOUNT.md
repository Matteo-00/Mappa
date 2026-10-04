# Cancellazione account reale (richiesta da Google Play / App Store)

Google Play e App Store richiedono che l'utente possa cancellare **davvero**
il proprio account dall'app, non solo disconnettersi. "Davvero" significa:
email e password non più utilizzabili per accedere, oltre alla cancellazione
dei dati del profilo.

## Situazione prima di questa modifica

Il pulsante "Elimina il mio account" (in [user_profile_page.dart](lib/pages/user_profile_page.dart))
cancellava solo la riga della tabella `utenti`, ma lasciava intatto l'utente
dentro Supabase Auth: l'email restava "occupata" e tecnicamente l'account non
era mai stato eliminato per davvero.

## Cosa è stato aggiunto

Una Edge Function Supabase in [supabase/functions/delete-account/index.ts](supabase/functions/delete-account/index.ts)
che, chiamata dall'app già autenticata, cancella:
1. la riga utente dalla tabella `utenti`;
2. l'utente da `auth.users` (tramite `admin.deleteUser`, che richiede la
   service role key — per questo DEVE girare lato server e mai nell'app).

[auth_service.dart](lib/services/auth_service.dart) ora chiama questa funzione
con `supabase.functions.invoke('delete-account')` prima di disconnettere
l'utente. Se la funzione non è ancora distribuita, come fallback viene
cancellato solo il profilo (comportamento precedente) per non bloccare
l'utente: per la compliance completa la funzione va distribuita.

## Come distribuirla (una tantum)

Serve la [Supabase CLI](https://supabase.com/docs/guides/cli) installata e il
progetto collegato (`supabase login`, `supabase link --project-ref <ref>`).

```powershell
supabase functions deploy delete-account
```

Non serve impostare manualmente `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY`:
sono già disponibili automaticamente nell'ambiente delle Edge Function del
progetto.

## Verifica

1. Accedi nell'app con un account di test.
2. Vai su Profilo → "Elimina il mio account" → conferma.
3. Prova a rifare login con le stesse credenziali: deve fallire (utente non
   più esistente). Se riesci ad accedere, la funzione non è distribuita
   correttamente: controlla i log con `supabase functions logs delete-account`.
