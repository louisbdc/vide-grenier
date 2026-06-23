import Foundation

/// Erreurs de domaine, présentables à l'utilisateur sans fuite de détail technique.
enum AppError: LocalizedError, Equatable {
    case locationDenied
    case notAuthenticated
    case network(String)
    case decoding(String)
    case photoProcessingFailed
    case paymentFailed
    case paymentRequired
    case alreadyPublished
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
        case .paymentFailed:
            return "Le paiement n'a pas abouti. Aucune annonce n'a été publiée."
        case .paymentRequired:
            return "Le paiement n'a pas été confirmé. Réessaie la publication."
        case .alreadyPublished:
            return "Cette annonce a déjà été publiée."
        case .unknown:
            return "Une erreur inattendue est survenue."
        }
    }
}
