import Foundation

/// Adresse du backend. Par défaut : la **production** (VPS OVH, HTTPS).
/// Surchargée par la variable d'environnement `API_BASE_URL` pour le dev local
/// (ex: `API_BASE_URL=http://127.0.0.1:8080`).
enum APIConfig {
    static var baseURL: URL {
        let raw = ProcessInfo.processInfo.environment["API_BASE_URL"]
            ?? "https://vps-03f913ed.vps.ovh.net"
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
