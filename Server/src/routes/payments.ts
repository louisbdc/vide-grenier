import type { FastifyInstance } from "fastify";
import { uidFromRequest } from "../auth.js";
import { config } from "../config.js";
import { stripe } from "../stripe.js";

const APP_SCHEME = "videgrenier";

export default async function paymentRoutes(fastify: FastifyInstance): Promise<void> {
  // Crée une Checkout Session Stripe (page de paiement hébergée) de 5 €
  // pour la publication d'une annonce. Renvoie l'URL à ouvrir + l'id de session.
  fastify.post("/events/checkout", async (request, reply) => {
    const uid = uidFromRequest(request);
    if (!uid) return reply.code(401).send({ error: "Authentification requise" });
    try {
      const session = await stripe().checkout.sessions.create({
        mode: "payment",
        line_items: [{
          quantity: 1,
          price_data: {
            currency: config.listingCurrency,
            unit_amount: config.listingPriceCents,
            product_data: { name: "Publication d'une annonce vide-grenier" },
          },
        }],
        success_url: `${config.publicUrl}/pay/return?session_id={CHECKOUT_SESSION_ID}`,
        cancel_url: `${config.publicUrl}/pay/cancel`,
        metadata: { uid, purpose: "listing" },
      });
      return { url: session.url, sessionId: session.id };
    } catch (error) {
      request.log.error(error, "Création Checkout Session échouée");
      return reply.code(502).send({ error: "Paiement indisponible" });
    }
  });

  // Pages de retour : redirigent vers l'app (schéma personnalisé) après paiement.
  fastify.get("/pay/return", async (_request, reply) => {
    reply.type("text/html").send(returnPage("done", "Paiement reçu ✅"));
  });
  fastify.get("/pay/cancel", async (_request, reply) => {
    reply.type("text/html").send(returnPage("cancel", "Paiement annulé"));
  });
}

function returnPage(path: string, title: string): string {
  const target = `${APP_SCHEME}://${path}`;
  return `<!doctype html><html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title}</title>
<script>setTimeout(function(){location.replace(${JSON.stringify(target)})},400)</script>
<style>body{font-family:-apple-system,sans-serif;text-align:center;padding:48px;color:#2a221e;background:#fbf7ee}</style>
</head><body><h2>${title}</h2><p>Retour à l'application…</p>
<p><a href="${target}">Revenir à Vide-Grenier</a></p></body></html>`;
}
