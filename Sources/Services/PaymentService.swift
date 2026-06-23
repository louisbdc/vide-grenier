import Foundation
import UIKit
import StripePaymentSheet

/// Résultat d'un paiement via le Payment Sheet Stripe.
enum PaymentOutcome {
    case success
    case canceled
    case failed
}

/// Présente le Payment Sheet Stripe (carte / moyens dynamiques configurés au
/// Dashboard) pour régler la publication d'une annonce.
@MainActor
enum PaymentService {
    static func payListing(clientSecret: String, publishableKey: String) async -> PaymentOutcome {
        STPAPIClient.shared.publishableKey = publishableKey

        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Vide-Grenier"

        let sheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: configuration)
        guard let presenter = topViewController() else { return .failed }

        return await withCheckedContinuation { continuation in
            sheet.present(from: presenter) { result in
                _ = sheet // retient le sheet jusqu'à la complétion
                switch result {
                case .completed: continuation.resume(returning: .success)
                case .canceled: continuation.resume(returning: .canceled)
                case .failed: continuation.resume(returning: .failed)
                }
            }
        }
    }

    private static func topViewController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
        var top = root
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
