import { EventDoc } from "./types.js";

/// Forme JSON renvoyée à l'app (latitude/longitude à plat, id = extId).
export interface EventJSON {
  id: string;
  name: string;
  kind: string;
  latitude: number;
  longitude: number;
  startsAt: string;
  endsAt: string | null;
  address: string | null;
  recurrenceDays: string[];
  source: string;
  liveStatus: string;
  topTags: string[];
  photoCount: number;
  authorId: string | null;   // pour le blocage côté client (null = open data)
}

export function serializeEvent(doc: EventDoc): EventJSON {
  const [longitude, latitude] = doc.location.coordinates;
  return {
    id: doc.extId,
    name: doc.name,
    kind: doc.kind,
    latitude,
    longitude,
    startsAt: doc.startsAt.toISOString(),
    endsAt: doc.endsAt ? doc.endsAt.toISOString() : null,
    address: doc.address,
    recurrenceDays: doc.recurrenceDays,
    source: doc.source,
    liveStatus: doc.liveStatus,
    topTags: doc.topTags,
    photoCount: doc.photoCount,
    authorId: doc.ownerUid,
  };
}
