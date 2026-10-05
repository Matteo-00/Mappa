// Supabase Edge Function: translate-content
//
// Traduce automaticamente un contenuto italiano (evento, ristorante, bar,
// itinerario, voce di storia) verso EN / FR / DE usando Azure Translator,
// e salva il risultato nella tabella `content_translations`.
//
// Richiesta protetta: può essere chiamata solo da un utente autenticato con
// ruolo 'admin' nella tabella `utenti`.
//
// Body atteso:
//   { "entity_type": "eventi" | "ristoranti" | "bar" | "itinerari" |
//                     "storia_epoche" | "storia_contenuti",
//     "entity_id": "<uuid>" }
//
// Variabili d'ambiente richieste (impostate su Supabase, mai nell'app):
//   SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
//   AZURE_TRANSLATOR_KEY, AZURE_TRANSLATOR_REGION
//   AZURE_TRANSLATOR_ENDPOINT (opzionale, default api.cognitive.microsofttranslator.com)
//
// Deploy:
//   supabase functions deploy translate-content

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const TARGET_LANGUAGES = ['en', 'fr', 'de'];

// Campi testuali traducibili per ogni tabella. Tutto il resto (id, date,
// coordinate, immagini, telefono, sito web, rating, ordinamento...) resta
// invariato e viene letto direttamente dalla tabella originale.
const TRANSLATABLE_FIELDS: Record<string, string[]> = {
  eventi: ['titolo', 'descrizione', 'luogo'],
  ristoranti: ['nome', 'descrizione'],
  bar: ['nome', 'descrizione'],
  itinerari: ['titolo', 'sottotitolo', 'descrizione'],
  storia_epoche: ['nome', 'periodo', 'descrizione'],
  storia_contenuti: [
    'title',
    'short_description',
    'full_description',
    'local_story',
    'curiosity',
  ],
};

// Campi array di stringhe traducibili (tradotti elemento per elemento).
const TRANSLATABLE_LIST_FIELDS: Record<string, string[]> = {
  storia_epoche: ['eventi_importanti'],
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

async function translateTexts(
  texts: string[],
  targetLang: string,
): Promise<string[]> {
  if (texts.length === 0) return [];

  const key = Deno.env.get('AZURE_TRANSLATOR_KEY');
  const region = Deno.env.get('AZURE_TRANSLATOR_REGION');
  const endpoint =
    Deno.env.get('AZURE_TRANSLATOR_ENDPOINT') ??
    'https://api.cognitive.microsofttranslator.com';

  if (!key || !region) {
    throw new Error('Azure Translator non configurato (manca key/region)');
  }

  const url = `${endpoint}/translate?api-version=3.0&from=it&to=${targetLang}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Ocp-Apim-Subscription-Key': key,
      'Ocp-Apim-Subscription-Region': region,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(texts.map((t) => ({ Text: t }))),
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Azure Translator error ${res.status}: ${errText}`);
  }

  const data = await res.json();
  return data.map((item: any) => item?.translations?.[0]?.text ?? '');
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'Header Authorization mancante' }, 401);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // Verifica identità del chiamante con i suoi privilegi.
    const callerClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userResult, error: userError } =
      await callerClient.auth.getUser();
    if (userError || !userResult?.user) {
      return jsonResponse({ error: 'Sessione non valida o scaduta' }, 401);
    }

    // Client con service role per leggere/scrivere senza vincoli RLS, ma
    // solo dopo aver verificato che l'utente è admin.
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: profile, error: profileError } = await adminClient
      .from('utenti')
      .select('ruolo')
      .eq('id', userResult.user.id)
      .single();

    if (profileError || profile?.ruolo !== 'admin') {
      return jsonResponse({ error: 'Utente non autorizzato' }, 403);
    }

    const body = await req.json().catch(() => null);
    const entityType = body?.entity_type as string | undefined;
    const entityId = body?.entity_id as string | undefined;

    if (!entityType || !entityId) {
      return jsonResponse(
        { error: 'Parametri entity_type / entity_id mancanti' },
        400,
      );
    }

    const fields = TRANSLATABLE_FIELDS[entityType];
    if (!fields) {
      return jsonResponse(
        { error: `entity_type non supportato: ${entityType}` },
        400,
      );
    }

    const { data: row, error: rowError } = await adminClient
      .from(entityType)
      .select()
      .eq('id', entityId)
      .single();

    if (rowError || !row) {
      return jsonResponse({ error: 'Record non trovato' }, 404);
    }

    const listFields = TRANSLATABLE_LIST_FIELDS[entityType] ?? [];
    const results: Record<string, { ok: boolean; error?: string }> = {};

    for (const lang of TARGET_LANGUAGES) {
      try {
        const scalarValues = fields.map((f) => (row[f] ?? '').toString());
        const translatedScalars = await translateTexts(scalarValues, lang);

        const content: Record<string, unknown> = {};
        fields.forEach((f, i) => {
          content[f] = translatedScalars[i];
        });

        for (const listField of listFields) {
          const items: string[] = Array.isArray(row[listField])
            ? row[listField]
            : [];
          content[listField] = items.length
            ? await translateTexts(items, lang)
            : [];
        }

        const { error: upsertError } = await adminClient
          .from('content_translations')
          .upsert(
            {
              entity_type: entityType,
              entity_id: entityId,
              language_code: lang,
              content,
            },
            { onConflict: 'entity_type,entity_id,language_code' },
          );

        if (upsertError) throw upsertError;
        results[lang] = { ok: true };
      } catch (err) {
        results[lang] = { ok: false, error: (err as Error).message };
      }
    }

    const anyFailed = Object.values(results).some((r) => !r.ok);
    return jsonResponse({ success: !anyFailed, results }, anyFailed ? 207 : 200);
  } catch (err) {
    return jsonResponse({ error: (err as Error).message }, 500);
  }
});
