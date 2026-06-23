import type { FastifyInstance } from "fastify";
import { collections } from "../db.js";
import { uidFromRequest } from "../auth.js";
import { recomputeStatus, recomputeTags } from "../aggregate.js";
import { SignalType } from "../types.js";

const SIGNAL_TYPES: SignalType[] = ["ongoing", "crowded", "deserted", "emptied", "cancelled"];
const TAG_LABELS = [
  "puericulture", "mobilierVintage", "livresAnciens", "outils", "vinyles",
  "vetements", "jouets", "vaisselle", "bd", "hightech", "collection",
];

async function eventExists(eventId: string): Promise<boolean> {
  const doc = await collections().events.findOne({ extId: eventId }, { projection: { _id: 1 } });
  return doc !== null;
}

export default async function contributionRoutes(fastify: FastifyInstance): Promise<void> {
  // Signalement « terrain » — un seul par (événement, utilisateur, type).
  fastify.post("/events/:id/signals", async (request, reply) => {
    const uid = uidFromRequest(request);
    if (!uid) return reply.code(401).send({ error: "Authentification requise" });
    const { id } = request.params as { id: string };
    const type = String((request.body as { type?: string }).type ?? "") as SignalType;
    if (!SIGNAL_TYPES.includes(type)) return reply.code(400).send({ error: "Type invalide" });
    if (!(await eventExists(id))) return reply.code(404).send({ error: "Événement introuvable" });

    // Upsert : déduplique par utilisateur et rafraîchit l'horodatage (donc le TTL).
    await collections().signals.updateOne(
      { eventId: id, uid, type },
      { $set: { createdAt: new Date() } },
      { upsert: true },
    );
    await recomputeStatus(id);
    return reply.code(201).send({ ok: true });
  });

  // Tag d'inventaire — un seul par (événement, utilisateur, label).
  fastify.post("/events/:id/tags", async (request, reply) => {
    const uid = uidFromRequest(request);
    if (!uid) return reply.code(401).send({ error: "Authentification requise" });
    const { id } = request.params as { id: string };
    const label = String((request.body as { label?: string }).label ?? "");
    if (!TAG_LABELS.includes(label)) return reply.code(400).send({ error: "Label invalide" });
    if (!(await eventExists(id))) return reply.code(404).send({ error: "Événement introuvable" });

    await collections().tags.updateOne(
      { eventId: id, uid, label },
      { $set: { createdAt: new Date() } },
      { upsert: true },
    );
    await recomputeTags(id);
    return reply.code(201).send({ ok: true });
  });
}
