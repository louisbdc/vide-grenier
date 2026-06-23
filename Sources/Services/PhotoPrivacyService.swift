import Foundation
import Vision
import CoreImage
import UIKit

/// « Privacy by Design » : floute de façon irréversible les visages et les
/// plaques d'immatriculation **localement sur le téléphone**, avant tout envoi.
///
/// Conforme à la doctrine CNIL citée dans l'étude : une plaque est une donnée à
/// caractère personnel ; un visage relève du droit à l'image. Le traitement est
/// 100 % local (aucune image brute ne quitte l'appareil).
struct PhotoPrivacyService {
    private let context = CIContext()

    /// Détecte visages + zones de plaque probables et applique un flou pixellisé
    /// irréversible sur ces régions. Retourne l'image anonymisée (JPEG).
    func anonymize(_ image: UIImage) async throws -> Data {
        guard let cgImage = image.cgImage else { throw AppError.photoProcessingFailed }

        async let faces = detectFaceRegions(cgImage)
        async let plates = detectPlateRegions(cgImage)
        let regions = try await faces + plates

        let ciImage = CIImage(cgImage: cgImage)
        let blurred = applyPixellation(to: ciImage, regions: regions, extent: ciImage.extent)

        guard
            let outputCG = context.createCGImage(blurred, from: ciImage.extent),
            let data = UIImage(cgImage: outputCG).jpegData(compressionQuality: 0.8)
        else {
            throw AppError.photoProcessingFailed
        }
        return data
    }

    // MARK: - Détection

    private func detectFaceRegions(_ cgImage: CGImage) async throws -> [CGRect] {
        try await performRequest(VNDetectFaceRectanglesRequest(), on: cgImage) { obs in
            (obs as? [VNFaceObservation])?.map(\.boundingBox) ?? []
        }
    }

    /// Heuristique plaques : on détecte les blocs de texte au format proche d'une
    /// plaque (rapport largeur/hauteur ~3 à 6, alphanumérique court).
    private func detectPlateRegions(_ cgImage: CGImage) async throws -> [CGRect] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .fast
        request.usesLanguageCorrection = false
        return try await performRequest(request, on: cgImage) { obs in
            (obs as? [VNRecognizedTextObservation])?.compactMap { observation in
                let box = observation.boundingBox
                let ratio = box.width / max(box.height, 0.0001)
                let looksLikePlate = ratio > 2.5 && ratio < 7
                    && (observation.topCandidates(1).first?.string.count ?? 0) <= 9
                return looksLikePlate ? box : nil
            } ?? []
        }
    }

    private func performRequest<T>(_ request: VNImageBasedRequest,
                                   on cgImage: CGImage,
                                   transform: @escaping ([VNObservation]) -> [T]) async throws -> [T] {
        try await withCheckedThrowingContinuation { continuation in
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                    continuation.resume(returning: transform(request.results ?? []))
                } catch {
                    continuation.resume(throwing: AppError.photoProcessingFailed)
                }
            }
        }
    }

    // MARK: - Floutage

    /// Applique une pixellisation forte sur chaque région (coordonnées Vision
    /// normalisées, origine en bas-gauche).
    private func applyPixellation(to image: CIImage,
                                  regions: [CGRect],
                                  extent: CGRect) -> CIImage {
        guard !regions.isEmpty else { return image }

        var result = image
        for normalized in regions {
            let rect = CGRect(
                x: normalized.origin.x * extent.width,
                y: normalized.origin.y * extent.height,
                width: normalized.width * extent.width,
                height: normalized.height * extent.height
            ).insetBy(dx: -8, dy: -8)

            let pixellated = result
                .cropped(to: rect)
                .applyingFilter("CIPixellate", parameters: [
                    kCIInputScaleKey: max(rect.width, rect.height) / 8
                ])
            result = pixellated.composited(over: result)
        }
        return result.cropped(to: extent)
    }
}
