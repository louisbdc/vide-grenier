import SwiftUI
import CoreLocation

/// Sélecteur de rayon kilométrique — la fonctionnalité absente des apps
/// historiques (recherche figée par département). Style « Carnet de chine ».
struct RadiusPicker: View {
    @ObservedObject var viewModel: MapViewModel
    let center: CLLocationCoordinate2D?

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "scope")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.accent)
                .padding(.leading, 6)
            ForEach(viewModel.radiusOptions, id: \.self) { km in
                pill(for: km)
            }
        }
        .padding(5)
        .glassEffect(.regular, in: .capsule)
        .padding(.bottom, 26)
    }

    private func pill(for km: Double) -> some View {
        let selected = viewModel.radiusKm == km
        return Button {
            viewModel.radiusKm = km
            viewModel.radiusChanged(center: center)
        } label: {
            Text("\(Int(km))")
                .font(Theme.display(15, .bold))
                .foregroundStyle(selected ? .white : Theme.ink.opacity(0.7))
                .frame(width: 38, height: 34)
                .background(
                    selected ? AnyShapeStyle(Theme.accent.gradient) : AnyShapeStyle(Color.clear),
                    in: Capsule()
                )
        }
    }
}
