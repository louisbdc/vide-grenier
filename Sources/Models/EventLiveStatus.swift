import Foundation
import SwiftUI

/// Statut « terrain » d'un événement, déduit des signalements récents de la
/// communauté (recalculé côté serveur, avec expiration des signaux périmés).
enum EventLiveStatus: String, Codable, CaseIterable, Sendable {
    case scheduled   // prévu, aucun signal contradictoire
    case ongoing     // en cours
    case crowded     // foule dense
    case deserted    // stands désertés / fin d'affluence
    case emptied     // déjà vidé
    case cancelled   // annulé (ex: pluie)

    var label: String {
        switch self {
        case .scheduled: return "Prévu"
        case .ongoing: return "En cours"
        case .crowded: return "Foule dense"
        case .deserted: return "Stands désertés"
        case .emptied: return "Déjà vidé"
        case .cancelled: return "Annulé"
        }
    }

    var systemImage: String {
        switch self {
        case .scheduled: return "calendar"
        case .ongoing: return "figure.walk"
        case .crowded: return "person.3.fill"
        case .deserted: return "person.fill.xmark"
        case .emptied: return "tray"
        case .cancelled: return "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .scheduled: return .blue
        case .ongoing: return .green
        case .crowded: return .orange
        case .deserted: return .gray
        case .emptied: return .gray
        case .cancelled: return .red
        }
    }

    /// Un événement à éviter : permet de griser l'épingle sur la carte.
    var isDiscouraged: Bool {
        self == .cancelled || self == .emptied || self == .deserted
    }
}
