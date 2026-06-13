import Foundation
import AVFoundation
import Vision

// Camera-specific capture + OCR pipeline for the live scanner (Phase 3A.2).
// Isolated from the photo-based OCRService; reuses Vision config tuned for codes.
//
// - Captures video frames via AVCaptureVideoDataOutput.
// - Throttles OCR to ~2 frames/sec (Vision is NOT run on every frame).
// - Uses a single VNSequenceRequestHandler across frames.
// - Reports recognized lines (text + confidence) back on the main thread.
// `nonisolated` opts this type out of the project's default MainActor isolation —
// its capture state lives on background queues, not the main actor.
// `@unchecked Sendable`: thread-safety is managed manually via serial queues
// (session work on sessionQueue, frame processing on sampleQueue).
nonisolated final class ScannerCameraController: NSObject, @preconcurrency AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {

    let session = AVCaptureSession()

    // Called on the main thread with recognized lines for each processed frame.
    var onLines: (([(text: String, confidence: Float)]) -> Void)?

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "scanner.session")
    private let sampleQueue = DispatchQueue(label: "scanner.samples")
    private let sequenceHandler = VNSequenceRequestHandler()

    // Throttle: only run Vision once per interval.
    private var lastProcessed = Date.distantPast
    private let minInterval: TimeInterval = 0.5 // ~2 fps
    private var isConfigured = false

    // MARK: - Permission

    static func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    // MARK: - Lifecycle

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                self.configureSession()
                self.isConfigured = true
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    // MARK: - Configuration

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: sampleQueue)
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
    }
}

// MARK: - Frame processing

extension ScannerCameraController {

    // Runs on sampleQueue (background).
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let now = Date()
        guard now.timeIntervalSince(lastProcessed) >= minInterval else { return }
        lastProcessed = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false   // codes aren't dictionary words
        request.recognitionLanguages = ["en-US"]

        do {
            // Back camera in portrait → frames need .right orientation.
            try sequenceHandler.perform([request], on: pixelBuffer, orientation: .right)
        } catch {
            return
        }

        let observations = request.results ?? []
        let lines: [(text: String, confidence: Float)] = observations.compactMap { obs in
            guard let candidate = obs.topCandidates(1).first else { return nil }
            return (candidate.string, candidate.confidence)
        }

        guard !lines.isEmpty else { return }
        DispatchQueue.main.async { [weak self] in
            self?.onLines?(lines)
        }
    }
}
