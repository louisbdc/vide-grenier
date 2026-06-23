import type { FastifyInstance } from "fastify";
import { issueToken } from "../auth.js";

export default async function authRoutes(fastify: FastifyInstance): Promise<void> {
  // Session anonyme : l'app envoie un deviceId stable, reçoit un JWT.
  fastify.post("/auth/anon", async (request, reply) => {
    const deviceId = String((request.body as { deviceId?: string }).deviceId ?? "").trim();
    if (deviceId.length < 8) return reply.code(400).send({ error: "deviceId invalide" });
    return issueToken(deviceId);
  });
}
