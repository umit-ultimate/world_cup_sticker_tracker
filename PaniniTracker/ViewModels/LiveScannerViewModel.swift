import Foundation
import SwiftData
import AudioToolbox
import UIKit

// Drives the live scanner UI: receives OCR lines, validates them against the
// album catalog, checks missing state in SwiftData, applies a duplicate cooldown,
// and fires sound/haptic feedback for needed stickers.
//
// Does NOT mark stickers as found — detection/alert only (Phase 3A.2).
@Observable
@MainActor
final class LiveScannerViewModel {

    enum Status { case needed, notNeeded }

    struct Detection: Identifiable {
        let id = UUID()
        let code: StickerCodeOCRParser.ParsedCode
        let country: Country
        let status: Status
        var stickerCode: String { String(format: "%@ %02d", country.code, code.number) }
    }

    private(set) var latest: Detection?
    var permissionDenied = false

    let controller = ScannerCameraController()

    private let parser = StickerCodeOCRParser()
    private let cooldown: TimeInterval = 3
    private var lastAlerted: [String: Date] = [:]   // code id -> last surfaced time
    private var modelContext: ModelContext?
    private let haptic = UINotificationFeedbackGenerator()

    // MARK: - Lifecycle

    func start(context: ModelContext) async {
        modelContext = context
        let granted = await ScannerCameraController.requestAccess()
        guard granted else {
            permissionDenied = true
            return
        }
        controller.onLines = { [weak self] lines in
            self?.handle(lines: lines)
        }
        haptic.prepare()
        controller.start()
    }

    func stop() {
        controller.onLines = nil
        controller.stop()
    }

    // MARK: - Detection handling (main thread)

    private func handle(lines: [(text: String, confidence: Float)]) {
        let output = parser.validate(
            lines: lines,
            countries: AlbumDataService.shared.countries
        )
        // First validated album sticker in the frame.
        guard let code = output.accepted.first,
              let country = AlbumDataService.shared.countries.first(where: { $0.code == code.countryCode })
        else { return }

        // Duplicate cooldown: ignore the same code within the cooldown window.
        let now = Date()
        if let last = lastAlerted[code.id], now.timeIntervalSince(last) < cooldown { return }
        lastAlerted[code.id] = now

        let isMissing = missingNumbers(for: code.countryCode).contains(code.number)
        let status: Status = isMissing ? .needed : .notNeeded
        latest = Detection(code: code, country: country, status: status)

        if status == .needed {
            AudioServicesPlaySystemSound(1057) // short "Tink"
            haptic.notificationOccurred(.success)
        }
    }

    // Reads missing numbers for a country directly from SwiftData (avoids stale captures).
    private func missingNumbers(for countryCode: String) -> [Int] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<CountryMissingState>(
            predicate: #Predicate { $0.countryCode == countryCode }
        )
        return (try? context.fetch(descriptor))?.first?.missingNumbers ?? []
    }
}
