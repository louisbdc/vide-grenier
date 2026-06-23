import type { FastifyInstance } from "fastify";
import { uidFromRequest } from "../auth.js";
import { config } from "../config.js";
import { stripe } from "../stripe.js";

export default async function paymentRoutes(fastify: FastifyInstance): Promise<void> {
  // Crée un PaymentIntent de 5 € pour la publication d'une annonce.
  // Renvoie le client secret (pour le Payment Sheet iOS) + la clé publique.
  fastify.post("/events/intent", async (request, reply) => {
    const uid = uidFromRequest(request);
    if (!uid) return reply.code(401).send({ error: "Authentification requise" });
    try {
      const intent = await stripe().paymentIntents.create({
        amount: config.listingPriceCents,
        currency: config.listingCurrency,
        // Pas de payment_method_types : on laisse Stripe gérer dynamiquement
        // les moyens de paiement (configurables depuis le Dashboard).
        automatic_payment_methods: { enabled: true },
        metadata: { uid, purpose: "listing" },
      });
      return {
        clientSecret: intent.client_secret,
        publishableKey: config.stripePublishableKey,
      };
    } catch (error) {
      request.log.error(error, "Création PaymentIntent échouée");
      return reply.code(502).send({ error: "Paiement indisponible" });
    }
  });
}
