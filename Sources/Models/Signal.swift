import Foundation

/// Type de signalement « terrain » émis par un utilisateur sur un événement.
enum SignalType: String, Codable, CaseIterable, Identifiable, Sendable {
    case ongoing
    case crowded
    case deserted
    case emptied
    case cancelled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ongoing: return "En cours"
        case .crowded: return "Foule dense"
        case .deserted: return "Stands désertés"
        case .emptied: return "Déjà vidé"
        case .cancelled: return "Annulé"
        }
    }

    var systemImage: String {
        switch self {
        case .ongoing: return "figure.walk"
        case .crowded: return "person.3.fill"
        case .deserted: return "person.fill.xmark"
        case .emptied: return "tray"
        case .cancelled: return "xmark.octagon.fill"
        }
    }
}

/// Un signalement individuel et horodaté.
///
/// Les signaux expirent (TTL côté serveur) : un « foule dense » ne reflète plus
/// la réalité quelques heures plus tard.
struct Signal: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let type: SignalType
    let uid: String
    let createdAt: Date
}
