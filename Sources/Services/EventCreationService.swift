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
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Crée la Checkout Session de 5 € pour la publication.
    func createCheckout() async throws -> ListingCheckout {
        try await APIClient.shared.post("events/checkout", body: [:])
    }

    /// Publie une annonce déjà payée (session vérifiée serveur). Idempotent :
    /// utilisé aussi pour retenter une publication en attente sans re-payer.
    @discardableResult
    func publish(_ pending: PendingPublish) async throws -> String {
        var body: [String: Any] = [
            "name": pending.name,
            "kind": pending.kind,
            "latitude": pending.latitude,
            "longitude": pending.longitude,
            "startsAt": Self.isoFormatter.string(from: pending.startsAt),
            "checkoutSessionId": pending.checkoutSessionId,
        ]
        if let endsAt = pending.endsAt {
            body["endsAt"] = Self.isoFormatter.string(from: endsAt)
        }
        let created: CreatedEvent = try await APIClient.shared.post("events", body: body)
        return created.id
    }

}
