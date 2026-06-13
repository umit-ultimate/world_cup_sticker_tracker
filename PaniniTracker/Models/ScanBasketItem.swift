import Foundation
import SwiftData

@Model final class ScanBasketItem {
    @Attribute(.unique) var stickerID: String   // "AUT-20"
    var countryCode: String
    var number: Int
    var firstScannedAt: Date
    var lastScannedAt: Date
    var neededByExporter: Bool

    init(countryCode: String, number: Int, neededByExporter: Bool) {
        self.stickerID = "\(countryCode)-\(number)"
        self.countryCode = countryCode
        self.number = number
        let now = Date()
        self.firstScannedAt = now
        self.lastScannedAt = now
        self.neededByExporter = neededByExporter
    }

    var displayCode: String { String(format: "%@ %02d", countryCode, number) }
}
