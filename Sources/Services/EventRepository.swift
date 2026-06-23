import Foundation
import CoreLocation

/// Enveloppe d'un message temps réel du backend.
private struct WSEvent: Decodable {
    let type: String
    let event: SaleEvent
}

/// Accès aux événements autour d'un point : chargement initial via REST, puis
/// mises à jour en direct via WebSocket (alimenté par les Change Streams Mongo).
///
/// Reconnexion automatique avec backoff exponentiel : indispensable en mobilité
/// (perte de réseau, passage 4G/Wi-Fi). À la reconnexion, on recharge l'état via
/// REST pour ne pas manquer les changements survenus pendant la coupure.
@MainActor
final class EventRepository {
    private var socket: URLSessionWebSocketTask?
    private var cache: [String: SaleEvent] = [:]
    private var onChange: (([SaleEvent]) -> Void)?

    private var center: CLLocationCoordinate2D?
    private var radiusMeters: Double = 0
    private var shouldStayConnected = false
    private var reconnectAttempt = 0
    private let maxBackoffSeconds: Double = 30

    /// Charge puis écoute les événements dans un rayon (mètres) autour du centre.
    func observe(center: CLLocationCoordinate2D,
                 radius: Double,
                 onChange: @escaping ([SaleEvent]) -> Void) {
        stop()
        self.onChange = onChange
        self.center = center
        self.radiusMeters = radius
        self.shouldStayConnected = true
        self.reconnectAttempt = 0
        cache = [:]
        Task {
            await fetchInitial()
            subscribe()
        }
    }

    private func fetchInitial() async {
        guard let center else { return }
        do {
            let list: [SaleEvent] = try await APIClient.shared.get("events", query: [
                "lat": String(center.latitude),
                "lng": String(center.longitude),
                "radius": String(radiusMeters / 1000),
            ])
            cache = Dictionary(list.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            emit()
        } catch {
            // Échec réseau : on garde le cache et on laissera la reconnexion réessayer.
        }
    }

    private func subscribe() {
        guard let center else { return }
        let task = URLSession.shared.webSocketTask(with: APIConfig.webSocketURL)
        socket = task
        task.resume()

        let message: [String: Any] = [
            "type": "subscribe",
            "lat": center.latitude,
            "lng": center.longitude,
            "radiusM": radiusMeters,
        ]
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let text = String(data: data, encoding: .utf8) {
            task.send(.string(text)) { _ in }
        }
        receive(task)
    }

    private func receive(_ task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message, let data = text.data(using: .utf8),
                   let envelope = try? APIClient.decoder.decode(WSEvent.self, from: data) {
                    Task { @MainActor [weak self] in self?.merge(envelope.event) }
                }
                Task { @MainActor [weak self] in
                    guard let self, self.socket === task else { return }
                    self.reconnectAttempt = 0
                    self.receive(task)
                }
            case .failure:
                Task { @MainActor [weak self] in
                    guard let self, self.socket === task else { return }
                    self.scheduleReconnect()
                }
            }
        }
    }

    /// Replanifie une connexion après une coupure, avec backoff exponentiel borné.
    private func scheduleReconnect() {
        guard shouldStayConnected else { return }
        socket = nil
        let delay = min(pow(2, Double(reconnectAttempt)), maxBackoffSeconds)
        reconnectAttempt += 1
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard let self, self.shouldStayConnected else { return }
            await self.fetchInitial()   // rattrape les changements manqués
            self.subscribe()
        }
    }

    /// Le serveur ne pousse que les événements de la zone abonnée : on fusionne.
    private func merge(_ event: SaleEvent) {
        cache[event.id] = event
        emit()
    }

    private func emit() {
        let sorted = cache.values.sorted { $0.startsAt < $1.startsAt }
        onChange?(sorted)
    }

    func stop() {
        shouldStayConnected = false
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
    }

    deinit {
        socket?.cancel(with: .goingAway, reason: nil)
    }
}
