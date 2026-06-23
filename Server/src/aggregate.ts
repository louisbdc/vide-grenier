import { collections } from "./db.js";
import { LiveStatus } from "./types.js";

const SIGNAL_TTL_MS = 6 * 3600 * 1000;
const STATUS_PRIORITY: LiveStatus[] = ["cancelled", "emptied", "deserted", "crowded", "ongoing"];

/// Recalcule le statut « terrain » d'un événement à partir des signaux récents.
/// Seuil anti-bruit : au moins 2 signaux concordants pour basculer.
export async function recomputeStatus(eventId: string): Promise<void> {
  const { events, signals } = collections();
  const since = new Date(Date.now() - SIGNAL_TTL_MS);

  const recent = await signals.find({ eventId, createdAt: { $gte: since } }).toArray();
  const counts: Record<string, number> = {};
  for (const s of recent) counts[s.type] = (counts[s.type] ?? 0) + 1;

  let status: LiveStatus = "scheduled";
  let best = 0;
  for (const candidate of STATUS_PRIORITY) {
    const count = counts[candidate] ?? 0;
    if (count >= 2 && count >= best) {
      best = count;
      status = candidate;
    }
  }
  await events.updateOne({ extId: eventId }, { $set: { liveStatus: status, updatedAt: new Date() } });
}

/// Recalcule les 3 spécialités les plus signalées.
export async function recomputeTags(eventId: string): Promise<void> {
  const { events, tags } = collections();
  const all = await tags.find({ eventId }).toArray();
  const counts: Record<string, number> = {};
  for (const t of all) counts[t.label] = (counts[t.label] ?? 0) + 1;

  const topTags = Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([label]) => label);

  await events.updateOne({ extId: eventId }, { $set: { topTags, updatedAt: new Date() } });
}
