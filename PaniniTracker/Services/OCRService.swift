import Foundation
import Vision
import UIKit

// Wraps Apple Vision text recognition for the OCR proof of concept.
struct OCRService {

    struct Line: Identifiable {
        let id = UUID()
        let text: String
        let confidence: Float   // top-candidate confidence, 0...1
    }

    struct Result {
        let lines: [Line]
        var rawText: String { lines.map(\.text).joined(separator: "\n") }
        // Average confidence across detected lines (nil if nothing detected).
        var averageConfidence: Float? {
            guard !lines.isEmpty else { return nil }
            return lines.map(\.confidence).reduce(0, +) / Float(lines.count)
        }
    }

    enum OCRError: LocalizedError {
        case noCGImage
        case requestFailed(String)

        var errorDescription: String? {
            switch self {
            case .noCGImage:
                return "Could not read the selected image."
            case .requestFailed(let msg):
                return "Text recognition failed: \(msg)"
            }
        }
    }

    // Runs Vision text recognition on the given image.
    // Tuned for short alphanumeric sticker codes: accurate level, no language correction.
    func recognizeText(in image: UIImage) async throws -> Result {
        guard let cgImage = image.cgImage else { throw OCRError.noCGImage }

        let orientation = cgOrientation(from: image.imageOrientation)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.requestFailed(error.localizedDescription))
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines: [OCRService.Line] = observations.compactMap { obs in
                    guard let candidate = obs.topCandidates(1).first else { return nil }
                    return OCRService.Line(text: candidate.string, confidence: candidate.confidence)
                }
                continuation.resume(returning: Result(lines: lines))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false   // codes are not words
            request.recognitionLanguages = ["en-US"]
            request.minimumTextHeight = 0.0          // allow small codes

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.requestFailed(error.localizedDescription))
            }
        }
    }

    private func cgOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
