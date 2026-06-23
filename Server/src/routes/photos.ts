import { randomUUID } from "node:crypto";
import { writeFile, mkdir } from "node:fs/promises";
import { join } from "node:path";
import type { FastifyInstance } from "fastify";
import { collections } from "../db.js";
import { uidFromRequest } from "../auth.js";
import { config } from "../config.js";

export default async function photoRoutes(fastify: FastifyInstance): Promise<void> {
  // Liste des photos (déjà floutées côté client) d'un événement.
  // On exclut les photos masquées (signalées). `authorId` permet à l'app de
  // bloquer un utilisateur localement.
  fastify.get("/events/:id/photos", async (request) => {
    const { id } = request.params as { id: string };
    const docs = await collections().photos
      .find({ eventId: id, hidden: { $ne: true } })
      .sort({ createdAt: -1 })
      .limit(30)
      .toArray();
    return docs.map((p) => ({
      id: p.id,
      url: p.url,
      authorId: p.uid,
      createdAt: p.createdAt.toISOString(),
    }));
  });

  // Upload d'une photo (multipart). L'image arrive déjà anonymisée du téléphone.
  fastify.post("/events/:id/photos", async (request, reply) => {
    const uid = uidFromRequest(request);
    if (!uid) return reply.code(401).send({ error: "Authentification requise" });
    const { id } = request.params as { id: string };

    // L'événement doit exister (pas de doc/photo orpheline).
    const exists = await collections().events.findOne({ extId: id }, { projection: { _id: 1 } });
    if (!exists) return reply.code(404).send({ error: "Événement introuvable" });

    const data = await request.file();
    if (!data || !data.mimetype.startsWith("image/")) {
      return reply.code(400).send({ error: "Image requise" });
    }

    await mkdir(config.photosDir, { recursive: true });
    // Nom de fichier = UUID seul : aucune donnée issue du client (anti path traversal).
    const photoId = randomUUID();
    const file = `${photoId}.jpg`;
    await writeFile(join(config.photosDir, file), await data.toBuffer());
    const url = `/photos/${file}`;

    await collections().photos.insertOne({
      id: photoId, eventId: id, file, url, uid,
      createdAt: new Date(), reporters: [], hidden: false,
    });
    await collections().events.updateOne(
      { extId: id },
      { $inc: { photoCount: 1 }, $set: { updatedAt: new Date() } },
    );
    return reply.code(201).send({ id: photoId, url });
  });

  // Signalement d'une photo (contenu inapproprié). Masquée automatiquement
  // dès qu'au moins SEUIL utilisateurs distincts l'ont signalée. Conformité
  // App Store 1.2 (modération du contenu généré par les utilisateurs).
  fastify.post("/photos/:photoId/report", async (request, reply) => {
    const uid = uidFromRequest(request);
    if (!uid) return reply.code(401).send({ error: "Authentification requise" });
    const { photoId } = request.params as { photoId: string };

    const updated = await collections().photos.findOneAndUpdate(
      { id: photoId },
      { $addToSet: { reporters: uid } },
      { returnDocument: "after" },
    );
    if (!updated) return reply.code(404).send({ error: "Photo introuvable" });

    const REPORT_THRESHOLD = 3;
    if (updated.reporters.length >= REPORT_THRESHOLD && !updated.hidden) {
      await collections().photos.updateOne({ id: photoId }, { $set: { hidden: true } });
    }
    return reply.code(201).send({ ok: true });
  });
}
