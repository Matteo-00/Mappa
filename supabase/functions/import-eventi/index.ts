// Supabase Edge Function: import-eventi
//
// Importa in automatico gli eventi pubblicati sul sito del Comune di Gubbio
// (www.comune.gubbio.pg.it, piattaforma Municipium) leggendo il loro feed
// RSS, e li salva nella tabella "eventi".
//
// - Parte da sola ogni giorno alle 11:00 (programmata da supabase_eventi_orari.sql)
//   oppure quando un admin tocca "Importa ora" nell'app. Gli eventi importati
//   sono BOZZE; alle 13:00 quelle non toccate vengono pubblicate da sole
//   (chiamata con {"azione": "pubblica"}).
// - Un evento già importato non viene importato di nuovo (colonna fonte_id).
// - Ogni evento nuovo viene tradotto subito in EN/FR/DE (anche le bozze).
//   Con "pubblica_subito" attivo quelli con date sicure sono pubblicati
//   subito; gli altri restano BOZZE che l'admin controlla e pubblica.
// - Ogni evento indica la fonte e il link alla pagina originale del Comune.
//
// Impostazioni nella tabella "import_eventi_stato" (riga id = 1):
//   feed_url          indirizzo del feed; se vuoto lo cerca da sola
//   pubblica_subito   true/false
//   importa_immagini  true/false
//
// Deploy:
//   supabase functions deploy import-eventi

import { createClient } from "npm:@supabase/supabase-js@2";
import { XMLParser } from "npm:fast-xml-parser@4.4.1";

const SITE = "https://www.comune.gubbio.pg.it";
const SOURCE = "comune_gubbio";
const SOURCE_LABEL = "Comune di Gubbio";
const USER_AGENT = "VisitGubbioApp/1.0 (+https://visitgubbio.eu)";
const MAX_ITEMS = 100;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-import-secret",
};

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// ---------------------------------------------------------------- testo

const ENTITIES: Record<string, string> = {
  amp: "&", lt: "<", gt: ">", quot: '"', apos: "'", nbsp: " ",
  agrave: "à", aacute: "á", egrave: "è", eacute: "é", igrave: "ì",
  iacute: "í", ograve: "ò", oacute: "ó", ugrave: "ù", uacute: "ú",
  Agrave: "À", Egrave: "È", Eacute: "É", Igrave: "Ì", Ograve: "Ò",
  Ugrave: "Ù", laquo: "«", raquo: "»", rsquo: "’", lsquo: "‘",
  rdquo: "”", ldquo: "“", ndash: "–", mdash: "—", hellip: "…", euro: "€",
  deg: "°", ordm: "º",
};

function decodeEntities(s: string): string {
  return s.replace(/&(#x[0-9a-f]+|#\d+|[a-z]+);/gi, (m, code: string) => {
    if (code[0] === "#") {
      const n = code[1].toLowerCase() === "x"
        ? parseInt(code.slice(2), 16)
        : parseInt(code.slice(1), 10);
      return Number.isFinite(n) ? String.fromCodePoint(n) : m;
    }
    return ENTITIES[code] ?? m;
  });
}

