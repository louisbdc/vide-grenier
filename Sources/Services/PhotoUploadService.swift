import Foundation
import UIKit

private struct PhotoUploadResponse: Decodable {
    let url: String
}

/// Anonymise puis téléverse une photo d'événement.
///
/// Pipeline : image brute -> floutage local (`PhotoPrivacyService`) -> upload
/// multipart. L'image brute ne quitte jamais l'appareil.
@MainActor
struct PhotoUploadService {
    private let privacy = PhotoPrivacyService()

    func upload(_ image: UIImage, eventId: String, uid: String) async throws {
        let anonymized = try await privacy.anonymize(image)
        let _: PhotoUploadResponse = try await APIClient.shared.uploadImage(
            "events/\(eventId)/photos", imageData: anonymized
        )
    }
}
