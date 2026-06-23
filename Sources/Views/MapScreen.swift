import SwiftUI
import MapKit
import UIKit

/// Écran principal : carte plein écran, contrôles flottants en Liquid Glass
/// (matériau natif iOS 26, teinté terracotta), épingles colorées par type.
struct MapScreen: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var parcours: ParcoursStore
    @StateObject private var viewModel = MapViewModel()
    @Environment(\.openURL) private var openURL
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var selectedEvent: SaleEvent?
    @State private var showCreate = false
    @State private var showParcours = false

    private let fallbackCenter = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)

    var body: some View {
        Map(position: $viewModel.cameraPosition) {
            UserAnnotation()
            ForEach(viewModel.annotationItems) { item in
                if let event = item.single {
                    Annotation(event.name, coordinate: event.coordinate) {
                        EventAnnotationView(event: event, isSelected: parcours.contains(event))
                            .onTapGesture { selectedEvent = event }
                    }
                } else if let group = item.clusterEvents {
                    Annotation("", coordinate: item.coordinate) {
                        ClusterAnnotationView(count: group.count)
                            .onTapGesture { viewModel.zoom(into: group) }
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            viewModel.visibleRegion = context.region
        }
        .overlay { statusOverlay }
        .overlay(alignment: .top) { topBar }
        .overlay(alignment: .bottomTrailing) {
            VStack(spacing: 14) {
                if !parcours.selected.isEmpty { parcoursButton }
                createButton
            }
            .padding(.trailing, 20)
            .padding(.bottom, 96)
        }
        .overlay(alignment: .bottom) { RadiusPicker(viewModel: viewModel, center: session.location.coordinate) }
        .sheet(isPresented: $showParcours) {
            ParcoursSheet().environmentObject(session).environmentObject(parcours)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailSheet(event: event).environmentObject(session)
        }
        .sheet(isPresented: $showCreate) {
            CreateEventSheet(initialCenter: session.location.coordinate ?? fallbackCenter)
                .environmentObject(session)
        }
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { _ in })) {
            OnboardingView {
                hasOnboarded = true
                session.requestLocation()
            }
        }
        .onReceive(session.location.$coordinate) { viewModel.onUserLocation($0) }
        .task { if hasOnboarded { session.requestLocation() } }
    }

    // MARK: - Contrôles flottants (Liquid Glass)

    private var topBar: some View {
        GlassEffectContainer(spacing: 12) {
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    searchField
                    filterMenu
                }
                HStack {
                countPill
                Spacer()
                if viewModel.canSearchHere { searchHereButton }
            }
            }
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }

    private var searchHereButton: some View {
        Button {
            viewModel.searchHere()
        } label: {
            Label("Rechercher ici", systemImage: "arrow.clockwise")
                .font(Theme.display(13, .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .glassEffect(.regular.tint(Theme.accent).interactive(), in: .capsule)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var countPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.and.ellipse").foregroundStyle(Theme.accent)
            Text("\(viewModel.visibleEvents.count) événements").foregroundStyle(Theme.ink)
        }
        .font(Theme.display(12, .semibold))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .capsule)
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.accent)
            TextField("Chiner autour de moi…", text: $viewModel.searchText)
                .font(Theme.display(16, .medium))
                .foregroundStyle(Theme.ink)
                .tint(Theme.accent)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .glassEffect(.regular, in: .capsule)
    }

    private var filterMenu: some View {
        let allActive = viewModel.selectedKinds.count == SaleEventKind.allCases.count
        return Menu {
            ForEach(SaleEventKind.allCases, id: \.self) { kind in
                Button {
                    viewModel.toggleKind(kind)
                } label: {
                    Label(kind.label,
                          systemImage: viewModel.selectedKinds.contains(kind) ? "checkmark" : "")
                }
            }
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(allActive ? Theme.ink : .white)
                .frame(width: 48, height: 48)
                .glassEffect(allActive ? .regular : .regular.tint(Theme.accent),
                             in: .circle)
        }
    }

    private var createButton: some View {
        Button {
            showCreate = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .glassEffect(.regular.tint(Theme.accent).interactive(), in: .circle)
        }
    }

    private var parcoursButton: some View {
        Button {
            showParcours = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "map.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 54, height: 54)
                    .glassEffect(.regular.interactive(), in: .circle)
                Text("\(parcours.selected.count)")
                    .font(Theme.display(12, .heavy))
                    .foregroundStyle(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Theme.accent, in: Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    .offset(x: 4, y: -4)
            }
        }
    }

    // MARK: - États (chargement / vide / localisation)

    @ViewBuilder private var statusOverlay: some View {
        let status = session.location.authorizationStatus
        if status == .denied || status == .restricted {
            statusCard(
                icon: "location.slash.fill",
                title: "Localisation désactivée",
                message: "Active la localisation pour voir les vide-greniers autour de toi.",
                actionTitle: "Ouvrir les réglages"
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        } else if viewModel.isLoading && !viewModel.hasLoadedOnce {
            VStack(spacing: 14) {
                ProgressView().tint(Theme.accent)
                Text("Chargement des trouvailles…")
                    .font(Theme.display(15, .medium)).foregroundStyle(Theme.ink.opacity(0.7))
            }
            .padding(28)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        } else if viewModel.hasLoadedOnce && viewModel.visibleEvents.isEmpty {
            statusCard(
                icon: "mappin.slash",
                title: "Aucun événement",
                message: "Rien dans ce rayon. Agrandis la zone, change les filtres, ou crée le tien avec +.",
                actionTitle: nil,
                action: nil
            )
        }
    }

    private func statusCard(icon: String,
                            title: String,
                            message: String,
                            actionTitle: String?,
                            action: (() -> Void)?) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(Theme.accent)
            Text(title).font(Theme.display(20, .bold)).foregroundStyle(Theme.ink)
            Text(message)
                .font(.subheadline).foregroundStyle(Theme.ink.opacity(0.6))
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle).font(Theme.display(15, .semibold))
                }
                .buttonStyle(.glassProminent)
                .tint(Theme.accent)
                .padding(.top, 4)
            }
        }
        .padding(30)
        .frame(maxWidth: 320)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .padding(40)
    }
}