function htmlToText(html: string): string {
  return decodeEntities(
    html
      .replace(/<(script|style)[\s\S]*?<\/\1>/gi, "")
      .replace(/<br\s*\/?>/gi, "\n")
      .replace(/<\/(p|div|li|h[1-6]|tr)>/gi, "\n")
      .replace(/<li[^>]*>/gi, "• ")
      .replace(/<[^>]+>/g, ""),
  )
    .replace(/[ \t ]+/g, " ")
    .replace(/ *\n */g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

/** Valore testuale di un nodo XML (stringa, {#text}, CDATA...). */
function text(v: unknown): string {
  if (v == null) return "";
  if (typeof v === "string" || typeof v === "number") return String(v).trim();
  if (Array.isArray(v)) return text(v[0]);
  if (typeof v === "object") {
    const o = v as Record<string, unknown>;
    return text(o["#text"] ?? o["__cdata"] ?? "");
  }
  return "";
}

function asArray<T>(v: T | T[] | undefined | null): T[] {
  if (v == null) return [];
  return Array.isArray(v) ? v : [v];
}

function absoluteUrl(url: string, base: string): string {
  try {
    return new URL(decodeEntities(url.trim()), base).toString();
  } catch {
    return "";
  }
}

// ---------------------------------------------------------------- date

const MONTHS: Record<string, number> = {
  gennaio: 1, gen: 1, febbraio: 2, feb: 2, marzo: 3, mar: 3, aprile: 4,
  apr: 4, maggio: 5, mag: 5, giugno: 6, giu: 6, luglio: 7, lug: 7,
  agosto: 8, ago: 8, settembre: 9, set: 9, sett: 9, ottobre: 10, ott: 10,
  novembre: 11, nov: 11, dicembre: 12, dic: 12,
};
const MONTH_RE =
  "(gennaio|febbraio|marzo|aprile|maggio|giugno|luglio|agosto|settembre|ottobre|novembre|dicembre|gen|feb|mar|apr|mag|giu|lug|ago|sett|set|ott|nov|dic)\\.?";

/** Converte un'ora italiana (Europe/Rome) in ISO UTC. */
function romeToUtcIso(y: number, m: number, d: number, h = 0, mi = 0): string {
  const guess = Date.UTC(y, m - 1, d, h, mi);
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: "Europe/Rome",
    hourCycle: "h23",
    year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit",
  }).formatToParts(new Date(guess));
  const get = (t: string) => Number(parts.find((p) => p.type === t)?.value);
  const local = Date.UTC(get("year"), get("month") - 1, get("day"), get("hour"), get("minute"));
  return new Date(guess - (local - guess)).toISOString();
}

type DayRef = { y: number | null; m: number; d: number };
type Parsed = { start: string; end: string } | null;

function validDay(d: number, m: number) {
  return m >= 1 && m <= 12 && d >= 1 && d <= 31;
}

/** Anno mancante: quello che rende la data "attuale" (non più di 2 mesi fa). */
function inferYear(m: number, d: number, now: Date): number {
  const y = now.getUTCFullYear();
  const candidate = Date.UTC(y, m - 1, d);
  return candidate < now.getTime() - 60 * 86400000 ? y + 1 : y;
}

/**
 * Cerca le date di un evento in un testo italiano, ad esempio:
 * "dal 5 al 7 novembre 2026", "dal 28 novembre al 6 gennaio",
 * "sabato 14 dicembre 2026 ore 21:00", "05/11/2026", "dalle 10 alle 18".
 */
