import SwiftUI
import MapKit
import CoreLocation

/// Détail d'un événement : hero coloré selon le type, aperçu Look Around,
/// spécialités, photos, et actions communautaires. Style « Carnet de chine ».
struct EventDetailSheet: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var parcours: ParcoursStore
    @StateObject private var viewModel = EventDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showCamera = false
    let event: SaleEvent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero

                VStack(alignment: .leading, spacing: 22) {
                    LookAroundPreviewView(coordinate: event.coordinate)
                        .frame(height: 175)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    if !event.topTags.isEmpty {
                        section("Spécialités repérées") { specialitiesRow }
                    }
                    if !viewModel.gallery.isEmpty {
                        section("Photos des allées") { photoGallery }
                    }

                    section("Que vois-tu sur place ?") {
                        SignalBar { type in
                            Task { await viewModel.submitSignal(type, eventId: event.id, uid: session.uid) }
                        }
                    }
                    section("Qu'est-ce qu'on y trouve ?") {
                        TagChipsView { tag in
                            Task { await viewModel.submitTag(tag, eventId: event.id, uid: session.uid) }
                        }
                    }

                    addPhotoButton
                    feedback
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Theme.paper)
        .scrollIndicators(.hidden)
        .overlay(alignment: .topTrailing) { closeButton }
        .sheet(isPresented: $showCamera) {
            PhotoCaptureView { image in
                Task { await viewModel.uploadPhoto(image, eventId: event.id, uid: session.uid) }
            }
        }
        .task { await viewModel.loadPhotos(eventId: event.id) }
    }

    // MARK: - Hero

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [event.kind.color, event.kind.color.opacity(0.78)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(event.kind.label.uppercased())
                        .font(Theme.display(12, .heavy))
                        .tracking(0.5)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(.white.opacity(0.25), in: Capsule())
                    statusBadge
                }
                Text(event.name)
                    .font(Theme.display(26, .heavy))
                    .lineLimit(3)
                infoLine("calendar", event.startsAt.formatted(date: .abbreviated, time: .shortened))
                if let address = event.address {
                    infoLine("mappin.and.ellipse", address)
                }
                if let distanceText {
                    infoLine("figure.walk", distanceText)
                }
                HStack(spacing: 10) {
                    itineraryButton
                    parcoursButton
                }
                .padding(.top, 6)
            }
            .foregroundStyle(.white)
            .padding(20)
            .padding(.top, 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var itineraryButton: some View {
        Button { openDirections() } label: {
            Label("Itinéraire", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                .font(Theme.display(15, .bold))
                .foregroundStyle(event.kind.color)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.white, in: Capsule())
        }
    }

    private var parcoursButton: some View {
        let inRoute = parcours.contains(event)
        return Button {
            parcours.toggle(event)
        } label: {
            Label(inRoute ? "Dans le parcours" : "Au parcours",
                  systemImage: inRoute ? "checkmark.circle.fill" : "plus.circle.fill")
                .font(Theme.display(15, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(.white.opacity(0.22), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 1))
        }
    }

    private var distanceText: String? {
        guard let here = session.location.coordinate else { return nil }
        let meters = CLLocation(latitude: here.latitude, longitude: here.longitude)
            .distance(from: CLLocation(latitude: event.latitude, longitude: event.longitude))
        return meters < 1000
            ? "À \(Int(meters)) m"
            : String(format: "À %.1f km", meters / 1000)
    }

    private func openDirections() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: event.coordinate))
        item.name = event.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    @ViewBuilder private var statusBadge: some View {
        if event.liveStatus != .scheduled {
            Label(event.liveStatus.label, systemImage: event.liveStatus.systemImage)
                .font(Theme.display(12, .bold))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(.white, in: Capsule())
                .foregroundStyle(event.liveStatus.tint)
        }
    }

    private func infoLine(_ icon: String, _ text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white.opacity(0.95))
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .padding(16)
    }

    // MARK: - Sections

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(Theme.display(18, .bold))
                .foregroundStyle(Theme.ink)
            content()
        }
    }

    private var specialitiesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(event.topTags) { tag in
                    HStack(spacing: 6) {
                        Text(tag.emoji)
                        Text(tag.label).font(Theme.display(14, .semibold))
                    }
                    .foregroundStyle(event.kind.color)
                    .padding(.horizontal, 13).padding(.vertical, 9)
                    .background(event.kind.color.opacity(0.13), in: Capsule())
                }
            }
        }
    }

    private var photoGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.gallery) { photo in
                    AsyncImage(url: URL(string: photo.url)) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        case .failure: Image(systemName: "photo").foregroundStyle(.secondary)
                        default: ProgressView()
                        }
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .contextMenu {
                        Button(role: .destructive) {
                            Task { await viewModel.report(photo: photo, eventId: event.id) }
                        } label: { Label("Signaler cette photo", systemImage: "flag") }
                        Button(role: .destructive) {
                            Task { await viewModel.block(authorId: photo.authorId, eventId: event.id) }
                        } label: { Label("Bloquer cet utilisateur", systemImage: "hand.raised") }
                    }
                }
            }
        }
    }

    private var addPhotoButton: some View {
        VStack(spacing: 6) {
            Button { showCamera = true } label: {
                Label("Ajouter une photo", systemImage: "camera.fill")
                    .font(Theme.display(16, .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .tint(Theme.ink)
            Text("Visages & plaques floutés automatiquement sur ton téléphone")
                .font(.caption2).foregroundStyle(Theme.ink.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    @ViewBuilder private var feedback: some View {
        if let confirmation = viewModel.confirmation {
            Label(confirmation, systemImage: "checkmark.seal.fill")
                .foregroundStyle(Theme.teal).font(.footnote.weight(.medium))
        }
        if let error = viewModel.error {
            Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.terracotta).font(.footnote.weight(.medium))
        }
    }
}
