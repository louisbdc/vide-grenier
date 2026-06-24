import { mapObject, DataTourismeObject } from "./mapper.js";
import { EventDoc } from "./types.js";
import { upsertEvents, keepUpcoming } from "./ingest.js";

const API_BASE = "https://api.datatourisme.fr/v1";
const PAGE_SIZE = 250;
const MAX_PAGES = 200;
const FIELDS = "uuid,uri,label,type,isLocatedAt.geo,isLocatedAt.address,takesPlaceAt";

interface ApiResponse {
  objects?: DataTourismeObject[];
  meta?: { total?: number; next?: string };
}

async function fetchAll(apiKey: string): Promise<DataTourismeObject[]> {
  const headers = { "X-API-Key": apiKey, Accept: "application/json" };
  let url =
    `${API_BASE}/entertainmentAndEvent` +
    `?type=SaleEvent&page_size=${PAGE_SIZE}&fields=${encodeURIComponent(FIELDS)}`;
  const all: DataTourismeObject[] = [];
  for (let page = 0; page < MAX_PAGES; page += 1) {
    const res = await fetch(url, { headers });
    if (res.status === 401) throw new Error("DATAtourisme : clé API invalide (401).");
    if (!res.ok) throw new Error(`DATAtourisme HTTP ${res.status}`);
    const body = (await res.json()) as ApiResponse;
    all.push(...(body.objects ?? []));
    if (!body.meta?.next) break;
    url = body.meta.next;
  }
  return all;
}

/// Importe/actualise les événements DATAtourisme (upsert par extId). Préserve
/// les champs agrégés crowdsourcés (liveStatus, topTags, photoCount).
export async function runImport(apiKey: string): Promise<{ fetched: number; upserted: number }> {
  if (!apiKey) throw new Error("DATATOURISME_API_KEY non configurée.");
  const objects = await fetchAll(apiKey);

  const mapped = keepUpcoming(
    objects.map(mapObject).filter((e): e is EventDoc => e !== null),
  );

  const upserted = await upsertEvents(mapped);
  return { fetched: objects.length, upserted };
}
