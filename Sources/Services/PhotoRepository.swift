import Foundation

/// Lecture des photos (déjà floutées) attachées à un événement.
@MainActor
struct PhotoRepository {
    func fetch(eventId: String) async throws -> [EventPhoto] {
        try await APIClient.shared.get("events/\(eventId)/photos")
    }
}
