import Foundation
import CoreLocation
import Combine

/// « Mon parcours de chine » : sélection de plusieurs événements et calcul d'un
/// ordre de visite optimisé (plus proche voisin depuis la position courante),
/// inspiré des « sale routes » de Yard Sale Treasure Map.
@MainActor
final class ParcoursStore: ObservableObject {
    @Published private(set) var selected: [SaleEvent] = []

    func contains(_ event: SaleEvent) -> Bool {
        selected.contains { $0.id == event.id }
    }

    func toggle(_ event: SaleEvent) {
        if contains(event) {
            selected = selected.filter { $0.id != event.id }
        } else {
            selected = selected + [event]
        }
    }

    func remove(_ event: SaleEvent) {
        selected = selected.filter { $0.id != event.id }
    }

    func clear() {
        selected = []
    }

    /// Ordre de visite optimisé par heuristique du plus proche voisin.
    func orderedRoute(from start: CLLocationCoordinate2D?) -> [SaleEvent] {
        guard let start else { return selected }
        var remaining = selected
        var route: [SaleEvent] = []
        var current = start
        while !remaining.isEmpty {
            guard let index = remaining.indices.min(by: {
                distance(current, remaining[$0].coordinate) < distance(current, remaining[$1].coordinate)
            }) else { break }
            let next = remaining.remove(at: index)
            route.append(next)
            current = next.coordinate
        }
        return route
    }

    /// Distance totale (mètres) du parcours optimisé, position de départ incluse.
    func totalDistance(from start: CLLocationCoordinate2D?) -> Double {
        let route = orderedRoute(from: start)
        guard !route.isEmpty else { return 0 }
        var total = 0.0
        var current = start ?? route[0].coordinate
        for event in route {
            total += distance(current, event.coordinate)
            current = event.coordinate
        }
        return total
    }

    private func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }
}
