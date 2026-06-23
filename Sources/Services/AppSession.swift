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
        } catch let error as AppError {
            startupError = error
        } catch {
            startupError = .unknown
        }
    }

    func requestLocation() {
        location.requestPermissionAndStart()
    }
}
