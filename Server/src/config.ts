/// Configuration lue depuis l'environnement, validée au démarrage.
function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Variable d'environnement manquante : ${name}`);
  return value;
}

export const config = {
  port: Number(process.env.PORT ?? 8080),
  mongoUrl: process.env.MONGO_URL ?? "mongodb://127.0.0.1:27017/videgrenier?replicaSet=rs0",
  dbName: "videgrenier",
  jwtSecret: process.env.JWT_SECRET ?? "dev-insecure-secret-change-me",
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
  get jwtSecretChecked() {
    return required("JWT_SECRET");
  },
};
