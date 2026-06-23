import Foundation
import Combine

/// État global de session injecté dans l'environnement SwiftUI.
///
/// Au démarrage : ouvre une session anonyme. La localisation est demandée
/// séparément (`requestLocation`) après l'onboarding, pour ne pas afficher la
/// demande système derrière l'écran d'accueil. Expose l'`uid` courant.
@MainActor
final class AppSession: ObservableObject {
    @Published private(set) var uid: String?
    @Published private(set) var startupError: AppError?

    let location = LocationService()
    private let auth: AuthServiceProtocol

    init(auth: AuthServiceProtocol = AuthService()) {
        self.auth = auth
    }

    func start() async {
        do {
            uid = try await auth.ensureSignedIn()
            await retryPendingPublish()
        } catch let error as AppError {
            startupError = error
        } catch {
            startupError = .unknown
        }
    }

    /// Republie une annonce payée dont la publication avait échoué (sans re-payer).
    private func retryPendingPublish() async {
        guard let pending = PendingPublishStore.load() else { return }
        do {
            _ = try await EventCreationService().publish(pending)
            PendingPublishStore.clear()
        } catch AppError.alreadyPublished, AppError.paymentRequired {
            // Déjà publiée, ou session non réellement payée : on n'insiste pas.
            PendingPublishStore.clear()
        } catch {
            // Échec réseau : on conserve pour retenter au prochain lancement.
        }
    }

    func requestLocation() {
        location.requestPermissionAndStart()
    }
}
