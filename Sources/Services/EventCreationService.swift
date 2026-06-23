import Foundation

private struct CreatedEvent: Decodable {
    let id: String
}

/// Création d'un événement crowdsourcé. Le serveur calcule la géolocalisation
/// (2dsphere) et applique les règles (auteur = porteur du jeton).
@MainActor
struct EventCreationService {
    private static let isoFormatter = ISO8601DateFormatter()

    func create(name: String,
                kind: SaleEventKind,
                startsAt: Date,
                endsAt: Date?,
                latitude: Double,
                longitude: Double,
                address: String?,
                uid: String) async throws -> String {
        var body: [String: Any] = [
            "name": name,
            "kind": kind.rawValue,
            "latitude": latitude,
            "longitude": longitude,
            "startsAt": Self.isoFormatter.string(from: startsAt),
        ]
        if let endsAt { body["endsAt"] = Self.isoFormatter.string(from: endsAt) }
        if let address { body["address"] = address }

        let created: CreatedEvent = try await APIClient.shared.post("events", body: body)
        return created.id
    }
}
