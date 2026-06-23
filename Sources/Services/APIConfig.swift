import Foundation

/// Adresse du backend. Surchargée par la variable d'environnement
/// `API_BASE_URL` (pratique en simulateur / CI), sinon localhost en dev.
///
/// En production, mets l'URL HTTPS de ton VPS (ex: https://api.tondomaine.fr).
enum APIConfig {
    static var baseURL: URL {
        let raw = ProcessInfo.processInfo.environment["API_BASE_URL"]
            ?? "http://127.0.0.1:8080"
        return URL(string: raw)!
    }

    /// URL WebSocket dérivée de la base (http→ws, https→wss).
    static var webSocketURL: URL {
        var components = URLComponents(url: baseURL.appendingPathComponent("ws"),
                                       resolvingAgainstBaseURL: false)!
        components.scheme = (components.scheme == "https") ? "wss" : "ws"
        return components.url!
    }
}
