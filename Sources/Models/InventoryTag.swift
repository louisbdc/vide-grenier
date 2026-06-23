import Foundation

/// Qualification d'inventaire posée par les visiteurs en direct
/// (« beaucoup de puériculture », « mobilier vintage »…).
///
/// Le `rawValue` est stocké tel quel côté serveur pour pouvoir agréger les
/// occurrences et faire remonter les spécialités d'un événement.
enum InventoryTag: String, Codable, CaseIterable, Identifiable, Sendable {
    case puericulture
    case mobilierVintage
    case livresAnciens
    case outils
    case vinyles
    case vetements
    case jouets
    case vaisselle
    case bd
    case hightech
    case collection

    var id: String { rawValue }

    var label: String {
        switch self {
        case .puericulture: return "Puériculture"
        case .mobilierVintage: return "Mobilier vintage"
        case .livresAnciens: return "Livres anciens"
        case .outils: return "Outils"
        case .vinyles: return "Vinyles"
        case .vetements: return "Vêtements"
        case .jouets: return "Jouets"
        case .vaisselle: return "Vaisselle"
        case .bd: return "BD / Comics"
        case .hightech: return "High-tech"
        case .collection: return "Collection"
        }
    }

    var emoji: String {
        switch self {
        case .puericulture: return "🍼"
        case .mobilierVintage: return "🪑"
        case .livresAnciens: return "📚"
        case .outils: return "🔧"
        case .vinyles: return "💿"
        case .vetements: return "👕"
        case .jouets: return "🧸"
        case .vaisselle: return "🍽️"
        case .bd: return "📰"
        case .hightech: return "📱"
        case .collection: return "🃏"
        }
    }
}
