import { EventDoc, EventKind } from "./types.js";
import { classifyKind } from "./mapper.js";
import { upsertEvents } from "./ingest.js";

// Miroir public Opendatasoft de l'agrégat OpenAgenda (Licence Ouverte, sans clé) —
// API Explore v2.1. C'est là que les associations et mairies de villages publient
// leurs vide-greniers, là où DATAtourisme (offices de tourisme) est pauvre.
// La clause `where` filtre côté serveur sur les événements à venir, ce qui évite
// d'aspirer l'historique : ~quelques centaines de fiches au lieu de millions.
const ENDPOINT =
  "https://public.opendatasoft.com/api/explore/v2.1/catalog/datasets/evenements-publics-openagenda/records";
const PAGE_SIZE = 100; // maximum v2.1.
const MAX_OFFSET = 9_900; // borne v2.1 : offset + limit <= 10 000.

// Filtre plein-texte large (titre + description) ; le bruit est ensuite écarté
// par classifyKind sur le titre seul. Termes régionaux de la chine inclus.
const CHINE_TERMS = [
  "vide-grenier", "vide grenier", "vide-greniers", "videgrenier",
  "brocante", "braderie", "puces", "deballage", "bric a brac", "vide dressing",
];

// On ne conserve que les vraies catégories de chine : le plein-texte ramène du
// bruit (événements dont seule la description mentionne un de ces termes).
const CHINE_KINDS = new Set<EventKind>(["videGrenier", "brocante", "marcheAuxPuces", "braderie"]);

interface OARecord {
  uid?: string | number;
  title_fr?: string;
  title?: string;
  description_fr?: string;
  longdescription_fr?: string;
  image?: string;
  originalimage?: string;
  thumbnail?: string;
  location_coordinates?: { lon?: number; lat?: number };
  firstdate_begin?: string;
  lastdate_end?: string;
  location_address?: string;
  location_postalcode?: string;
  location_city?: string;
}

/// Nettoie un texte source : espaces normalisés, borné à une longueur lisible.
function cleanDescription(s: string | undefined): string | null {
  if (!s) return null;
  const text = s.replace(/\s+/g, " ").trim();
  if (!text) return null;
  return text.length > 600 ? `${text.slice(0, 597)}…` : text;
}

interface OAResponse {
  total_count?: number;
  results?: OARecord[];
}

function buildAddress(r: OARecord): string | null {
  const parts = [r.location_address, r.location_postalcode, r.location_city].filter(Boolean);
  return parts.length ? parts.join(", ") : null;
}

function parseDate(s?: string): Date | null {
  if (!s) return null;
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? null : d;
}

/// Convertit un enregistrement OpenAgenda en EventDoc, ou null si inexploitable
/// (sans coordonnées, sans date de début, ou hors périmètre chine).
function mapRecord(r: OARecord): EventDoc | null {
  const latitude = r.location_coordinates?.lat;
  const longitude = r.location_coordinates?.lon;
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;

  const uid = r.uid != null ? String(r.uid) : null;
  if (!uid) return null;

  const startsAt = parseDate(r.firstdate_begin);
  if (!startsAt) return null;

  const name = r.title_fr ?? r.title ?? "Vide-grenier";
  const kind = classifyKind(undefined, name);
  if (!CHINE_KINDS.has(kind)) return null;

  return {
    extId: `oa:${uid}`,
    name,
    kind,
    location: { type: "Point", coordinates: [longitude as number, latitude as number] },
    startsAt,
    endsAt: parseDate(r.lastdate_end),
    address: buildAddress(r),
    description: cleanDescription(r.longdescription_fr ?? r.description_fr),
    imageUrl: r.image ?? r.originalimage ?? r.thumbnail ?? null,
    recurrenceDays: [],
    source: "openAgenda",
    ownerUid: null,
    liveStatus: "scheduled",
    topTags: [],
    photoCount: 0,
    updatedAt: new Date(),
  };
}

function buildWhere(): string {
  const terms = CHINE_TERMS.map((t) => `"${t}"`).join(" or ");
  return `firstdate_begin >= now() and (${terms})`;
}

async function fetchPage(offset: number): Promise<OAResponse> {
  const url =
    `${ENDPOINT}?where=${encodeURIComponent(buildWhere())}` +
    `&limit=${PAGE_SIZE}&offset=${offset}&order_by=firstdate_begin`;
  const res = await fetch(url, { headers: { Accept: "application/json" } });
  if (!res.ok) throw new Error(`OpenAgenda HTTP ${res.status}`);
  return (await res.json()) as OAResponse;
}

/// Importe les vide-greniers/brocantes OpenAgenda à venir (upsert par `oa:<uid>`).
export async function runOpenAgendaImport(): Promise<{ fetched: number; upserted: number }> {
  const mapped: EventDoc[] = [];
  let fetched = 0;

  for (let offset = 0; offset <= MAX_OFFSET; offset += PAGE_SIZE) {
    const body = await fetchPage(offset);
    const results = body.results ?? [];
    if (results.length === 0) break;
    fetched += results.length;
    for (const r of results) {
      const doc = mapRecord(r);
      if (doc) mapped.push(doc);
    }
    if (offset + results.length >= (body.total_count ?? 0)) break;
  }

  const upserted = await upsertEvents(mapped);
  return { fetched, upserted };
}
