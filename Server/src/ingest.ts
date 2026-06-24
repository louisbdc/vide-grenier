import type { AnyBulkWriteOperation } from "mongodb";
import { collections } from "./db.js";
import { EventDoc } from "./types.js";

/// Upsert d'événements open data dans la collection `events` (clé : extId).
///
/// Les champs sourcés sont réécrits à chaque import ; les champs crowdsourcés
/// (liveStatus, topTags, photoCount, ownerUid) ne sont posés qu'à l'insertion
/// pour préserver les contributions communautaires accumulées entre deux imports.
export async function upsertEvents(events: EventDoc[]): Promise<number> {
  if (events.length === 0) return 0;
  const { events: collection } = collections();

  const ops: AnyBulkWriteOperation<EventDoc>[] = events.map((e) => ({
    updateOne: {
      filter: { extId: e.extId },
      update: {
        $set: {
          name: e.name, kind: e.kind, location: e.location,
          startsAt: e.startsAt, endsAt: e.endsAt, address: e.address,
          recurrenceDays: e.recurrenceDays, source: e.source, updatedAt: new Date(),
        },
        $setOnInsert: {
          ownerUid: null,
          liveStatus: "scheduled",
          topTags: [] as string[],
          photoCount: 0,
        },
      },
      upsert: true,
    },
  }));

  const result = await collection.bulkWrite(ops, { ordered: false });
  return result.upsertedCount + result.modifiedCount;
}

/// Filtre les événements expirés : on garde ceux qui se terminent (ou démarrent,
/// à défaut de date de fin) après le seuil donné (par défaut : il y a 24 h).
export function keepUpcoming(events: EventDoc[], cutoff = Date.now() - 24 * 3600 * 1000): EventDoc[] {
  return events.filter((e) =>
    e.endsAt ? e.endsAt.getTime() >= cutoff : e.startsAt.getTime() >= cutoff,
  );
}
