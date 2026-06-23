import SwiftUI

/// Système de design « Carnet de chine » : palette chaleureuse de brocante
/// (terracotta / ocre / crème), typographie arrondie, formes douces. Cohérent
/// sur tout l'app, à l'opposé du bleu générique des concurrents.
enum Theme {
    // Palette
    static let terracotta = Color(red: 0.79, green: 0.33, blue: 0.24) // accent principal
    static let ochre = Color(red: 0.90, green: 0.64, blue: 0.30)
    static let teal = Color(red: 0.18, green: 0.52, blue: 0.49)
    static let plum = Color(red: 0.52, green: 0.34, blue: 0.52)
    static let slate = Color(red: 0.42, green: 0.47, blue: 0.53)
    static let ink = Color(red: 0.16, green: 0.13, blue: 0.11)
    static let paper = Color(red: 0.99, green: 0.97, blue: 0.93)

    static let accent = terracotta

    /// Police d'affichage arrondie (titres, marqueurs), caractérielle mais native.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Petit triangle (pointe de marqueur cartographique).
struct DownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

extension SaleEventKind {
    /// Couleur dédiée par type, pour un repérage instantané sur la carte.
    var color: Color {
        switch self {
        case .videGrenier: return Theme.terracotta
        case .brocante: return Theme.ochre
        case .marcheAuxPuces: return Theme.teal
        case .braderie: return Theme.plum
        case .autre: return Theme.slate
        }
    }
}
