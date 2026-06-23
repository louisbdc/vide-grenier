import Stripe from "stripe";
import { config } from "./config.js";

/// Client Stripe partagé. La clé secrète vient de l'environnement
/// (`STRIPE_SECRET_KEY`) — jamais committée. API version épinglée.
let client: Stripe | null = null;

export function stripe(): Stripe {
  if (!config.stripeSecretKey) {
    throw new Error("STRIPE_SECRET_KEY non configurée.");
  }
  if (!client) {
    client = new Stripe(config.stripeSecretKey, {
      apiVersion: "2026-05-27.dahlia" as Stripe.LatestApiVersion,
      appInfo: { name: "Vide-Grenier" },
    });
  }
  return client;
}

export const stripeEnabled = (): boolean => config.stripeSecretKey.length > 0;