function parseItalianDates(raw: string, now: Date): Parsed {
  const s = raw.toLowerCase().replace(/\s+/g, " ");
  let a: DayRef | null = null;
  let b: DayRef | null = null;

  const rangeSameMonth = new RegExp(
    `\\b(?:dal|da)\\s+(\\d{1,2})\\s+(?:al|a|-|–)\\s+(\\d{1,2})\\s+${MONTH_RE}(?:\\s+(\\d{4}))?`,
  ).exec(s);
  const rangeTwoMonths = new RegExp(
    `\\b(\\d{1,2})\\s+${MONTH_RE}(?:\\s+(\\d{4}))?\\s*(?:al|a|-|–)\\s*(\\d{1,2})\\s+${MONTH_RE}(?:\\s+(\\d{4}))?`,
  ).exec(s);
  const numericRange =
    /\b(\d{1,2})[\/.](\d{1,2})[\/.](\d{4})\s*(?:al|a|-|–)\s*(\d{1,2})[\/.](\d{1,2})[\/.](\d{4})/
      .exec(s);

  // "il 14 e 15 novembre": due giorni dello stesso mese
  const rangeAnd = new RegExp(
    `\\b(\\d{1,2})\\s+e\\s+(\\d{1,2})\\s+${MONTH_RE}(?:\\s+(\\d{4}))?`,
  ).exec(s);

  if (rangeSameMonth || rangeAnd) {
    const r = (rangeSameMonth ?? rangeAnd)!;
    const m = MONTHS[r[3]];
    const y = r[4] ? Number(r[4]) : null;
    a = { y, m, d: Number(r[1]) };
    b = { y, m, d: Number(r[2]) };
  } else if (rangeTwoMonths) {
    const y2 = rangeTwoMonths[6] ? Number(rangeTwoMonths[6]) : null;
    const y1 = rangeTwoMonths[3] ? Number(rangeTwoMonths[3]) : null;
    a = { y: y1, m: MONTHS[rangeTwoMonths[2]], d: Number(rangeTwoMonths[1]) };
    b = { y: y2, m: MONTHS[rangeTwoMonths[5]], d: Number(rangeTwoMonths[4]) };
    if (a.y == null && b.y != null) a.y = a.m > b.m ? b.y - 1 : b.y;
  } else if (numericRange) {
    a = { y: Number(numericRange[3]), m: Number(numericRange[2]), d: Number(numericRange[1]) };
    b = { y: Number(numericRange[6]), m: Number(numericRange[5]), d: Number(numericRange[4]) };
  } else {
    const single = new RegExp(`\\b(\\d{1,2})(?:°|º)?\\s+${MONTH_RE}(?:\\s+(\\d{4}))?`).exec(s);
    const numeric = /\b(\d{1,2})[\/.](\d{1,2})[\/.](\d{4})\b/.exec(s);
    const iso = /\b(\d{4})-(\d{2})-(\d{2})\b/.exec(s);
    if (single) {
      a = { y: single[3] ? Number(single[3]) : null, m: MONTHS[single[2]], d: Number(single[1]) };
    } else if (numeric) {
      a = { y: Number(numeric[3]), m: Number(numeric[2]), d: Number(numeric[1]) };
    } else if (iso) {
      a = { y: Number(iso[1]), m: Number(iso[2]), d: Number(iso[3]) };
    }
  }

  if (!a || !validDay(a.d, a.m)) return null;
  if (b && !validDay(b.d, b.m)) b = null;
  if (a.y == null) a.y = inferYear(a.m, a.d, now);
  if (b && b.y == null) b.y = b.m < a.m ? a.y + 1 : a.y;

  // Orari: "dalle 10 alle 18", "ore 21:00", "alle 17.30"
  let h1 = 0, m1 = 0, h2: number | null = null, m2 = 0;
  const fromTo = /\bdalle\s+(?:ore\s+)?(\d{1,2})(?:[:.](\d{2}))?\s+alle\s+(?:ore\s+)?(\d{1,2})(?:[:.](\d{2}))?/.exec(s);
  const at = /\b(?:ore|alle)\s+(\d{1,2})(?:[:.](\d{2}))?\b/.exec(s);
  let hasTime = false;
  if (fromTo && Number(fromTo[1]) < 24 && Number(fromTo[3]) < 24) {
    h1 = Number(fromTo[1]); m1 = Number(fromTo[2] ?? 0);
    h2 = Number(fromTo[3]); m2 = Number(fromTo[4] ?? 0);
    hasTime = true;
  } else if (at && Number(at[1]) < 24) {
    h1 = Number(at[1]); m1 = Number(at[2] ?? 0);
    hasTime = true;
  }

  const start = romeToUtcIso(a.y, a.m, a.d, h1, m1);
  const endDay = b ?? a;
  let end: string;
  if (h2 != null) {
    end = romeToUtcIso(endDay.y!, endDay.m, endDay.d, h2, m2);
  } else if (hasTime && !b) {
    end = new Date(new Date(start).getTime() + 2 * 3600000).toISOString();
  } else {
    end = romeToUtcIso(endDay.y!, endDay.m, endDay.d, 23, 59);
  }
  if (new Date(end) < new Date(start)) {
    end = romeToUtcIso(a.y, a.m, a.d, 23, 59);
  }
  return { start, end };
}

function parseIsoDate(v: string): string | null {
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}

// ---------------------------------------------------------------- feed

type FeedKind = "eventi" | "notizie";
type Feed = { url: string; kind: FeedKind };

