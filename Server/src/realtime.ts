import type { WebSocket } from "@fastify/websocket";
import { collections } from "./db.js";
import { EventDoc } from "./types.js";
import { serializeEvent } from "./serialize.js";

interface Subscriber {
  socket: WebSocket;
  lat: number;
  lng: number;
  radiusM: number;
}

const subscribers = new Set<Subscriber>();

function distanceMeters(aLat: number, aLng: number, bLat: number, bLng: number): number {
  const R = 6_371_000;
  const dLat = ((bLat - aLat) * Math.PI) / 180;
  const dLng = ((bLng - aLng) * Math.PI) / 180;
  const lat1 = (aLat * Math.PI) / 180;
  const lat2 = (bLat * Math.PI) / 180;
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

export function addSubscriber(socket: WebSocket): void {
  const sub: Subscriber = { socket, lat: 0, lng: 0, radiusM: 0 };
  subscribers.add(sub);

  socket.on("message", (raw: Buffer) => {
    try {
      const msg = JSON.parse(raw.toString());
      if (msg.type === "subscribe") {
        const lat = Number(msg.lat);
        const lng = Number(msg.lng);
        const radiusM = Number(msg.radiusM ?? msg.radius ?? 15000);
        if (!Number.isFinite(lat) || !Number.isFinite(lng) || !Number.isFinite(radiusM)) return;
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return;
        sub.lat = lat;
        sub.lng = lng;
        sub.radiusM = Math.min(Math.max(radiusM, 0), 200_000); // borne à 200 km
      }
    } catch {
      // message ignoré
    }
  });

  socket.on("close", () => subscribers.delete(sub));
  socket.on("error", () => subscribers.delete(sub));
}

/// Pousse un événement mis à jour aux abonnés dont la zone le contient.
function broadcast(doc: EventDoc): void {
  const [lng, lat] = doc.location.coordinates;
  const payload = JSON.stringify({ type: "event", event: serializeEvent(doc) });
  for (const sub of subscribers) {
    if (sub.radiusM <= 0) continue;
    if (distanceMeters(sub.lat, sub.lng, lat, lng) <= sub.radiusM) {
      try { sub.socket.send(payload); } catch { /* socket invalide */ }
    }
  }
}

/// Surveille les changements de la collection `events` (Change Streams) et
/// diffuse en temps réel. Les signaux/tags modifient l'événement via
/// l'agrégation, ce qui déclenche aussi un changement ici.
export function watchEvents(): void {
  const { events } = collections();
  const stream = events.watch([], { fullDocument: "updateLookup" });
  stream.on("change", (change) => {
    if ((change.operationType === "insert" || change.operationType === "update")
      && "fullDocument" in change && change.fullDocument) {
      broadcast(change.fullDocument as EventDoc);
    }
  });
  // Sans ce handler, une erreur (réélection du replica set, coupure) tuerait le
  // flux temps réel — voire le process. On relance après un court délai.
  stream.on("error", () => {
    stream.close().catch(() => {});
    setTimeout(watchEvents, 3000);
  });
}
