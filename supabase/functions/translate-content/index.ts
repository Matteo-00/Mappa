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
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
//   AZURE_TRANSLATOR_KEY, AZURE_TRANSLATOR_ENDPOINT, AZURE_TRANSLATOR_REGION (opzionale)
//
// Deploy:
//   supabase functions deploy translate-content

import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const TARGET_LANGUAGES = ["en", "fr", "de"] as const;

type TargetLanguage = (typeof TARGET_LANGUAGES)[number];

const ENTITY_CONFIG: Record<
  string,
  {
    table: string;
    fields: string[];
  }
> = {
  ristoranti: {
    table: "ristoranti",
    fields: ["descrizione"],
  },

  bar: {
    table: "bar",
    fields: ["descrizione"],
  },

  eventi: {
    table: "eventi",
    fields: ["titolo", "descrizione"],
  },

  itinerari: {
    table: "itinerari",
    fields: [
      "titolo",
      "sottotitolo",
      "descrizione",
      "durata",
      "difficolta",
      "tema",
    ],
  },

  storia_epoche: {
    table: "storia_epoche",
    fields: [
      "nome",
      "periodo",
      "descrizione",
      "eventi_importanti",
    ],
  },

  storia_contenuti: {
    table: "storia_contenuti",
    fields: [
      "title",
      "display_date",
      "short_description",
      "full_description",
      "local_story",
      "curiosity",
    ],
  },
};

type TranslationItem = {
  field: string;
  text: string;
  index?: number;
};

