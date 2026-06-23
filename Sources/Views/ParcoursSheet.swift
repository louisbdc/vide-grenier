import SwiftUI
import MapKit
import CoreLocation

/// « Mon parcours de chine » : événements sélectionnés, ordonnés par trajet
/// optimisé, avec tracé sur la carte et lancement de la navigation.
struct ParcoursSheet: View {
    @EnvironmentObject private var parcours: ParcoursStore
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss

    private var route: [SaleEvent] {
        parcours.orderedRoute(from: session.location.coordinate)
    }

    private var routeCoordinates: [CLLocationCoordinate2D] {
        var coords: [CLLocationCoordinate2D] = []
        if let here = session.location.coordinate { coords.append(here) }
        coords.append(contentsOf: route.map(\.coordinate))
        return coords
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                map
                summaryBar
                stopList
            }
            .background(Theme.paper)
            .navigationTitle("Mon parcours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Vider") { parcours.clear() }
                        .disabled(parcours.selected.isEmpty)
                }
            }
        }
    }

    private var map: some View {
        Map {
            if routeCoordinates.count > 1 {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2, 8]))
            }
            ForEach(Array(route.enumerated()), id: \.element.id) { index, event in
                Annotation(event.name, coordinate: event.coordinate) {
                    numberPin(index + 1)
                }
            }
            UserAnnotation()
        }
        .frame(height: 280)
    }

    private func numberPin(_ number: Int) -> some View {
        ZStack {
            Circle().fill(Theme.accent.gradient).frame(width: 32, height: 32)
            Circle().stroke(.white, lineWidth: 2.5)
            Text("\(number)").font(Theme.display(15, .heavy)).foregroundStyle(.white)
        }
        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    }

    private var summaryBar: some View {
        HStack {
            Label("\(route.count) arrêts", systemImage: "flag.checkered")
            Spacer()
            if parcours.selected.count > 0 {
                Label(distanceText, systemImage: "figure.walk")
            }
        }
        .font(Theme.display(15, .semibold))
        .foregroundStyle(Theme.ink)
        .padding(.horizontal, 20).padding(.vertical, 14)
    }

    @ViewBuilder private var stopList: some View {
        if parcours.selected.isEmpty {
            ContentUnavailableView(
                "Parcours vide",
                systemImage: "map",
                description: Text("Ajoute des événements à ton parcours depuis leur fiche.")
            )
            .frame(maxHeight: .infinity)
        } else {
            List {
                ForEach(Array(route.enumerated()), id: \.element.id) { index, event in
                    stopRow(index + 1, event)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) { launchButton }
        }
    }

    private func stopRow(_ number: Int, _ event: SaleEvent) -> some View {
        HStack(spacing: 12) {
            numberPin(number)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.name).font(Theme.display(15, .semibold)).lineLimit(1)
                Text(event.kind.label).font(.caption).foregroundStyle(Theme.ink.opacity(0.55))
            }
            Spacer()
            Button {
                parcours.remove(event)
            } label: {
                Image(systemName: "minus.circle.fill").foregroundStyle(.secondary)
            }
        }
        .listRowBackground(Color.clear)
    }

    private var launchButton: some View {
        Button { launchNavigation() } label: {
            Label("Lancer l'itinéraire", systemImage: "location.north.line.fill")
                .font(Theme.display(17, .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        .tint(Theme.accent)
        .padding(16)
    }

    private var distanceText: String {
        let meters = parcours.totalDistance(from: session.location.coordinate)
        return meters < 1000 ? "\(Int(meters)) m" : String(format: "%.1f km", meters / 1000)
    }

    private func launchNavigation() {
        let stops = route.map { event -> MKMapItem in
            let item = MKMapItem(placemark: MKPlacemark(coordinate: event.coordinate))
            item.name = event.name
            return item
        }
        let items = [MKMapItem.forCurrentLocation()] + stops
        MKMapItem.openMaps(with: items, launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}
