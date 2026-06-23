import Foundation

private struct CreatedEvent: Decodable {
    let id: String
}

/// Réponse de `POST /events/intent` : de quoi présenter le Payment Sheet Stripe.
struct ListingPaymentIntent: Decodable {
    let clientSecret: String
    let publishableKey: String
}

/// Création d'un événement crowdsourcé (payant : 5 € via Stripe).
/// Le serveur calcule la géolocalisation et vérifie le paiement.
@MainActor
struct EventCreationService {
    private static let isoFormatter = ISO8601DateFormatter()

    /// Crée le PaymentIntent de 5 € pour la publication.
    func createIntent() async throws -> ListingPaymentIntent {
        try await APIClient.shared.post("events/intent", body: [:])
    }

    /// Publie l'annonce une fois le paiement réglé (paymentIntentId vérifié serveur).
    func create(name: String,
                kind: SaleEventKind,
                startsAt: Date,
                endsAt: Date?,
                latitude: Double,
                longitude: Double,
                address: String?,
                paymentIntentId: String,
                uid: String) async throws -> String {
        var body: [String: Any] = [
            "name": name,
            "kind": kind.rawValue,
            "latitude": latitude,
            "longitude": longitude,
            "startsAt": Self.isoFormatter.string(from: startsAt),
            "paymentIntentId": paymentIntentId,
        ]
        if let endsAt { body["endsAt"] = Self.isoFormatter.string(from: endsAt) }
        if let address { body["address"] = address }

        let created: CreatedEvent = try await APIClient.shared.post("events", body: body)
        return created.id
    }
}
