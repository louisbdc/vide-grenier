import Foundation

/// Authentification anonyme : aucun écran de login au premier lancement.
///
/// L'app génère un identifiant d'appareil stable (persisté), l'échange contre un
/// JWT auprès du backend, et configure le client API. Aucune identité réelle.
protocol AuthServiceProtocol: Sendable {
    func ensureSignedIn() async throws -> String
}

private struct AnonAuthResponse: Decodable {
    let uid: String
    let token: String
}

struct AuthService: AuthServiceProtocol {
    private let deviceIdKey = "videgrenier.deviceId"

    func ensureSignedIn() async throws -> String {
        let response: AnonAuthResponse = try await APIClient.shared.post(
            "auth/anon", body: ["deviceId": deviceId()]
        )
        await APIClient.shared.setToken(response.token)
        return response.uid
    }

    private func deviceId() -> String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: deviceIdKey) { return existing }
        let generated = UUID().uuidString
        defaults.set(generated, forKey: deviceIdKey)
        return generated
    }
}
