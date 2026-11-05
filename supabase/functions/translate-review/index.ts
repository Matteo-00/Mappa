// Supabase Edge Function: translate-review
//
// Traduce il commento di una recensione nella lingua dell'app (tasto
// "Traduci" sotto le recensioni). Usa Azure Translator, come
// translate-content, riconoscendo da solo la lingua del commento.
//
// - Può chiamarla qualsiasi utente collegato.
// - La traduzione resta salvata in "recensioni_traduzioni": chi la chiede
//   dopo la riceve subito, senza una nuova chiamata ad Azure.
// - Se il commento è già nella lingua richiesta, torna "stessa_lingua".
//
// Richiede le stesse variabili di translate-content:
//   AZURE_TRANSLATOR_KEY, AZURE_TRANSLATOR_ENDPOINT, AZURE_TRANSLATOR_REGION
//
// Deploy:
//   supabase functions deploy translate-review

import { createClient } from "npm:@supabase/supabase-js@2";

const LANGUAGES = ["it", "en", "de", "fr"];

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const db = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // ------------------------------------------------ utente collegato
    const token = (req.headers.get("Authorization") ?? "")
      .replace(/^Bearer\s+/i, "");
    const { data: { user } } = await db.auth.getUser(token);
    if (!user) return jsonResponse({ error: "Utente non autenticato" }, 401);

    // ------------------------------------------------ parametri
    const body = await req.json();
    const reviewId = String(body.review_id ?? "");
    const lang = String(body.lang ?? "");
    if (!reviewId || !LANGUAGES.includes(lang)) {
      return jsonResponse({ error: "Parametri non validi" }, 400);
    }

    // ------------------------------------------------ già tradotta?
    const { data: cached } = await db.from("recensioni_traduzioni")
      .select("testo, lingua_originale")
      .eq("recensione_id", reviewId).eq("lingua", lang).maybeSingle();
    if (cached) {
      return jsonResponse({
        testo: cached.testo,
        lingua_originale: cached.lingua_originale,
        stessa_lingua: cached.lingua_originale === lang,
      });
    }

    const { data: review } = await db.from("recensioni")
      .select("commento").eq("id", reviewId).maybeSingle();
    const text = (review?.commento ?? "").trim();
    if (!text) return jsonResponse({ error: "Nessun commento" }, 404);

    // ------------------------------------------------ Azure Translator
    const azureKey = Deno.env.get("AZURE_TRANSLATOR_KEY");
    const azureEndpoint = Deno.env.get("AZURE_TRANSLATOR_ENDPOINT");
    const azureRegion = Deno.env.get("AZURE_TRANSLATOR_REGION");
    if (!azureKey || !azureEndpoint) {
      throw new Error("Azure Translator non configurato");
    }
    const url = new URL(`${azureEndpoint.replace(/\/$/, "")}/translate`);
    url.searchParams.set("api-version", "3.0");
    url.searchParams.set("to", lang); // lingua di partenza: la riconosce Azure

    const headers: Record<string, string> = {
      "Content-Type": "application/json",
      "Ocp-Apim-Subscription-Key": azureKey,
    };
    if (azureRegion) headers["Ocp-Apim-Subscription-Region"] = azureRegion;

    const res = await fetch(url.toString(), {
      method: "POST",
      headers,
      body: JSON.stringify([{ Text: text }]),
    });
    if (!res.ok) {
      console.error("Azure Translator:", await res.text());
      return jsonResponse({ error: "Traduzione non disponibile" }, 502);
    }
    const result = await res.json();
    const detected: string = result?.[0]?.detectedLanguage?.language ?? "";
    const translated: string = result?.[0]?.translations?.[0]?.text ?? text;
    const same = detected === lang;

    await db.from("recensioni_traduzioni").upsert({
      recensione_id: reviewId,
      lingua: lang,
      testo: same ? text : translated,
      lingua_originale: detected || null,
    });

    return jsonResponse({
      testo: same ? text : translated,
      lingua_originale: detected || null,
      stessa_lingua: same,
    });
  } catch (e) {
    console.error("translate-review:", e);
    return jsonResponse({ error: String((e as Error)?.message ?? e) }, 500);
  }
});
