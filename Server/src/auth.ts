import jwt from "jsonwebtoken";
import { createHash } from "node:crypto";
import { config } from "./config.js";
import type { FastifyRequest } from "fastify";

/// Authentification anonyme : l'app génère un identifiant d'appareil au premier
/// lancement, l'échange contre un JWT, et le réutilise. Aucune identité réelle
/// n'est collectée. L'uid est dérivé du deviceId (hash) pour rester stable.
export function issueToken(deviceId: string): { uid: string; token: string } {
  const uid = createHash("sha256").update(deviceId).digest("hex").slice(0, 24);
  const token = jwt.sign({ sub: uid }, config.jwtSecret, { expiresIn: "365d" });
  return { uid, token };
}

/// Extrait l'uid d'un header Authorization: Bearer <jwt>, ou null.
export function uidFromRequest(request: FastifyRequest): string | null {
  const header = request.headers.authorization;
  if (!header?.startsWith("Bearer ")) return null;
  try {
    const payload = jwt.verify(header.slice(7), config.jwtSecret) as { sub: string };
    return payload.sub;
  } catch {
    return null;
  }
}
