import Foundation
import UIKit

/// Gère les contributions de l'utilisateur sur un événement (signaux, tags,
/// photos) avec retour d'état pour l'UI.
@MainActor
final class EventDetailViewModel: ObservableObject {
    @Published private(set) var isSubmitting = false
    @Published private(set) var error: AppError?
    @Published private(set) var confirmation: String?
    @Published private(set) var gallery: [EventPhoto] = []

    private let signals = SignalRepository()
    private let photos = PhotoUploadService()
    private let photoRepository = PhotoRepository()

    func loadPhotos(eventId: String) async {
        gallery = (try? await photoRepository.fetch(eventId: eventId)) ?? []
    }

    /// Signale une photo inappropriée (modération UGC).
    func report(photo: EventPhoto, eventId: String) async {
        try? await photoRepository.report(photoId: photo.id)
        confirmation = "Merci, la photo a été signalée."
        await loadPhotos(eventId: eventId)
    }

    /// Bloque l'auteur d'une photo : ses contenus sont masqués sur l'appareil.
    func block(authorId: String, eventId: String) async {
        BlockStore.block(authorId)
        confirmation = "Utilisateur bloqué."
        await loadPhotos(eventId: eventId)
    }

    func submitSignal(_ type: SignalType, eventId: String, uid: String?) async {
        guard let uid else { error = .notAuthenticated; return }
        await run(confirmation: "Merci ! Signalement « \(type.label) » envoyé.") {
            try await self.signals.submitSignal(eventId: eventId, type: type, uid: uid)
        }
    }

    func submitTag(_ tag: InventoryTag, eventId: String, uid: String?) async {
        guard let uid else { error = .notAuthenticated; return }
        await run(confirmation: "Tag « \(tag.label) » ajouté.") {
            try await self.signals.submitTag(eventId: eventId, tag: tag, uid: uid)
        }
    }

    func uploadPhoto(_ image: UIImage, eventId: String, uid: String?) async {
        guard let uid else { error = .notAuthenticated; return }
        await run(confirmation: "Photo floutée et publiée.") {
            try await self.photos.upload(image, eventId: eventId, uid: uid)
        }
        if error == nil { await loadPhotos(eventId: eventId) }
    }

    private func run(confirmation message: String,
                     _ operation: @escaping () async throws -> Void) async {
        isSubmitting = true
        error = nil
        confirmation = nil
        do {
            try await operation()
            confirmation = message
        } catch let appError as AppError {
            error = appError
        } catch {
            self.error = .unknown
        }
        isSubmitting = false
    }
}
