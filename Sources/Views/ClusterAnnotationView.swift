import SwiftUI

/// Bulle de regroupement « Carnet de chine » : pastille terracotta cerclée de
/// blanc, compteur en typographie arrondie. Taille croissante avec la densité.
struct ClusterAnnotationView: View {
    let count: Int

    private var diameter: CGFloat {
        switch count {
        case ..<5: return 40
        case 5..<15: return 48
        case 15..<40: return 56
        default: return 64
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.accent.gradient)
                .shadow(color: .black.opacity(0.28), radius: 3, y: 2)
            Circle().stroke(.white, lineWidth: 3)
            Text("\(count)")
                .font(Theme.display(count < 100 ? 17 : 14, .heavy))
                .foregroundStyle(.white)
        }
        .frame(width: diameter, height: diameter)
    }
}
