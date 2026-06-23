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

export default async function contributionRoutes(fastify: FastifyInstance): Promise<void> {
  // Signalement « terrain ».
  fastify.post("/events/:id/signals", async (request, reply) => {
    const uid = uidFromRequest(request);
    if (!uid) return reply.code(401).send({ error: "Authentification requise" });
    const { id } = request.params as { id: string };
    const type = String((request.body as { type?: string }).type ?? "") as SignalType;
    if (!SIGNAL_TYPES.includes(type)) return reply.code(400).send({ error: "Type invalide" });

    await collections().signals.insertOne({ eventId: id, type, uid, createdAt: new Date() });
    await recomputeStatus(id);
    return reply.code(201).send({ ok: true });
  });

  // Tag d'inventaire.
  fastify.post("/events/:id/tags", async (request, reply) => {
    const uid = uidFromRequest(request);
    if (!uid) return reply.code(401).send({ error: "Authentification requise" });
    const { id } = request.params as { id: string };
    const label = String((request.body as { label?: string }).label ?? "");
    if (!TAG_LABELS.includes(label)) return reply.code(400).send({ error: "Label invalide" });

    await collections().tags.insertOne({ eventId: id, label, uid, createdAt: new Date() });
    await recomputeTags(id);
    return reply.code(201).send({ ok: true });
  });
}
