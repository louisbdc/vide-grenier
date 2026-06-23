import SwiftUI

/// Point d'entrée de l'application.
///
/// Au tout premier lancement, aucun écran de connexion : `AppSession` ouvre
/// silencieusement une session anonyme auprès du backend. L'utilisateur arrive
/// directement sur la carte.
@main
struct VideGrenierApp: App {
    @StateObject private var session = AppSession()
    @StateObject private var parcours = ParcoursStore()

    var body: some Scene {
        WindowGroup {
            MapScreen()
                .environmentObject(session)
                .environmentObject(parcours)
                .tint(Theme.accent)
                .task { await session.start() }
        }
    }
}
