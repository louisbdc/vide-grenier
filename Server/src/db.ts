import { MongoClient, Db, Collection } from "mongodb";
import { config } from "./config.js";
import { EventDoc, SignalDoc, TagDoc, PhotoDoc } from "./types.js";

let client: MongoClient;
let db: Db;

export interface Collections {
  events: Collection<EventDoc>;
  signals: Collection<SignalDoc>;
  tags: Collection<TagDoc>;
  photos: Collection<PhotoDoc>;
}

export async function connect(): Promise<void> {
  client = new MongoClient(config.mongoUrl);
  await client.connect();
  db = client.db(config.dbName);
  await ensureIndexes();
}

export function getDb(): Db {
  if (!db) throw new Error("DB non initialisée — appeler connect() d'abord.");
  return db;
}

export function collections(): Collections {
  const d = getDb();
  return {
    events: d.collection<EventDoc>("events"),
    signals: d.collection<SignalDoc>("signals"),
    tags: d.collection<TagDoc>("tags"),
    photos: d.collection<PhotoDoc>("photos"),
  };
}

/// Index : 2dsphere pour les requêtes par rayon, TTL pour l'expiration des
/// signaux (6 h), et unicité de l'identifiant source des événements.
async function ensureIndexes(): Promise<void> {
  const c = collections();
  await c.events.createIndex({ location: "2dsphere" });
  await c.events.createIndex({ extId: 1 }, { unique: true });
  await c.events.createIndex({ endsAt: 1 });
  // Une session de paiement ne peut financer qu'une seule annonce.
  await c.events.createIndex({ checkoutSessionId: 1 }, { unique: true, sparse: true });
  await c.signals.createIndex({ eventId: 1 });
  await c.signals.createIndex({ createdAt: 1 }, { expireAfterSeconds: 6 * 3600 });
  await c.tags.createIndex({ eventId: 1 });
  await c.photos.createIndex({ eventId: 1 });
  // Un seul signal/tag par utilisateur et par type/label (déduplication).
  // Tolérant : si d'anciens doublons existent, on n'empêche pas le démarrage
  // (l'upsert applicatif déduplique déjà à l'écriture).
  await tryUniqueIndex(c.signals, { eventId: 1, uid: 1, type: 1 });
  await tryUniqueIndex(c.tags, { eventId: 1, uid: 1, label: 1 });
}

async function tryUniqueIndex(
  collection: Collection<SignalDoc> | Collection<TagDoc>,
  keys: Record<string, 1>,
): Promise<void> {
  try {
    await collection.createIndex(keys as never, { unique: true });
  } catch (error) {
    console.warn("Index unique non créé (doublons existants ?) :", (error as Error).message);
  }
}

export async function close(): Promise<void> {
  await client?.close();
}
