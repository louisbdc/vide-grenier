import Foundation
import CoreLocation
import MapKit
import SwiftUI
import Combine

/// Pilote la carte : centre, rayon de recherche modulable, et flux temps réel
/// des événements alentour.
@MainActor
final class MapViewModel: ObservableObject {
    @Published var radiusKm: Double = 15
    @Published private(set) var events: [SaleEvent] = []
    @Published var selectedKinds: Set<SaleEventKind> = Set(SaleEventKind.allCases)
    @Published var searchText = ""
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published private(set) var isLoading = false
    @Published private(set) var hasLoadedOnce = false
    @Published private(set) var lastError: AppError?

    /// Région visible courante, mise à jour au déplacement de la carte ; sert au
    /// regroupement (clustering) adapté au zoom.
    @Published var visibleRegion: MKCoordinateRegion?

    /// Événements affichés après filtrage par type et recherche par nom.
    var visibleEvents: [SaleEvent] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return events.filter { event in
            guard !BlockStore.isBlocked(event.authorId) else { return false }
            guard selectedKinds.contains(event.kind) else { return false }
            guard !query.isEmpty else { return true }
            // localizedStandardContains : insensible à la casse et aux accents.
            return event.name.localizedStandardContains(query)
        }
    }

    /// Épingles et clusters à afficher sur la carte au zoom courant.
    var annotationItems: [MapAnnotationItem] {
        Clustering.items(events: visibleEvents, region: visibleRegion)
    }

    /// Zoome sur l'emprise d'un cluster lorsqu'on le tape.
    func zoom(into events: [SaleEvent]) {
        guard let region = Clustering.boundingRegion(for: events) else { return }
        cameraPosition = .region(region)
    }

    func toggleKind(_ kind: SaleEventKind) {
        if selectedKinds.contains(kind) {
            selectedKinds.remove(kind)
        } else {
            selectedKinds.insert(kind)
        }
    }

    private let repository = EventRepository()
    private var didCenterOnUser = false
    private var lastSearchCenter: CLLocationCoordinate2D?

    /// Vrai quand la carte a été déplacée loin du dernier centre recherché :
    /// on propose alors « Rechercher dans cette zone ».
    var canSearchHere: Bool {
        guard let region = visibleRegion, let last = lastSearchCenter else { return false }
        let moved = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
            .distance(from: CLLocation(latitude: last.latitude, longitude: last.longitude))
        return moved > max(radiusKm * 1000 * 0.4, 1500)
    }

    /// Relance la recherche au centre actuel de la carte (sans recentrer).
    func searchHere() {
        guard let region = visibleRegion else { return }
        refresh(center: region.center)
    }

    /// Rayons proposés à l'utilisateur (km).
    let radiusOptions: [Double] = [5, 10, 15, 25, 50]

    /// Centre la carte sur l'utilisateur au premier point reçu, puis observe.
    func onUserLocation(_ coordinate: CLLocationCoordinate2D?) {
        guard let coordinate else { return }
        if !didCenterOnUser {
            didCenterOnUser = true
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: radiusKm * 2_000,
                longitudinalMeters: radiusKm * 2_000
            ))
        }
        refresh(center: coordinate)
    }

    /// Relance l'observation autour d'un centre donné (ex: après déplacement
    /// de la carte ou changement de rayon).
    func refresh(center: CLLocationCoordinate2D) {
        isLoading = true
        lastSearchCenter = center
        repository.observe(center: center, radius: radiusKm * 1_000) { [weak self] events in
            Task { @MainActor in
                guard let self else { return }
                self.events = events
                self.isLoading = false
                self.hasLoadedOnce = true
            }
        }
    }

    func radiusChanged(center: CLLocationCoordinate2D?) {
        guard let center else { return }
        refresh(center: center)
    }
}
