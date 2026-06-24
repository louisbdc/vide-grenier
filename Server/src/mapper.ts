import { EventDoc, EventKind } from "./types.js";

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
}

/// Normalise une chaîne pour la classification : minuscules, sans accents.
function normalize(s: string): string {
  return s.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "");
}

/// Détermine la catégorie d'un événement.
///
/// `type=SaleEvent` est une classe parente : ses sous-classes DATAtourisme
/// distinguent la chine (`GarageSale` = vide-grenier, `BricABrac` = brocante/puces)
/// des marchés alimentaires (`Market`) et des salons/foires (`FairOrShow`,
/// `OpenDay`, `BusinessEvent`). On classe d'abord par ce `@type` (autoritatif),
/// puis par mots-clés du nom en repli, puis « autre ».
function classifyKind(types: string[] | undefined, name: string): EventKind {
  const typeStr = normalize((types ?? []).join(" "));
  const nameStr = normalize(name);

  // 1. Sous-classes DATAtourisme (signal officiel le plus fiable).
  if (/garagesale/.test(typeStr)) return "videGrenier";
  if (/bricabrac/.test(typeStr)) {
    // BricABrac couvre brocantes ET marchés aux puces : on affine au nom.
    return /puces/.test(nameStr) ? "marcheAuxPuces" : "brocante";
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
