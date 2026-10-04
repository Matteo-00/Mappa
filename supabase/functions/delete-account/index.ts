// Supabase Edge Function: delete-account
//
// Elimina DEFINITIVAMENTE l'account dell'utente che chiama la funzione:
// - rimuove il profilo dalla tabella "utenti"
// - rimuove l'utente da Supabase Auth (auth.users), così non potrà più
//   accedere né registrarsi di nuovo con la stessa email usando le vecchie
//   credenziali.
//
// La service role key NON deve mai finire nell'app: resta solo qui, come
// variabile d'ambiente della funzione lato server.
//
// Deploy (richiede Supabase CLI):
//   supabase functions deploy delete-account
//
// La funzione usa automaticamente SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY,
// già disponibili di default nell'ambiente delle Edge Function.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Header Authorization mancante' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // Client con i privilegi dell'utente chiamante: serve solo per
    // verificare in modo sicuro chi è l'utente autenticato dal token.
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userResult, error: userError } = await callerClient.auth.getUser();
    if (userError || !userResult?.user) {
      return new Response(
        JSON.stringify({ error: 'Sessione non valida o scaduta' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    const userId = userResult.user.id;

    // Client con service role: unico modo per cancellare un utente da Auth.
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    // Cancella il profilo (ridondante se la tabella ha ON DELETE CASCADE su
    // auth.users, ma esplicito per sicurezza).
    await adminClient.from('utenti').delete().eq('id', userId);

    const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);
    if (deleteError) {
      return new Response(
        JSON.stringify({ error: deleteError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
