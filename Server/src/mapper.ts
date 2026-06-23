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

function kindFromTypes(types: string[] | undefined): EventKind {
  const joined = (types ?? []).join(" ").toLowerCase();
  if (joined.includes("garagesale") || joined.includes("videgrenier")) return "videGrenier";
  if (joined.includes("brocante")) return "brocante";
  if (joined.includes("fleamarket") || joined.includes("puces")) return "marcheAuxPuces";
  if (joined.includes("braderie")) return "braderie";
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

  return {
    extId,
    name: frLabel(obj.label),
    kind: kindFromTypes(obj.type),
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
