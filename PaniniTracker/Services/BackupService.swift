import Foundation
import SwiftData

// MARK: - Import errors

enum BackupImportError: LocalizedError {
    case unreadable
    case invalidJSON
    case unsupportedVersion(Int)
    case unknownCountryCode(String)
    case invalidStickerNumber(country: String, number: Int)

    var errorDescription: String? {
        switch self {
        case .unreadable:
            return "Could not read the selected file."
        case .invalidJSON:
            return "The file is not a valid Panini Tracker backup."
        case .unsupportedVersion(let v):
            return "Unsupported backup version (\(v))."
        case .unknownCountryCode(let code):
            return "Unknown country code \"\(code)\" in backup file."
        case .invalidStickerNumber(let country, let n):
            return "Invalid sticker number \(n) for \(country)."
        }
    }
}

// MARK: - Service

struct BackupService {

    static let fileName = "panini-backup.json"

    static var backupURL: URL {
        URL.documentsDirectory.appendingPathComponent(fileName)
    }

    // Writes current state to Documents/panini-backup.json.
    // Returns the URL on success, nil on failure.
    @discardableResult
    static func write(states: [CountryMissingState]) -> URL? {
        let countries = states
            .sorted { $0.countryCode < $1.countryCode }
            .map { BackupCountry(countryCode: $0.countryCode, missingNumbers: $0.missingNumbers.sorted()) }

        let payload = BackupPayload(
            version: 1,
            exportDate: ISO8601DateFormatter().string(from: Date()),
            albumSetupCompleted: true,
            countries: countries
        )

        guard
            let data = try? JSONEncoder.pretty.encode(payload),
            (try? data.write(to: backupURL, options: .atomic)) != nil
        else {
            print("[BackupService] ERROR: failed to write backup")
            return nil
        }

        print("[BackupService] Backup saved: \(backupURL.path)")
        return backupURL
    }

    // Validates a backup file at the given URL.
    // Returns (countryCount, missingCount) on success, throws BackupImportError on failure.
    static func validate(url: URL) throws -> (countryCount: Int, missingCount: Int) {
        guard let data = try? Data(contentsOf: url) else {
            throw BackupImportError.unreadable
        }
        guard let payload = try? JSONDecoder().decode(BackupPayload.self, from: data) else {
            throw BackupImportError.invalidJSON
        }
        guard payload.version == 1 else {
            throw BackupImportError.unsupportedVersion(payload.version)
        }

        let catalog = AlbumDataService.shared
        for country in payload.countries {
            guard let catalogCountry = catalog.countries.first(where: { $0.code == country.countryCode }) else {
                throw BackupImportError.unknownCountryCode(country.countryCode)
            }
            for n in country.missingNumbers where n < 1 || n > catalogCountry.stickerCount {
                throw BackupImportError.invalidStickerNumber(country: country.countryCode, number: n)
            }
        }

        let missingCount = payload.countries.reduce(0) { $0 + $1.missingNumbers.count }
        return (payload.countries.count, missingCount)
    }

    // Writes a safety backup of currentStates, then clears data and imports from url.
    // Call only after validate(url:) succeeds.
    static func restore(from url: URL, currentStates: [CountryMissingState], context: ModelContext) {
        guard let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(BackupPayload.self, from: data) else {
            print("[BackupService] ERROR: restore failed to read file")
            return
        }

        write(states: currentStates) // safety backup before wiping

        AlbumStateService.deleteAll(context: context)
        for country in payload.countries {
            context.insert(CountryMissingState(countryCode: country.countryCode, missingNumbers: country.missingNumbers))
        }
        AlbumSetupFlag.isCompleted = true

        let totalMissing = payload.countries.reduce(0) { $0 + $1.missingNumbers.count }
        print("[BackupService] Restored \(payload.countries.count) countries, \(totalMissing) missing stickers")
    }
}

// MARK: - Private Codable models

private struct BackupPayload: Codable {
    let version: Int
    let exportDate: String
    let albumSetupCompleted: Bool
    let countries: [BackupCountry]
}

private struct BackupCountry: Codable {
    let countryCode: String
    let missingNumbers: [Int]
}

private extension JSONEncoder {
    static let pretty: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
}
