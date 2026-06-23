import Foundation

private struct CreatedEvent: Decodable {
    let id: String
}

/// Réponse de `POST /events/checkout` : URL de la page Stripe + id de session.
struct ListingCheckout: Decodable {
    let url: String
    let sessionId: String
}

/// Création d'un événement crowdsourcé (payant : 5 € via Stripe Checkout).
/// Le serveur calcule la géolocalisation et vérifie le paiement.
@MainActor
struct EventCreationService {
    private static let isoFormatter = ISO8601DateFormatter()

    /// Crée la Checkout Session de 5 € pour la publication.
    func createCheckout() async throws -> ListingCheckout {
        try await APIClient.shared.post("events/checkout", body: [:])
    }

    /// Publie l'annonce une fois le paiement réglé (session vérifiée serveur).
    func create(name: String,
                kind: SaleEventKind,
                startsAt: Date,
                endsAt: Date?,
                latitude: Double,
                longitude: Double,
                address: String?,
                checkoutSessionId: String,
                uid: String) async throws -> String {
        var body: [String: Any] = [
            "name": name,
            "kind": kind.rawValue,
            "latitude": latitude,
            "longitude": longitude,
            "startsAt": Self.isoFormatter.string(from: startsAt),
            "checkoutSessionId": checkoutSessionId,
        ]
        if let endsAt { body["endsAt"] = Self.isoFormatter.string(from: endsAt) }
        if let address { body["address"] = address }

        let created: CreatedEvent = try await APIClient.shared.post("events", body: body)
        return created.id
    }
}
