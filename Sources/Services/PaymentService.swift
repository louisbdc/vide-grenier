import Foundation
import UIKit
import AuthenticationServices

/// Résultat de l'ouverture de la page de paiement Stripe Checkout.
enum PaymentOutcome {
    case returned   // l'utilisateur est revenu (paiement à vérifier côté serveur)
    case canceled
    case failed
}

/// Ouvre la page Stripe Checkout dans une session web native
/// (`ASWebAuthenticationSession`) — aucun SDK tiers. Après paiement, la page de
/// retour redirige vers `videgrenier://done`, ce qui referme la session.
/// Le paiement est ensuite **vérifié côté serveur** (source de vérité).
@MainActor
final class PaymentService: NSObject {
    private var session: ASWebAuthenticationSession?

    func openCheckout(url: String) async -> PaymentOutcome {
        guard let checkoutURL = URL(string: url) else { return .failed }
        return await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: checkoutURL,
                callbackURLScheme: "videgrenier"
            ) { callbackURL, error in
                if callbackURL?.host == "done" {
                    continuation.resume(returning: .returned)
                } else if let error = error as? ASWebAuthenticationSessionError,
                          error.code == .canceledLogin {
                    continuation.resume(returning: .canceled)
                } else {
                    continuation.resume(returning: error == nil ? .returned : .failed)
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            session.start()
        }
    }
}

extension PaymentService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            return scene?.keyWindow ?? ASPresentationAnchor()
        }
    }
}
