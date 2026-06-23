import SwiftUI
import MapKit
import CoreLocation

/// Écran de création d'un vide-grenier par un utilisateur.
///
/// L'emplacement se choisit en déplaçant la carte : le repère fixe au centre
/// (couleur du type choisi) indique la position retenue.
struct CreateEventSheet: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel = CreateEventViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var camera: MapCameraPosition
    @State private var center: CLLocationCoordinate2D

    init(initialCenter: CLLocationCoordinate2D) {
        _camera = State(initialValue: .region(MKCoordinateRegion(
            center: initialCenter,
            latitudinalMeters: 1_500,
            longitudinalMeters: 1_500
        )))
        _center = State(initialValue: initialCenter)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nom de l'événement", text: $viewModel.name)
                        .font(Theme.display(16, .medium))
                    Picker("Type", selection: $viewModel.kind) {
                        ForEach(SaleEventKind.allCases, id: \.self) { kind in
                            Text(kind.label).tag(kind)
                        }
                    }
                } header: { header("Informations") }

                Section {
                    DatePicker("Début", selection: $viewModel.startsAt)
                    Toggle("Heure de fin", isOn: $viewModel.hasEnd)
                    if viewModel.hasEnd {
                        DatePicker("Fin", selection: $viewModel.endsAt)
                    }
                } header: { header("Dates") }

                Section {
                    locationPicker
                } header: { header("Emplacement — déplace la carte") }

                if let error = viewModel.error {
                    Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.terracotta).font(.footnote)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.paper)
            .navigationTitle("Nouvel événement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publier") { Task { await publish() } }
                        .fontWeight(.bold)
                        .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
        }
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(Theme.display(13, .bold))
            .foregroundStyle(Theme.accent)
            .textCase(nil)
    }

    private var locationPicker: some View {
        ZStack {
            Map(position: $camera)
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .onMapCameraChange(frequency: .continuous) { context in
                    center = context.region.center
                }
            // Repère fixe au centre, couleur du type choisi.
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(viewModel.kind.color)
                .background(Circle().fill(.white).padding(4))
                .shadow(radius: 3)
                .allowsHitTesting(false)
            // Indice flottant en verre.
            VStack {
                Text("Place le repère ici")
                    .font(Theme.display(12, .semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .glassEffect(.regular, in: .capsule)
                    .padding(.top, 10)
                Spacer()
            }
        }
        .listRowInsets(EdgeInsets())
    }

    private func publish() async {
        let success = await viewModel.save(center: center, uid: session.uid)
        if success { dismiss() }
    }
}