function jsonResponse(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    // =====================================================
    // 1. AUTENTICAZIONE
    // =====================================================

    const authHeader = req.headers.get("Authorization");

    if (!authHeader) {
      return jsonResponse(
        { error: "Utente non autenticato" },
        401,
      );
    }

    const token = authHeader.replace(/^Bearer\s+/i, "");

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get(
      "SUPABASE_SERVICE_ROLE_KEY",
    );

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error(
        "Configurazione Supabase mancante",
      );
    }

    const supabaseAdmin = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    );

    const {
      data: { user },
      error: userError,
    } = await supabaseAdmin.auth.getUser(token);

    if (userError || !user) {
      return jsonResponse(
        { error: "Sessione utente non valida" },
        401,
      );
    }

    // =====================================================
    // 2. CONTROLLO RUOLO ADMIN
    // =====================================================

    const {
      data: utente,
      error: ruoloError,
    } = await supabaseAdmin
      .from("utenti")
      .select("ruolo")
      .eq("id", user.id)
      .single();

    if (ruoloError) {
      console.error(
        "Errore controllo ruolo:",
        ruoloError,
      );

      return jsonResponse(
        { error: "Impossibile verificare il ruolo" },
        500,
      );
    }

    if (utente?.ruolo !== "admin") {
      return jsonResponse(
        {
          error:
            "Solo gli amministratori possono generare traduzioni",
        },
        403,
      );
    }

    // =====================================================
    // 3. PARAMETRI
    // =====================================================

    const body = await req.json();

    const entityType = body.entity_type;
    const entityId = body.entity_id;

    if (!entityType || !entityId) {
      return jsonResponse(
        {
          error:
            "entity_type ed entity_id sono obbligatori",
        },
        400,
      );
    }

    const config = ENTITY_CONFIG[entityType];

    if (!config) {
      return jsonResponse(
        {
          error: `Tipo non supportato: ${entityType}`,
        },
        400,
      );
    }

    // =====================================================
    // 4. RECUPERA CONTENUTO ITALIANO
    // =====================================================

    const {
      data: sourceData,
      error: sourceError,
    } = await supabaseAdmin
      .from(config.table)
      .select("*")
      .eq("id", entityId)
      .single();

    if (sourceError || !sourceData) {
      console.error(
        "Errore recupero contenuto:",
        sourceError,
      );

      return jsonResponse(
        {
          error:
            "Contenuto italiano non trovato",
        },
        404,
      );
    }

    // =====================================================
    // 5. PREPARA I CAMPI DA TRADURRE
    // =====================================================

    const items: TranslationItem[] = [];

    for (const field of config.fields) {
      const value = sourceData[field];

      if (
        typeof value === "string" &&
        value.trim() !== ""
      ) {
        items.push({
          field,
          text: value,
        });
      }

      if (Array.isArray(value)) {
        value.forEach((element, index) => {
          if (
            typeof element === "string" &&
            element.trim() !== ""
          ) {
            items.push({
              field,
              text: element,
              index,
            });
          }
        });
      }
    }

    if (items.length === 0) {
      return jsonResponse({
        success: true,
        message: "Nessun testo da tradurre",
      });
    }

    // =====================================================
    // 6. AZURE TRANSLATOR
    // =====================================================

    const azureKey = Deno.env.get(
      "AZURE_TRANSLATOR_KEY",
    );

    const azureEndpoint =
      Deno.env.get("AZURE_TRANSLATOR_ENDPOINT");

    const azureRegion = Deno.env.get(
      "AZURE_TRANSLATOR_REGION",
    );

    if (!azureKey) {
      throw new Error(
        "AZURE_TRANSLATOR_KEY non configurata",
      );
    }

    if (!azureEndpoint) {
      throw new Error(
        "AZURE_TRANSLATOR_ENDPOINT non configurato",
      );
    }

    const endpoint = azureEndpoint.replace(
      /\/$/,
      "",
    );

    const url = new URL(
      `${endpoint}/translate`,
    );

    url.searchParams.set(
      "api-version",
      "3.0",
    );

    url.searchParams.set(
      "from",
      "it",
    );

    for (const language of TARGET_LANGUAGES) {
      url.searchParams.append(
        "to",
        language,
      );
    }

    const azureHeaders: Record<string, string> = {
      "Content-Type": "application/json",
      "Ocp-Apim-Subscription-Key": azureKey,
    };

    if (azureRegion) {
      azureHeaders[
        "Ocp-Apim-Subscription-Region"
      ] = azureRegion;
    }

    // Il tier gratuito di Azure Translator applica un limite di richieste
    // al secondo: in caso di 429 (rate limit) riproviamo con backoff
    // esponenziale invece di far fallire subito l'intera traduzione.
    const maxAttempts = 4;
    let azureResponse: Response | null = null;

    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      azureResponse = await fetch(
        url.toString(),
        {
          method: "POST",
          headers: azureHeaders,
          body: JSON.stringify(
            items.map((item) => ({
              Text: item.text,
            })),
          ),
        },
      );

      if (azureResponse.ok) break;

      const errorText = await azureResponse.clone().text();
      const isRateLimited =
        azureResponse.status === 429 ||
        errorText.includes("429001") ||
        errorText.includes("429000");

      if (isRateLimited && attempt < maxAttempts) {
        await sleep(attempt * 1500);
        continue;
      }

      console.error(
        "Azure Translator:",
        errorText,
      );

      return jsonResponse(
        {
          error:
            "Azure Translator ha restituito un errore",
          details: errorText,
        },
        502,
      );
    }

    const azureResult =
      await azureResponse!.json();

    // =====================================================
    // 7. RICOSTRUISCE I JSON TRADOTTI
    // =====================================================

    const translatedContent: Record<
      TargetLanguage,
      Record<string, unknown>
    > = {
      en: {},
      fr: {},
      de: {},
    };

    // Prepara eventuali campi ARRAY
    for (const field of config.fields) {
      if (Array.isArray(sourceData[field])) {
        for (const language of TARGET_LANGUAGES) {
          translatedContent[language][field] =
            [];
        }
      }
    }

    items.forEach((item, itemIndex) => {
      const azureItem =
        azureResult[itemIndex];

      if (!azureItem?.translations) {
        return;
      }

      for (const language of TARGET_LANGUAGES) {
        const translated =
          azureItem.translations.find(
            (translation: {
              text: string;
              to: string;
            }) =>
              translation.to === language,
          );

        if (!translated) {
          continue;
        }

        if (item.index !== undefined) {
          const array =
            translatedContent[language][
              item.field
            ] as string[];

          array[item.index] =
            translated.text;
        } else {
          translatedContent[language][
            item.field
          ] = translated.text;
        }
      }
    });

    // =====================================================
    // 8. SALVA EN / FR / DE
    // =====================================================

    const sourceUpdatedAt =
      sourceData.updated_at ??
      sourceData.created_at ??
      new Date().toISOString();

    for (const language of TARGET_LANGUAGES) {
      const {
        error: saveError,
      } = await supabaseAdmin
        .from("content_translations")
        .upsert(
          {
            entity_type: entityType,

            entity_id: entityId,

            language_code: language,

            content:
              translatedContent[language],

            source_updated_at:
              sourceUpdatedAt,

            updated_at:
              new Date().toISOString(),
          },
          {
            onConflict:
              "entity_type,entity_id,language_code",
          },
        );

      if (saveError) {
        console.error(
          `Errore salvataggio ${language}:`,
          saveError,
        );

        throw new Error(
          `Errore salvataggio traduzione ${language}: ${saveError.message}`,
        );
      }
    }

    // =====================================================
    // 9. RISPOSTA
    // =====================================================

    return jsonResponse({
      success: true,

      entity_type: entityType,

      entity_id: entityId,

      source_language: "it",

      translated_languages: [
        "en",
        "fr",
        "de",
      ],
    });
  } catch (error) {
    console.error(
      "translate-content error:",
      error,
    );

    return jsonResponse(
      {
        error:
          error instanceof Error
            ? error.message
            : "Errore sconosciuto",
      },
      500,
    );
  }
});
