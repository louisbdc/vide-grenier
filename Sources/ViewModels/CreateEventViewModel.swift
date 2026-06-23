import Foundation
import CoreLocation

/// Gère la saisie et la validation d'un nouvel événement crowdsourcé.
@MainActor
final class CreateEventViewModel: ObservableObject {
    @Published var name = ""
    @Published var kind: SaleEventKind = .videGrenier
    @Published var startsAt = Date()
    @Published var hasEnd = true
    @Published var endsAt = Date().addingTimeInterval(4 * 3600)
    @Published private(set) var isSaving = false
    @Published private(set) var error: AppError?

    private let service = EventCreationService()
    private let payment = PaymentService()

    /// Nom non vide et fin (si activée) postérieure au début.
    var isValid: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if hasEnd { return endsAt >= startsAt }
        return true
    }

    /// Publication payante : crée le PaymentIntent (5 €), présente le Payment
    /// Sheet Stripe, puis publie l'annonce seulement si le paiement réussit.
    func save(center: CLLocationCoordinate2D, uid: String?) async -> Bool {
        guard let uid else { error = .notAuthenticated; return false }
        guard isValid else { return false }

        isSaving = true
        error = nil
        defer { isSaving = false }
        do {
            let checkout = try await service.createCheckout()
            let outcome = await payment.openCheckout(url: checkout.url)
            switch outcome {
            case .canceled:
                return false               // annulation : pas d'erreur affichée
            case .failed:
                error = .paymentFailed
                return false
            case .returned:
                break                      // paiement vérifié côté serveur ci-dessous
            }

            // Le serveur vérifie que la session est réellement payée avant de publier.
            _ = try await service.create(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                kind: kind,
                startsAt: startsAt,
                endsAt: hasEnd ? endsAt : nil,
                latitude: center.latitude,
                longitude: center.longitude,
                address: nil,
                checkoutSessionId: checkout.sessionId,
                uid: uid
            )
            return true
        } catch let appError as AppError {
            error = appError
            return false
        } catch {
            self.error = .unknown
            return false
        }
    }
}
