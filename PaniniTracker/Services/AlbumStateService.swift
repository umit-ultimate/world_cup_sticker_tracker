import Foundation
import SwiftData

struct AlbumProgress {
    let totalStickers: Int
    let missingStickers: Int
    var ownedStickers: Int { totalStickers - missingStickers }
    var completionPercentage: Double {
        guard totalStickers > 0 else { return 0 }
        return Double(ownedStickers) / Double(totalStickers) * 100
    }
}

final class AlbumStateService {

    static func progress(
        states: [CountryMissingState],
        album: AlbumDataService = .shared
    ) -> AlbumProgress {
        let total = album.countries.reduce(0) { $0 + $1.stickerCount }
        let missing = states.reduce(0) { $0 + $1.missingNumbers.count }
        return AlbumProgress(totalStickers: total, missingStickers: missing)
    }

    static func missingNumbers(
        for countryCode: String,
        in states: [CountryMissingState]
    ) -> [Int] {
        states.first(where: { $0.countryCode == countryCode })?.missingNumbers ?? []
    }

    // Save or update missing state for one country.
    // Passing an empty array removes any existing record for that country.
    static func save(
        countryCode: String,
        missingNumbers: [Int],
        context: ModelContext
    ) {
        let existing = try? context.fetch(
            FetchDescriptor<CountryMissingState>(
                predicate: #Predicate { $0.countryCode == countryCode }
            )
        )
        if let record = existing?.first {
            if missingNumbers.isEmpty {
                context.delete(record)
            } else {
                record.missingNumbers = missingNumbers
            }
        } else if !missingNumbers.isEmpty {
            context.insert(CountryMissingState(countryCode: countryCode, missingNumbers: missingNumbers))
        }
        try? context.save()
    }

    // Removes one sticker number from a country's missing list.
    // Deletes the record entirely if no missing stickers remain.
    static func markFound(countryCode: String, number: Int, context: ModelContext) {
        guard let record = (try? context.fetch(
            FetchDescriptor<CountryMissingState>(
                predicate: #Predicate { $0.countryCode == countryCode }
            )
        ))?.first else { return }

        let updated = record.missingNumbers.filter { $0 != number }
        if updated.isEmpty {
            context.delete(record)
        } else {
            record.missingNumbers = updated
        }
        try? context.save()
    }

    static func deleteAll(context: ModelContext) {
        try? context.delete(model: CountryMissingState.self)
        try? context.save()
    }
}
