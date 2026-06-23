import Foundation

/// Lecture des photos (déjà floutées) attachées à un événement.
@MainActor
struct PhotoRepository {
    func fetch(eventId: String) async throws -> [EventPhoto] {
        let photos: [EventPhoto] = try await APIClient.shared.get("events/\(eventId)/photos")
        // On masque localement les photos des utilisateurs bloqués.
        return photos.filter { !BlockStore.isBlocked($0.authorId) }
    }

    /// Signale une photo comme inappropriée (masquée serveur au seuil).
    func report(photoId: String) async throws {
        let _: EmptyResponse = try await APIClient.shared.post("photos/\(photoId)/report", body: [:])
    }
}
