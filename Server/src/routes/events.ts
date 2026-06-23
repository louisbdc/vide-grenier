import { randomUUID } from "node:crypto";
import type { FastifyInstance } from "fastify";
import { collections } from "../db.js";
import { uidFromRequest } from "../auth.js";
import { serializeEvent } from "../serialize.js";
import { EventDoc, EventKind } from "../types.js";
import { config } from "../config.js";
import { stripe } from "../stripe.js";

/// Vérifie qu'un PaymentIntent correspond bien à un paiement d'annonce valide,
/// réglé par l'utilisateur courant (montant et devise attendus).
async function assertPaidListing(paymentIntentId: string, uid: string): Promise<boolean> {
  try {
    const intent = await stripe().paymentIntents.retrieve(paymentIntentId);
    return intent.status === "succeeded"
      && intent.amount === config.listingPriceCents
      && intent.currency === config.listingCurrency
      && intent.metadata?.uid === uid;
  } catch {
    return false;
  }
}

const KINDS: EventKind[] = ["videGrenier", "brocante", "marcheAuxPuces", "braderie", "autre"];

export default async function eventRoutes(fastify: FastifyInstance): Promise<void> {
  // Liste des événements dans un rayon (km) autour d'un point.
  fastify.get("/events", async (request, reply) => {
    const q = request.query as Record<string, string>;
    const lat = Number(q.lat);
    const lng = Number(q.lng);
    const radiusKm = Number(q.radius ?? 15);
    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      return reply.code(400).send({ error: "lat et lng requis" });
    }

    const cutoff = new Date(Date.now() - 24 * 3600 * 1000);
    const docs = await collections().events
      .find({
        location: {
          $nearSphere: {
            $geometry: { type: "Point", coordinates: [lng, lat] },
            $maxDistance: radiusKm * 1000,
          },
        },
        $or: [{ endsAt: { $gte: cutoff } }, { endsAt: null, startsAt: { $gte: cutoff } }],
      })
      .limit(500)
      .toArray();

    return docs.map(serializeEvent);
  });

  // Création d'un événement crowdsourcé (authentification requise).
  fastify.post("/events", async (request, reply) => {
    const uid = uidFromRequest(request);
    if (!uid) return reply.code(401).send({ error: "Authentification requise" });

    const b = request.body as Record<string, unknown>;
    const name = String(b.name ?? "").trim();
    const kind = String(b.kind ?? "") as EventKind;
    const latitude = Number(b.latitude);
    const longitude = Number(b.longitude);
    const startsAt = b.startsAt ? new Date(String(b.startsAt)) : null;
    const paymentIntentId = String(b.paymentIntentId ?? "");

    if (!name || !KINDS.includes(kind) || !Number.isFinite(latitude)
      || !Number.isFinite(longitude) || !startsAt || Number.isNaN(startsAt.getTime())) {
      return reply.code(400).send({ error: "Champs invalides" });
    }

    // Publier une annonce coûte 5 € : on exige un paiement Stripe validé.
    if (!paymentIntentId || !(await assertPaidListing(paymentIntentId, uid))) {
      return reply.code(402).send({ error: "Paiement requis ou non validé" });
    }

    const doc: EventDoc = {
      extId: randomUUID(),
      name,
      kind,
      location: { type: "Point", coordinates: [longitude, latitude] },
      startsAt,
      endsAt: b.endsAt ? new Date(String(b.endsAt)) : null,
      address: b.address ? String(b.address) : null,
      recurrenceDays: [],
      source: "crowdsourced",
      ownerUid: uid,
      liveStatus: "scheduled",
      topTags: [],
      photoCount: 0,
      updatedAt: new Date(),
      paymentIntentId,
    };
    try {
      await collections().events.insertOne(doc);
    } catch (error) {
      // Violation d'unicité = PaymentIntent déjà utilisé pour une autre annonce.
      if ((error as { code?: number }).code === 11000) {
        return reply.code(409).send({ error: "Paiement déjà utilisé" });
      }
      throw error;
    }
    return reply.code(201).send(serializeEvent(doc));
  });
}