/** Cerca i feed RSS nelle pagine del sito (pagina /it/feeds e home). */
async function discoverFeeds(): Promise<Feed[]> {
  const found = new Map<string, FeedKind>();
  for (const page of [`${SITE}/it/feeds`, `${SITE}/it`]) {
    try {
      const res = await fetch(page, { headers: { "User-Agent": USER_AGENT } });
      if (!res.ok) continue;
      const html = await res.text();
      for (const m of html.matchAll(/href\s*=\s*["']([^"']+)["']/gi)) {
        const href = m[1];
        if (!/(rss|feed|atom|\.xml)/i.test(href)) continue;
        const url = absoluteUrl(href, page);
        if (!url.startsWith("http")) continue;
        const kind: FeedKind | null = /event|eventi/i.test(href)
          ? "eventi"
          : /news|notizie/i.test(href)
          ? "notizie"
          : null;
        if (kind && !found.has(url)) found.set(url, kind);
      }
    } catch (e) {
      console.warn("discoverFeeds:", page, e);
    }
  }
  // Indirizzi più comuni dei siti Municipium, se la ricerca non trova nulla.
  for (const [u, k] of [
    [`${SITE}/it/events/feed`, "eventi"],
    [`${SITE}/it/eventi/feed`, "eventi"],
    [`${SITE}/it/news/feed`, "notizie"],
  ] as const) {
    if (!found.has(u)) found.set(u, k);
  }
  return [...found.entries()]
    .map(([url, kind]) => ({ url, kind }))
    .sort((a, b) => (a.kind === b.kind ? 0 : a.kind === "eventi" ? -1 : 1));
}

type FeedItem = {
  guid: string;
  title: string;
  link: string;
  html: string;
  image: string;
  categories: string[];
  location: string;
  startIso: string | null;
  endIso: string | null;
  /** Data di pubblicazione (pubDate / dc:date). */
  published: string | null;
};

function parseFeed(xml: string, baseUrl: string): FeedItem[] {
  const parser = new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: "@_",
    cdataPropName: "__cdata",
    processEntities: true,
  });
  const doc = parser.parse(xml);
  const rssItems = asArray(doc?.rss?.channel?.item ?? doc?.["rdf:RDF"]?.item);
  const atomItems = asArray(doc?.feed?.entry);
  const raw = rssItems.length ? rssItems : atomItems;

  return raw.slice(0, MAX_ITEMS).map((it: Record<string, unknown>) => {
    const linkNode = it.link;
    let link = "";
    for (const l of asArray(linkNode as unknown)) {
      if (typeof l === "string") { link = l; break; }
      const o = l as Record<string, string>;
      if (o?.["@_href"] && (!o["@_rel"] || o["@_rel"] === "alternate")) {
        link = o["@_href"];
        break;
      }
    }
    link = absoluteUrl(text(link) || link, baseUrl);

    const html = text(it["content:encoded"]) || text(it.description) ||
      text(it.summary) || text(it.content);

    let image = "";
    for (const key of ["enclosure", "media:content", "media:thumbnail"]) {
      for (const node of asArray(it[key] as unknown)) {
        const o = node as Record<string, string>;
        const url = o?.["@_url"];
        const type = o?.["@_type"] ?? "";
        if (url && (!type || type.startsWith("image"))) { image = url; break; }
      }
      if (image) break;
    }
    if (!image) {
      const img = /<img[^>]+src\s*=\s*["']([^"']+)["']/i.exec(html);
      if (img) image = img[1];
    }
    if (image) image = absoluteUrl(image, link || baseUrl);

    const categories = asArray(it.category as unknown)
      .map((c) => text(c))
      .filter((c) => c.length > 0);

    const start = text(it["ev:startdate"]) || text(it["startDate"]) ||
      text(it["event:startdate"]);
    const end = text(it["ev:enddate"]) || text(it["endDate"]) ||
      text(it["event:enddate"]);

    return {
      guid: text(it.guid) || text(it.id) || link,
      title: htmlToText(text(it.title)),
      link,
      html,
      image,
      categories,
      location: htmlToText(text(it["ev:location"]) || text(it["location"])),
      startIso: start ? parseIsoDate(start) : null,
      endIso: end ? parseIsoDate(end) : null,
      published: parseIsoDate(text(it.pubDate) || text(it["dc:date"]) ||
        text(it.published) || text(it.updated) || "x"),
    };
  });
}

// ---------------------------------------------------------------- articoli

/** Notizie che non sono eventi (avvisi, viabilità, bandi...): si saltano. */
const NOT_EVENT_RE =
  /\b(circolazione|viabilit|ordinanz|bando|bandi|avviso|censiment|chiusur|sciopero|tribut|graduatori|concors|lavori|allerta|scadenz|elezion|indagin|customer|questionari|sondagg|convocazion|mobilit)/i;

type Article = {
  title: string;
  subtitle: string;
  body: string;
  image: string;
  /** "Notizie", "Comunicati", "Avvisi"... (dal percorso Home > Novità > ...) */
  pageType: string;
  categories: string[];
  /** "Data : 5 novembre 2026" in ISO, se c'è. */
  published: string | null;
};

