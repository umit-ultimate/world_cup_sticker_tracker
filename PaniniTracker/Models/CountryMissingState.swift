import Foundation
import SwiftData

@Model
final class CountryMissingState {
    @Attribute(.unique) var countryCode: String
    // Stored as comma-separated integers, e.g. "4,17,19,20"
    // SwiftData cannot reliably persist [Int] transformable on all targets.
    private var missingNumbersRaw: String

    var missingNumbers: [Int] {
        get {
            missingNumbersRaw
                .split(separator: ",")
                .compactMap { Int($0) }
        }
        set {
            missingNumbersRaw = newValue.sorted().map(String.init).joined(separator: ",")
        }
    }

    init(countryCode: String, missingNumbers: [Int] = []) {
        self.countryCode = countryCode
        self.missingNumbersRaw = missingNumbers.sorted().map(String.init).joined(separator: ",")
    }
}
