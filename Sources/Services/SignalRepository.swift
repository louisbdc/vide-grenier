import Foundation

/// Envoi des contributions communautaires : signalements de statut et tags
/// d'inventaire. L'auteur est identifié par le jeton ; l'agrégation (statut
/// live, top tags) est faite côté serveur.
@MainActor
struct SignalRepository {
    func submitSignal(eventId: String, type: SignalType, uid: String) async throws {
        let _: EmptyResponse = try await APIClient.shared.post(
            "events/\(eventId)/signals", body: ["type": type.rawValue]
        )
    }

    func submitTag(eventId: String, tag: InventoryTag, uid: String) async throws {
        let _: EmptyResponse = try await APIClient.shared.post(
            "events/\(eventId)/tags", body: ["label": tag.rawValue]
        )
    }
}
