import Foundation

struct ScanBasketService {

    static let fileName = "scan-basket.json"

    static var exportURL: URL {
        URL.documentsDirectory.appendingPathComponent(fileName)
    }

    // MARK: - Export

    @discardableResult
    static func write(items: [ScanBasketItem]) -> URL? {
        let entries = items
            .sorted { $0.stickerID < $1.stickerID }
            .map { ScanBasketEntry(countryCode: $0.countryCode, number: $0.number, neededByExporter: $0.neededByExporter) }

        let payload = ScanBasketPayload(
            version: 1,
            source: "scan-basket",
            exportDate: ISO8601DateFormatter().string(from: Date()),
            stickers: entries
        )

        guard
            let data = try? JSONEncoder.pretty.encode(payload),
            (try? data.write(to: exportURL, options: .atomic)) != nil
        else {
            print("[ScanBasketService] ERROR: failed to write export")
            return nil
        }

        print("[ScanBasketService] Export saved: \(exportURL.path)")
        return exportURL
    }

    // MARK: - Import validation

    enum ImportError: LocalizedError {
        case unreadable
        case invalidJSON
        case wrongSource(String)
        case unsupportedVersion(Int)
        case unknownCountryCode(String)
        case invalidStickerNumber(country: String, number: Int)

        var errorDescription: String? {
            switch self {
            case .unreadable:
                return "Could not read the selected file."
            case .invalidJSON:
                return "The file is not a valid Scan Basket export."
            case .wrongSource(let s):
                return "Expected source \"scan-basket\", got \"\(s)\"."
            case .unsupportedVersion(let v):
                return "Unsupported version (\(v))."
            case .unknownCountryCode(let code):
                return "Unknown country code \"\(code)\" in basket file."
            case .invalidStickerNumber(let c, let n):
                return "Invalid sticker number \(n) for \(c)."
            }
        }
    }

    // Returns the valid entries. Throws ImportError on any structural problem.
    static func validate(url: URL) throws -> [ScanBasketEntry] {
        guard let data = try? Data(contentsOf: url) else { throw ImportError.unreadable }
        guard let payload = try? JSONDecoder().decode(ScanBasketPayload.self, from: data) else { throw ImportError.invalidJSON }
        guard payload.version == 1 else { throw ImportError.unsupportedVersion(payload.version) }
        guard payload.source == "scan-basket" else { throw ImportError.wrongSource(payload.source) }

        let catalog = Dictionary(
            AlbumDataService.shared.countries.map { ($0.code, $0.stickerCount) },
            uniquingKeysWith: { a, _ in a }
        )

        for entry in payload.stickers {
            guard let max = catalog[entry.countryCode] else { throw ImportError.unknownCountryCode(entry.countryCode) }
            guard entry.number >= 1, entry.number <= max else {
                throw ImportError.invalidStickerNumber(country: entry.countryCode, number: entry.number)
            }
        }

        return payload.stickers
    }

    // MARK: - Insight grouping

    struct Insight {
        struct Item: Identifiable {
            let id: String              // "AUT-20"
            let countryCode: String
            let number: Int
            let neededByExporter: Bool
            var displayCode: String { String(format: "%@ %02d", countryCode, number) }
        }

        // Group A: missing in my album AND neededByExporter == false
        let likelyAvailable: [Item]
        // Group B: missing in my album AND neededByExporter == true
        let possiblyTaken: [Item]
        // Group C: not missing in my album
        let notNeeded: [Item]

        var hasContent: Bool { !likelyAvailable.isEmpty || !possiblyTaken.isEmpty || !notNeeded.isEmpty }
        var totalCount: Int { likelyAvailable.count + possiblyTaken.count + notNeeded.count }
    }

    static func computeInsight(
        entries: [ScanBasketEntry],
        states: [CountryMissingState]
    ) -> Insight {
        var likelyAvailable: [Insight.Item] = []
        var possiblyTaken: [Insight.Item] = []
        var notNeeded: [Insight.Item] = []

        for entry in entries {
            let item = Insight.Item(
                id: "\(entry.countryCode)-\(entry.number)",
                countryCode: entry.countryCode,
                number: entry.number,
                neededByExporter: entry.neededByExporter
            )
            let isMissingByMe = AlbumStateService.missingNumbers(for: entry.countryCode, in: states)
                .contains(entry.number)

            if isMissingByMe {
                if entry.neededByExporter {
                    possiblyTaken.append(item)
                } else {
                    likelyAvailable.append(item)
                }
            } else {
                notNeeded.append(item)
            }
        }

        return Insight(likelyAvailable: likelyAvailable, possiblyTaken: possiblyTaken, notNeeded: notNeeded)
    }
}

// MARK: - Codable models (private to service)

struct ScanBasketEntry: Codable {
    let countryCode: String
    let number: Int
    let neededByExporter: Bool
}

private struct ScanBasketPayload: Codable {
    let version: Int
    let source: String
    let exportDate: String
    let stickers: [ScanBasketEntry]
}

private extension JSONEncoder {
    static let pretty: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
}