/** Categorie del Comune che non sono eventi (avvisi, uffici...). */
const NOT_EVENT_CATEGORY_RE =
  /^(viabilit|urp|notizie urp|tribut|personale|concors|bandi|avvisi|polizia|anagrafe)/i;

/**
 * Pagina completa di una notizia/evento del sito Municipium: nel feed c'è
 * solo l'inizio del testo (circa 150 caratteri), mentre le date vere
 * dell'evento sono nel sottotitolo o più avanti nell'articolo.
 */
async function fetchArticle(url: string): Promise<Article | null> {
  try {
    const res = await fetch(url, { headers: { "User-Agent": USER_AGENT } });
    if (!res.ok) return null;
    const html = await res.text();
    const pick = (re: RegExp) => htmlToText(re.exec(html)?.[1] ?? "");
    const subtitle = pick(
      /data-element="(?:news|event)-description"[^>]*>([\s\S]*?)<\/p>/i,
    );
    // Testo: dalla sezione "Descrizione" fino a "A cura di" / contenuti correlati
    const start = html.search(/<h2[^>]*>\s*Descrizione\s*<\/h2>/i);
    let body = "";
    if (start >= 0) {
      const rest = html.slice(start);
      const stop = rest.search(
        /id="(?:a-cura-di|contenuti-correlati|ulteriori-informazioni)"|<h2[^>]*>\s*(?:A cura di|Contenuti correlati)/i,
      );
      body = htmlToText(
        (stop > 0 ? rest.slice(0, stop) : rest.slice(0, 20000))
          .replace(/<h2[^>]*>\s*Descrizione\s*<\/h2>/i, ""),
      );
    }
    const image = /<meta property="og:image" content="([^"]+)"/i.exec(html)?.[1] ?? "";
    const title = pick(/data-element="(?:news|event)-title"[^>]*>([\s\S]*?)<\/h1>/i);
    // Testo semplice (tag -> spazi) per "Data : ..." e il resto.
    const plain = decodeEntities(
      html.replace(/<(script|style)[\s\S]*?<\/\1>/gi, "").replace(/<[^>]+>/g, " "),
    ).replace(/\s+/g, " ");
    // Tipo di pagina dal percorso: Home > Novità > Comunicati / Notizie / Avvisi
    const pageType = decodeEntities(
      /\/news\?type=\d+"[^>]*>\s*([^<]+?)\s*</i.exec(html)?.[1] ?? "",
    );
    // Categorie: le etichette dei link "news-category" (Comune, Cultura...)
    const categories = [...new Set([...html.matchAll(
      /href="[^"]*\/news-category\/\d+"[\s\S]*?chip-label[^>]*>\s*([^<]+?)\s*</gi,
    )].map((m) => decodeEntities(m[1]).trim()))];
    const pub = /Data\s*:\s*(\d{1,2})\s+(\p{L}+)\s+(\d{4})/u.exec(plain);
    const published = pub && MONTHS[pub[2].toLowerCase()]
      ? romeToUtcIso(Number(pub[3]), MONTHS[pub[2].toLowerCase()], Number(pub[1]), 12, 0)
      : null;
    return { title, subtitle, body, image, pageType, categories, published };
  } catch {
    return null;
  }
}

/** Ultime notizie elencate nella pagina /it/news del sito (circa 15): il
 *  feed ne contiene solo 5, così non se ne perde nessuna. */
