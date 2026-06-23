/// Configuration lue depuis l'environnement, validée au démarrage (voir
/// `assertConfig` dans server.ts qui refuse de démarrer sans secrets sûrs).
export const config = {
  port: Number(process.env.PORT ?? 8080),
  mongoUrl: process.env.MONGO_URL ?? "mongodb://127.0.0.1:27017/videgrenier?replicaSet=rs0",
  dbName: "videgrenier",
  // Aucun défaut : un secret vide est rejeté au démarrage (auth non forgeable).
  jwtSecret: process.env.JWT_SECRET ?? "",
  dataTourismeApiKey: process.env.DATATOURISME_API_KEY ?? "",
  photosDir: process.env.PHOTOS_DIR ?? "./data/photos",
  corsOrigin: process.env.CORS_ORIGIN ?? "*",
  // Stripe : publication d'une annonce = 5,00 € (500 centimes).
  stripeSecretKey: process.env.STRIPE_SECRET_KEY ?? "",
  stripePublishableKey: process.env.STRIPE_PUBLISHABLE_KEY ?? "",
  listingPriceCents: 500,
  listingCurrency: "eur",
  // URL publique du backend (pour les redirections Stripe Checkout).
  publicUrl: process.env.PUBLIC_URL ?? "https://vps-03f913ed.vps.ovh.net",
};
