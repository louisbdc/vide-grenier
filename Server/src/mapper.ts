import { EventDoc, EventKind } from "./types.js";
import { cleanRichText } from "./ingest.js";

// Objet renvoyé par l'API REST DATAtourisme v1 (/entertainmentAndEvent).
export interface DataTourismeObject {
  uuid?: string;
  uri?: string;
  label?: Record<string, string>;
  type?: string[];
  isLocatedAt?: Array<{
    geo?: { latitude?: number; longitude?: number };
    address?: Array<{
      streetAddress?: string[];
      postalCode?: string;
      addressLocality?: string;
    }>;
  }>;
  takesPlaceAt?: Array<{
    startDate?: string;
    endDate?: string;
    startTime?: string;
    endTime?: string;
    appliesOnDay?: Array<{ key?: string }>;
  }>;
  // Structures imbriquées et variables selon les producteurs : typées en `unknown`
  // et explorées défensivement (cf. extractDescription / extractImageUrl).
  hasDescription?: unknown;
  hasMainRepresentation?: unknown;
}

/// Normalise une chaîne pour la classification : minuscules, sans accents.
export function normalize(s: string): string {
  return s.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
}

/// Détermine la catégorie d'un événement.
///
/// `type=SaleEvent` est une classe parente : ses sous-classes DATAtourisme
/// distinguent la chine (`GarageSale` = vide-grenier, `BricABrac` = brocante/puces)
/// des marchés alimentaires (`Market`) et des salons/foires (`FairOrShow`,
/// `OpenDay`, `BusinessEvent`). On classe d'abord par ce `@type` (autoritatif),
/// puis par mots-clés du nom en repli, puis « autre ».
export function classifyKind(types: string[] | undefined, name: string): EventKind {
  const typeStr = normalize((types ?? []).join(" "));
  const nameStr = normalize(name);

  // 1. Sous-classes DATAtourisme (signal officiel le plus fiable).
  if (/garagesale/.test(typeStr)) return "videGrenier";
  if (/bricabrac/.test(typeStr)) {
    // BricABrac couvre vide-greniers, brocantes ET puces : on affine au nom.
    if (/vide[- ]?grenier|videgrenier/.test(nameStr)) return "videGrenier";
    if (/puces/.test(nameStr)) return "marcheAuxPuces";
    return "brocante";
  }
  if (/\bmarket\b/.test(typeStr)) return "marche";
  if (/fairorshow|openday|businessevent/.test(typeStr)) return "autre";

  // 2. Repli par mots-clés du nom (type absent ou générique).
  //    Ordre = spécificité décroissante (« marche aux puces » avant « marche »).
  if (/vide[- ]?grenier|videgrenier/.test(nameStr)) return "videGrenier";
  if (/brocante/.test(nameStr)) return "brocante";
  if (/puces/.test(nameStr)) return "marcheAuxPuces";
  if (/braderie/.test(nameStr)) return "braderie";
  if (/\bmarches?\b|halles?\b|foire/.test(nameStr)) return "marche";
  return "autre";
}

function frLabel(label: DataTourismeObject["label"]): string {
  if (!label) return "Vide-grenier";
  return label["@fr"] ?? label["@en"] ?? Object.values(label)[0] ?? "Vide-grenier";
}

function buildAddress(obj: DataTourismeObject): string | null {
  const addr = obj.isLocatedAt?.[0]?.address?.[0];
  if (!addr) return null;
  const parts = [
    addr.streetAddress?.filter(Boolean).join(" "),
    addr.postalCode,
    addr.addressLocality,
  ].filter(Boolean);
  return parts.length ? parts.join(", ") : null;
}

/// Extrait une valeur texte FR d'un champ DATAtourisme polymorphe :
/// string, string[], ou map de langue ({ "@fr": ... } / { fr: ... }).
function pickText(value: unknown): string | null {
  if (typeof value === "string") return value.trim() || null;
  if (Array.isArray(value)) {
    for (const v of value) {
      const t = pickText(v);
      if (t) return t;
    }
    return null;
  }
  if (value && typeof value === "object") {
    const obj = value as Record<string, unknown>;
    return pickText(obj["@fr"] ?? obj.fr ?? obj["@en"] ?? obj.en ?? Object.values(obj)[0]);
  }
  return null;
}

function firstOf(value: unknown): unknown {
  return Array.isArray(value) ? value[0] : value;
}

/// Description : `hasDescription[0].shortDescription` (repli longDescription).
function extractDescription(obj: DataTourismeObject): string | null {
  const desc = firstOf(obj.hasDescription) as Record<string, unknown> | undefined;
  if (!desc) return null;
  return cleanRichText(pickText(desc.shortDescription) ?? pickText(desc.longDescription));
}

/// Image : la structure exacte de `hasMainRepresentation` varie selon les
/// producteurs (préfixes ebucore:, imbrication). On cherche donc récursivement
/// la première URL d'image dans le sous-arbre, ce qui est robuste au schéma.
function extractImageUrl(obj: DataTourismeObject): string | null {
  return deepFindImageUrl(obj.hasMainRepresentation, 0);
}

function deepFindImageUrl(value: unknown, depth: number): string | null {
  if (depth > 6 || value == null) return null;
  if (typeof value === "string") {
    return /^https?:\/\/\S+\.(jpe?g|png|webp|gif)/i.test(value) || /^https?:\/\//.test(value)
      ? value
      : null;
  }
  if (Array.isArray(value)) {
    for (const v of value) {
      const found = deepFindImageUrl(v, depth + 1);
      if (found) return found;
    }
    return null;
  }
  if (typeof value === "object") {
    for (const v of Object.values(value as Record<string, unknown>)) {
      const found = deepFindImageUrl(v, depth + 1);
      if (found) return found;
    }
  }
  return null;
}

function combine(date?: string, time?: string): Date | null {
  if (!date) return null;
  const d = new Date(time ? `${date}T${time}:00` : `${date}T00:00:00`);
  return Number.isNaN(d.getTime()) ? null : d;
}

/// Convertit un objet DATAtourisme en document Mongo, ou null si inexploitable.
export function mapObject(obj: DataTourismeObject): EventDoc | null {
  const geo = obj.isLocatedAt?.[0]?.geo;
  const latitude = Number(geo?.latitude);
  const longitude = Number(geo?.longitude);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;

  const extId = obj.uuid ?? obj.uri;
  if (!extId) return null;

  const slot = obj.takesPlaceAt?.[0];
  const startsAt = combine(slot?.startDate, slot?.startTime);
  if (!startsAt) return null;

  const name = frLabel(obj.label);

  return {
    extId,
    name,
    kind: classifyKind(obj.type, name),
    location: { type: "Point", coordinates: [longitude, latitude] },
    startsAt,
    endsAt: combine(slot?.endDate, slot?.endTime),
    address: buildAddress(obj),
    description: extractDescription(obj),
    imageUrl: extractImageUrl(obj),
    recurrenceDays: (slot?.appliesOnDay ?? [])
      .map((d) => d.key)
      .filter((k): k is string => typeof k === "string"),
    source: "dataTourisme",
    ownerUid: null,
    liveStatus: "scheduled",
    topTags: [],
    photoCount: 0,
    updatedAt: new Date(),
  };
}
