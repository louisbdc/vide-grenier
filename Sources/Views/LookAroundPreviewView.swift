import SwiftUI
import MapKit

/// Aperçu Look Around (≈ Street View Apple) pour évaluer le quartier et le
/// stationnement avant de s'y rendre — fonctionnalité plébiscitée sur YSTM.
struct LookAroundPreviewView: View {
    let coordinate: CLLocationCoordinate2D
    @State private var scene: MKLookAroundScene?
    @State private var unavailable = false

    var body: some View {
        Group {
            if let scene {
                LookAroundPreview(initialScene: scene)
            } else if unavailable {
                placeholder
            } else {
                ProgressView().frame(maxWidth: .infinity)
            }
        }
        .task { await loadScene() }
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(.gray.opacity(0.15))
            Label("Aperçu indisponible ici", systemImage: "binoculars")
                .foregroundStyle(.secondary)
        }
    }

    private func loadScene() async {
        let request = MKLookAroundSceneRequest(coordinate: coordinate)
        do {
            scene = try await request.scene
            if scene == nil { unavailable = true }
        } catch {
            unavailable = true
        }
    }
}
