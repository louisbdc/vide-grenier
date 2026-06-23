import Foundation
import MapKit

/// Regroupement d'événements par grille, adapté au niveau de zoom courant.
///
/// On découpe la région visible en une grille `gridSize × gridSize` : les
/// événements tombant dans la même cellule sont fusionnés en un cluster
/// positionné sur leur barycentre. En dézoomant, les clusters grossissent ;
/// en zoomant, ils se scindent jusqu'aux épingles individuelles.
enum Clustering {
    static func items(events: [SaleEvent],
                      region: MKCoordinateRegion?,
                      gridSize: Int = 9) -> [MapAnnotationItem] {
        guard
            let region,
            region.span.latitudeDelta > 0,
            region.span.longitudeDelta > 0
        else {
            return events.map(MapAnnotationItem.single)
        }

        let cellLat = region.span.latitudeDelta / Double(gridSize)
        let cellLon = region.span.longitudeDelta / Double(gridSize)

        var buckets: [String: [SaleEvent]] = [:]
        for event in events {
            let row = Int((event.latitude / cellLat).rounded(.down))
            let col = Int((event.longitude / cellLon).rounded(.down))
            buckets["\(row)_\(col)", default: []].append(event)
        }

        return buckets.map { key, group in
            guard group.count > 1 else { return .single(group[0]) }
            let count = Double(group.count)
            let lat = group.reduce(0) { $0 + $1.latitude } / count
            let lon = group.reduce(0) { $0 + $1.longitude } / count
            return .cluster(
                id: key,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                events: group
            )
        }
    }

    /// Région englobant un groupe d'événements, avec une marge, pour zoomer
    /// dessus quand l'utilisateur tape un cluster.
    static func boundingRegion(for events: [SaleEvent]) -> MKCoordinateRegion? {
        guard !events.isEmpty else { return nil }
        let lats = events.map(\.latitude)
        let lons = events.map(\.longitude)
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.6, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.6, 0.01)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
