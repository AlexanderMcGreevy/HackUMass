import Foundation
import UIKit
import Vision

protocol OCRServiceProtocol {
    func extractSegments(from image: UIImage, regions: [DetectedRegion]) async throws -> [OCRTextSegment]
}

enum OCRServiceError: Error {
    case imageConversionFailed
    case noTextDetected
}

final class VisionOCRService: OCRServiceProtocol {

    func extractSegments(from image: UIImage, regions: [DetectedRegion]) async throws -> [OCRTextSegment] {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.imageConversionFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var collected: [OCRTextSegment] = []

                for region in regions {
                    let request = VNRecognizeTextRequest()
                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = false
                    request.minimumTextHeight = 0.02
                    request.customWords = []
                    request.regionOfInterest = Self.visionRect(for: region.normalizedRect)

                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

                    do {
                        try handler.perform([request])
                    } catch {
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let observations = request.results else {
                        continue
                    }

                    let rawText = observations
                        .compactMap { $0.topCandidates(1).first?.string }
                        .joined(separator: "\n")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    guard !rawText.isEmpty else {
                        continue
                    }

                    let sanitized = TextSanitizer.sanitize(rawText)
                    let segment = OCRTextSegment(
                        regionID: region.id,
                        rawText: rawText,
                        sanitizedText: sanitized
                    )
                    collected.append(segment)
                }

                if collected.isEmpty {
                    continuation.resume(throwing: OCRServiceError.noTextDetected)
                } else {
                    continuation.resume(returning: collected)
                }
            }
        }
    }

    private static func visionRect(for normalizedRect: CGRect) -> CGRect {
        let clampedX = max(0, min(1, normalizedRect.origin.x))
        let clampedY = max(0, min(1, normalizedRect.origin.y))
        let clampedWidth = max(0, min(1 - clampedX, normalizedRect.width))
        let clampedHeight = max(0, min(1 - clampedY, normalizedRect.height))

        // Convert from top-left origin (UI) to bottom-left origin (Vision)
        let visionY = 1 - clampedY - clampedHeight

        return CGRect(x: clampedX, y: visionY, width: clampedWidth, height: clampedHeight)
    }
}
