import Foundation

/// Erreurs de domaine, présentables à l'utilisateur sans fuite de détail technique.
enum AppError: LocalizedError, Equatable {
    case locationDenied
    case notAuthenticated
    case network(String)
    case decoding(String)
    case photoProcessingFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .locationDenied:
            return "Active la localisation pour voir les vide-greniers autour de toi."
        case .notAuthenticated:
            return "Impossible d'initialiser la session. Réessaie dans un instant."
        case .network:
            return "Connexion impossible. Vérifie ta connexion internet."
        case .decoding:
            return "Données illisibles reçues du serveur."
        case .photoProcessingFailed:
            return "Le traitement de confidentialité de la photo a échoué."
        case .unknown:
            return "Une erreur inattendue est survenue."
        }
    }
}
