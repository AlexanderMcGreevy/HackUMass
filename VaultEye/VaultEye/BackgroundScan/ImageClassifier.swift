//
//  ImageClassifier.swift
//  VaultEye
//
//  Core ML image classification wrapper
//

import Foundation
@preconcurrency import Vision
import CoreML
import UIKit

struct ImageClassifier {
    private let model: VNCoreMLModel?
    private let useMockMode: Bool

    // MARK: - Initialization

    /// Initialize with a Core ML model
    /// Replace MyPlaceholderModel with your actual .mlmodel class
    init() throws {
        // TODO: Replace with your actual Core ML model
        // Example: let mlModel = try YourModel(configuration: MLModelConfiguration()).model

        // For now, throw error to use mock mode
        throw NSError(domain: "ImageClassifier", code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "No Core ML model available"])
    }

    init(mlModel: MLModel) throws {
        self.model = try VNCoreMLModel(for: mlModel)
        self.useMockMode = false
    }

    /// Initialize in mock mode (no ML model required)
    private init(mockMode: Bool) {
        self.model = nil
        self.useMockMode = mockMode
    }

    // MARK: - Classification

    /// Returns confidence score 0-100 for the given image
    func confidence(for cgImage: CGImage) async throws -> Int {
        // If in mock mode, use mock confidence
        if useMockMode {
            return await mockConfidence(for: cgImage)
        }

        guard let model = self.model else {
            throw NSError(domain: "ImageClassifier", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "No model available"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNClassificationObservation],
                      let topResult = results.first else {
                    continuation.resume(returning: 0)
                    return
                }

                // Convert 0.0-1.0 confidence to 0-100
                let confidenceInt = Int(topResult.confidence * 100)
                continuation.resume(returning: confidenceInt)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Mock Classifier for Testing

extension ImageClassifier {
    /// Creates a mock classifier that returns random confidence for testing
    static func mock() -> ImageClassifier {
        return ImageClassifier(mockMode: true)
    }

    /// Mock confidence method that returns random values for testing
    /// Returns all photos (100 confidence) so they're all loaded for review
    func mockConfidence(for cgImage: CGImage) async -> Int {
        // Simulate brief processing time
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second

        // Return 100 (all photos match) so user can review all of them
        // When a real ML model is added, this will be replaced by actual inference
        return 100
    }
}
