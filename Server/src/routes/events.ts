import { randomUUID } from "node:crypto";
import type { FastifyInstance } from "fastify";
import { collections } from "../db.js";
import { uidFromRequest } from "../auth.js";
import { serializeEvent } from "../serialize.js";
import { EventDoc, EventKind } from "../types.js";
import { config } from "../config.js";
import { stripe } from "../stripe.js";

/// Vérifie qu'une Checkout Session correspond bien à un paiement d'annonce
/// réglé (payment_status=paid) par l'utilisateur courant, au bon montant.
async function assertPaidListing(sessionId: string, uid: string): Promise<boolean> {
  try {
    const session = await stripe().checkout.sessions.retrieve(sessionId);
    return session.payment_status === "paid"
      && session.amount_total === config.listingPriceCents
      && session.currency === config.listingCurrency
      && session.metadata?.uid === uid;
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
    if (!Number.isFinite(lat) || !Number.isFinite(lng)
      || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return reply.code(400).send({ error: "lat/lng invalides" });
    }
    // Rayon borné : évite un $maxDistance négatif (erreur Mongo) ou un scan énorme.
    const rawRadius = Number(q.radius ?? 15);
    const radiusKm = Number.isFinite(rawRadius) ? Math.min(Math.max(rawRadius, 1), 200) : 15;

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
    const checkoutSessionId = String(b.checkoutSessionId ?? "");

    const endsAt = b.endsAt ? new Date(String(b.endsAt)) : null;
    if (!name || name.length > 120 || !KINDS.includes(kind)
      || !Number.isFinite(latitude) || latitude < -90 || latitude > 90
      || !Number.isFinite(longitude) || longitude < -180 || longitude > 180
      || !startsAt || Number.isNaN(startsAt.getTime())
      || (endsAt && (Number.isNaN(endsAt.getTime()) || endsAt < startsAt))
      || (b.address != null && String(b.address).length > 200)) {
      return reply.code(400).send({ error: "Champs invalides" });
    }

    // Publier une annonce coûte 5 € : on exige un paiement Stripe validé.
    if (!checkoutSessionId || !(await assertPaidListing(checkoutSessionId, uid))) {
      return reply.code(402).send({ error: "Paiement requis ou non validé" });
    }

    const doc: EventDoc = {
      extId: randomUUID(),
      name,
      kind,
      location: { type: "Point", coordinates: [longitude, latitude] },
      startsAt,
      endsAt,
      address: b.address ? String(b.address) : null,
      recurrenceDays: [],
      source: "crowdsourced",
      ownerUid: uid,
      liveStatus: "scheduled",
      topTags: [],
      photoCount: 0,
      updatedAt: new Date(),
      checkoutSessionId,
    };
    try {
      await collections().events.insertOne(doc);
    } catch (error) {
      // Violation d'unicité = session de paiement déjà utilisée pour une annonce.
      if ((error as { code?: number }).code === 11000) {
        return reply.code(409).send({ error: "Paiement déjà utilisé" });
      }
      throw error;
    }
    return reply.code(201).send(serializeEvent(doc));
  });
}
