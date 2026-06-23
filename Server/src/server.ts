import { resolve } from "node:path";
import Fastify from "fastify";
import cors from "@fastify/cors";
import multipart from "@fastify/multipart";
import fastifyStatic from "@fastify/static";
import websocket from "@fastify/websocket";
import cron from "node-cron";

import { config } from "./config.js";
import { connect } from "./db.js";
import { watchEvents, addSubscriber } from "./realtime.js";
import { runImport } from "./datatourisme.js";
import authRoutes from "./routes/auth.js";
import eventRoutes from "./routes/events.js";
import contributionRoutes from "./routes/contributions.js";
import photoRoutes from "./routes/photos.js";
import paymentRoutes from "./routes/payments.js";

async function main(): Promise<void> {
  await connect();

  const app = Fastify({ logger: true });
  await app.register(cors, { origin: config.corsOrigin });
  await app.register(multipart, { limits: { fileSize: 8 * 1024 * 1024 } });
  await app.register(fastifyStatic, {
    root: resolve(config.photosDir),
    prefix: "/photos/",
  });
  await app.register(websocket);

  await app.register(authRoutes);
  await app.register(eventRoutes);
  await app.register(contributionRoutes);
  await app.register(photoRoutes);
  await app.register(paymentRoutes);

  // Canal temps réel : l'app s'abonne à une zone et reçoit les mises à jour.
  app.register(async (instance) => {
    instance.get("/ws", { websocket: true }, (socket) => addSubscriber(socket));
  });

  app.get("/health", async () => ({ ok: true }));

  // Surveillance des changements MongoDB → push WebSocket.
  watchEvents();

  // Import DATAtourisme quotidien (4 h du matin).
  if (config.dataTourismeApiKey) {
    cron.schedule("0 4 * * *", async () => {
      try {
        const result = await runImport(config.dataTourismeApiKey);
        app.log.info(`Import DATAtourisme : ${JSON.stringify(result)}`);
      } catch (error) {
        app.log.error(error, "Import DATAtourisme échoué");
      }
    });
  }

  await app.listen({ port: config.port, host: "0.0.0.0" });
}

main().catch((error) => {
  console.error("Démarrage du serveur échoué:", error);
  process.exit(1);
});