async function listNewsLinks(): Promise<string[]> {
  try {
    const res = await fetch(`${SITE}/it/news`, { headers: { "User-Agent": USER_AGENT } });
    if (!res.ok) return [];
    const html = await res.text();
    const links: string[] = [];
    for (const m of html.matchAll(/href="((?:https:\/\/www\.comune\.gubbio\.pg\.it)?\/it\/news\/[a-z0-9][^"#?]*)"/gi)) {
      const url = absoluteUrl(m[1], SITE);
      if (!url.endsWith("/feed") && !links.includes(url)) links.push(url);
    }
    return links.slice(0, 20);
  } catch {
    return [];
  }
}

/** Toglie le date che non sono quelle dell'evento: "GUBBIO (04/11/2026) -" e
 *  "Data : 4 novembre 2026" (data di pubblicazione). */
function stripPublicationDates(text: string): string {
  return text
    .replace(/\b[A-ZÀ-Ù' ]{3,}\s*\(\s*\d{1,2}\/\d{1,2}\/\d{2,4}\s*\)\s*[-–—]?\s*/g, "")
    .replace(/\bData\s*:\s*\d{1,2}\s+\p{L}+\s+\d{4}/giu, "");
}

/** Quante date diverse ("21 novembre", "6 dicembre"...) cita un testo: un
 *  programma con tante date va controllato dall'admin. */
function countDateMentions(text: string): number {
  const re = new RegExp(`\\b(\\d{1,2})\\s+${MONTH_RE}`, "gi");
  const seen = new Set<string>();
  for (const m of stripPublicationDates(text).toLowerCase().matchAll(re)) {
    seen.add(`${m[1]}-${MONTHS[m[2]]}`);
  }
  return seen.size;
}

/** Ultima data citata nel testo dopo [startIso] (entro 120 giorni): per un
 *  programma lungo (es. il Natale fino al 6 gennaio) è la fine dell'evento. */
function lastMentionedDate(text: string, startIso: string): string | null {
  const start = new Date(startIso);
  const re = new RegExp(`\\b(\\d{1,2})\\s+${MONTH_RE}(?:\\s+(\\d{4}))?`, "gi");
  let best: Date | null = null;
  for (const m of stripPublicationDates(text).toLowerCase().matchAll(re)) {
    const d = Number(m[1]);
    const mo = MONTHS[m[2]];
    if (!validDay(d, mo)) continue;
    let y = m[3] ? Number(m[3]) : start.getUTCFullYear();
    // Senza anno: un mese "prima" di quello d'inizio è dell'anno dopo.
    if (!m[3] && mo < start.getUTCMonth() + 1) y++;
    const date = new Date(romeToUtcIso(y, mo, d, 23, 59));
    if (date <= start || date.getTime() - start.getTime() > 120 * 86400000) {
      continue;
    }
    if (!best || date > best) best = date;
  }
  return best ? best.toISOString() : null;
}

/** Prima data dell'evento non ancora passata: prima nel sottotitolo e nel
 *  titolo, poi frase per frase nel testo. */
function findEventDates(
  parts: string[],
  now: Date,
): { start: string; end: string } | null {
  // Frase per frase, nell'ordine: in un testo lungo la prima data "intera"
  // potrebbe stare in mezzo a un programma (es. "20 e 26 dicembre").
  const sentences: string[] = [];
  for (const part of parts) {
    sentences.push(...stripPublicationDates(part).split(/(?<=[.!?;])\s+|\n+/));
  }
  for (const s of sentences) {
    if (!s.trim()) continue;
    const p = parseItalianDates(s, now);
    if (p && new Date(p.end).getTime() >= now.getTime() - 86400000) return p;
  }
  return null;
}

// ---------------------------------------------------------------- traduzioni

/** Traduce un evento in EN/FR/DE (funzione translate-content). Ritorna il
 *  messaggio d'errore, oppure null se è andata bene. */
async function translateEvent(
  supabaseUrl: string,
  serviceRoleKey: string,
  id: string,
): Promise<string | null> {
  try {
    const res = await fetch(`${supabaseUrl}/functions/v1/translate-content`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${serviceRoleKey}`,
      },
      body: JSON.stringify({ entity_type: "eventi", entity_id: id }),
    });
    if (res.ok) return null;
    return `${res.status} ${(await res.text()).slice(0, 200)}`;
  } catch (e) {
    return String(e);
  }
}

/** Traduce più eventi, pochi alla volta, e annota gli errori. */
async function translateEvents(
  supabaseUrl: string,
  serviceRoleKey: string,
  ids: string[],
  errori: string[],
): Promise<number> {
  let ok = 0;
  for (let i = 0; i < ids.length; i += 3) {
    const chunk = ids.slice(i, i + 3);
    const out = await Promise.all(
      chunk.map((id) => translateEvent(supabaseUrl, serviceRoleKey, id)),
    );
    out.forEach((err, k) => {
      if (err) errori.push(`traduzione ${chunk[k]}: ${err}`);
      else ok++;
    });
  }
  return ok;
}

// ---------------------------------------------------------------- server

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const db = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // ---------------------------------------------- chi può avviarla
  // Il programma automatico (parola segreta) oppure un admin collegato.
  const secret = req.headers.get("x-import-secret");
  let allowed = false;
  if (secret) {
    const { data } = await db.rpc("verifica_segreto_import", { segreto: secret });
    allowed = data === true;
  } else {
    const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    const { data: { user } } = await db.auth.getUser(token);
    if (user) {
      const { data: utente } = await db.from("utenti").select("ruolo")
        .eq("id", user.id).single();
      allowed = utente?.ruolo === "admin";
    }
  }
  if (!allowed) return jsonResponse({ error: "Non autorizzato" }, 403);

  // ---------------------------------------------- pubblicazione delle bozze
  // Chiamata dal programma automatico alle 13:00 (ora italiana): le bozze
  // importate che nessuno ha toccato vengono pubblicate così come sono.
  const reqBody = await req.json().catch(() => ({}));
  if (reqBody?.azione === "pubblica") {
    const out = { pubblicati: 0, errori: [] as string[] };
    const { data: drafts, error } = await db.from("eventi")
      .update({ stato: "pubblicato" })
      .eq("stato", "bozza").eq("fonte", SOURCE).select("id");
    if (error) {
      out.errori.push(error.message);
    } else {
      out.pubblicati = drafts?.length ?? 0;
      // Sono già tradotti dall'importazione (e dalle modifiche dell'admin):
      // si traducono solo quelli che non hanno ancora la traduzione.
      const ids = (drafts ?? []).map((d) => d.id as string);
      const { data: done } = ids.length
        ? await db.from("content_translations").select("entity_id")
          .eq("entity_type", "eventi").eq("language_code", "de").in("entity_id", ids)
        : { data: [] };
      const translated = new Set((done ?? []).map((r) => r.entity_id));
      await translateEvents(
        supabaseUrl,
        serviceRoleKey,
        ids.filter((id) => !translated.has(id)),
        out.errori,
      );
    }
    return jsonResponse(out, error ? 500 : 200);
  }

  // ---------------------------------------------- impostazioni
  const { data: config } = await db.from("import_eventi_stato")
    .select().eq("id", 1).maybeSingle();
  const publishNow = config?.pubblica_subito ?? true;
  const withImages = config?.importa_immagini ?? true;

  const result = {
    feed: "",
    tipo_feed: "",
    trovati: 0,
    nuovi: 0,
    pubblicati: 0,
    bozze: 0,
    tradotti: 0,
    eventi: 0,
    notizie: 0,
    saltati: 0,
    errori: [] as string[],
  };

  try {
    // ---------------------------------------------- lettura del feed
    const feeds: Feed[] = config?.feed_url
      ? [{ url: config.feed_url, kind: /news|notizie/i.test(config.feed_url) ? "notizie" : "eventi" }]
      : await discoverFeeds();

    let items: FeedItem[] = [];
    for (const f of feeds) {
      try {
        const res = await fetch(f.url, { headers: { "User-Agent": USER_AGENT } });
        if (!res.ok) continue;
        const parsed = parseFeed(await res.text(), f.url);
        if (parsed.length === 0) continue;
        items = parsed;
        result.feed = f.url;
        result.tipo_feed = f.kind;
        break;
      } catch (e) {
        result.errori.push(`${f.url}: ${e}`);
      }
    }
    // Più l'elenco delle ultime notizie del sito (il feed ne ha solo 5).
    const known = new Set(items.map((i) => i.link));
    for (const url of await listNewsLinks()) {
      if (known.has(url)) continue;
      known.add(url);
      items.push({
        guid: url, title: "", link: url, html: "", image: "", categories: [],
        location: "", startIso: null, endIso: null, published: null,
      });
    }
    if (!result.feed && items.length > 0) {
      result.feed = `${SITE}/it/news`;
      result.tipo_feed = "notizie";
    }
    if (items.length === 0) throw new Error("Nessun feed del Comune trovato");
    result.trovati = items.length;

    // ---------------------------------------------- solo quelli nuovi
    const ids = items.map((i) => i.guid).filter(Boolean);
    const { data: existing } = await db.from("eventi").select("fonte_id")
      .in("fonte_id", ids);
    const already = new Set((existing ?? []).map((r) => r.fonte_id));

    const now = new Date();
    const rows: Record<string, unknown>[] = [];
    for (const it of items) {
      if (!it.guid || already.has(it.guid)) {
        result.saltati++;
        continue;
      }

      // Pagina completa dal sito del Comune (testo intero, date, foto grande,
      // tipo di pagina e categorie).
      const article = it.link.startsWith(SITE) ? await fetchArticle(it.link) : null;
      const title = it.title || article?.title || "";
      if (!title) {
        result.saltati++;
        continue;
      }
      const feedText = htmlToText(it.html);
      const body = article?.body || feedText;
      const subtitle = article?.subtitle ?? "";
      const categories = (article?.categories.length
        ? article.categories
        : it.categories).filter((c) => !/^(comune|notizie)$/i.test(c));

      // È un evento? Sì se ha una data futura e non è un avviso (viabilità,
      // uffici, bandi...). Altrimenti è una notizia: si importa lo stesso.
      let start = it.startIso;
      let end = it.endIso;
      let sure = !!start;
      if (!start) {
        const p = findEventDates([subtitle, title, body], now);
        if (p) {
          start = p.start;
          end = p.end;
          // Un programma con tante date (es. il Natale): da controllare, e la
          // fine è l'ultima data citata.
          sure = countDateMentions(body) <= 3;
          if (!sure) end = lastMentionedDate(body, start) ?? end;
        }
      }
      const notAnEvent = NOT_EVENT_RE.test(title) ||
        categories.some((c) => NOT_EVENT_CATEGORY_RE.test(c)) ||
        /^avvisi$/i.test(article?.pageType ?? "");
      const isEvent = !!start && (result.tipo_feed === "eventi" || !notAnEvent);

      if (isEvent) {
        if (!end || new Date(end) < new Date(start!)) {
          end = new Date(new Date(start!).getTime() + 2 * 3600000).toISOString();
        }
        if (new Date(end).getTime() < now.getTime() - 86400000) {
          result.saltati++; // evento già finito
          continue;
        }
      } else {
        // Notizia: la data è quella di pubblicazione.
        start = article?.published || it.published || now.toISOString();
        end = start;
        sure = true;
      }

      const publish = publishNow && sure && result.tipo_feed === "eventi";
      rows.push({
        tipo: isEvent ? "evento" : "notizia",
        titolo: title.slice(0, 200),
        descrizione: `${[subtitle, stripPublicationDates(body)]
          .filter((t) => t.trim())
          .join("\n\n")
          .slice(0, 4000)}\n\nFonte: ${SOURCE_LABEL}`.trim(),
        luogo: it.location || "Gubbio",
        image_url: withImages && (article?.image || it.image)
          ? (article?.image || it.image)
          : null,
        sito_web: it.link || null,
        data_inizio: start,
        data_fine: end,
        categoria: categories[0] || SOURCE_LABEL,
        tags: categories.slice(0, 5),
        stato: publish ? "pubblicato" : "bozza",
        fonte: SOURCE,
        fonte_id: it.guid,
        fonte_url: it.link || null,
        date_da_verificare: isEvent && !sure,
      });
    }

    // ---------------------------------------------- salvataggio
    if (rows.length > 0) {
      const { data: inserted, error } = await db.from("eventi")
        .insert(rows).select("id, stato");
      if (error) throw error;
      result.nuovi = inserted?.length ?? 0;
      for (const ev of inserted ?? []) {
        if (ev.stato === "pubblicato") result.pubblicati++;
        else result.bozze++;
      }
      for (const r of rows) {
        if (r.tipo === "notizia") result.notizie++;
        else result.eventi++;
      }
      // Traduzione in inglese, francese e tedesco SUBITO, anche per le bozze:
      // quando vengono pubblicate sono già nelle 4 lingue. Se l'admin le
      // modifica, l'app le ritraduce da sola.
      result.tradotti = await translateEvents(
        supabaseUrl,
        serviceRoleKey,
        (inserted ?? []).map((ev) => ev.id as string),
        result.errori,
      );
    }
  } catch (e) {
    result.errori.push(String((e as Error)?.message ?? e));
  }

  await db.from("import_eventi_stato").update({
    ultimo_avvio: new Date().toISOString(),
    ultimo_esito: result,
  }).eq("id", 1);

  return jsonResponse(result, result.feed ? 200 : 502);
});
