/// Types partagés du domaine.

export type EventKind =
  | "videGrenier" | "brocante" | "marcheAuxPuces" | "braderie" | "autre";

export type EventSource = "dataTourisme" | "crowdsourced";

export type LiveStatus =
  | "scheduled" | "ongoing" | "crowded" | "deserted" | "emptied" | "cancelled";

export type SignalType = "ongoing" | "crowded" | "deserted" | "emptied" | "cancelled";

/// Point GeoJSON [longitude, latitude] indexé en 2dsphere.
export interface GeoPoint {
  type: "Point";
  coordinates: [number, number];
}

export interface EventDoc {
  _id?: string;          // = extId pour DATAtourisme, sinon ObjectId-like généré
  extId: string;         // identifiant source (uuid DATAtourisme) ou uuid crowdsourcé
  name: string;
  kind: EventKind;
  location: GeoPoint;
  startsAt: Date;
  endsAt: Date | null;
  address: string | null;
  recurrenceDays: string[];
  source: EventSource;
  ownerUid: string | null;
  liveStatus: LiveStatus;
  topTags: string[];
  photoCount: number;
  updatedAt: Date;
  // Checkout Session Stripe ayant payé la publication (annonces crowdsourcées).
  checkoutSessionId?: string;
}

export interface SignalDoc {
  eventId: string;
  type: SignalType;
  uid: string;
  createdAt: Date;
}

export interface TagDoc {
  eventId: string;
  label: string;
  uid: string;
  createdAt: Date;
}

export interface PhotoDoc {
  eventId: string;
  file: string;          // nom de fichier sur disque
  url: string;
  uid: string;
  createdAt: Date;
}
