import Foundation
import CoreLocation

/// Élément affiché sur la carte : soit un événement isolé, soit un regroupement
/// (cluster) de plusieurs événements proches, pour rester lisible en zone dense.
enum MapAnnotationItem: Identifiable {
    case single(SaleEvent)
    case cluster(id: String, coordinate: CLLocationCoordinate2D, events: [SaleEvent])

    var id: String {
        switch self {
        case .single(let event): return event.id
        case .cluster(let id, _, _): return "cluster_\(id)"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .single(let event): return event.coordinate
        case .cluster(_, let coordinate, _): return coordinate
        }
    }

    var single: SaleEvent? {
        if case .single(let event) = self { return event }
        return nil
    }

    var clusterEvents: [SaleEvent]? {
        if case .cluster(_, _, let events) = self { return events }
        return nil
    }
}
