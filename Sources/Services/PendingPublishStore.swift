import Foundation

/// Annonce payée mais dont la publication n'a pas encore abouti côté serveur.
/// Persistée pour ne JAMAIS perdre un paiement de 5 € en cas d'échec réseau :
/// on retentera la publication (sans re-payer) au prochain lancement.
struct PendingPublish: Codable, Equatable {
    let checkoutSessionId: String
    let name: String
    let kind: String
    let startsAt: Date
    let endsAt: Date?
    let latitude: Double
    let longitude: Double
}

enum PendingPublishStore {
    private static let key = "videgrenier.pendingPublish"

    static func save(_ pending: PendingPublish) {
        guard let data = try? JSONEncoder().encode(pending) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func load() -> PendingPublish? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(PendingPublish.self, from: data)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
