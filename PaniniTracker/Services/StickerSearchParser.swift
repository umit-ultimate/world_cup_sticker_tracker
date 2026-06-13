import Foundation

enum SearchQuery {
    case stickerCode(countryCode: String, number: Int)
    case countryCode(String)
    case countryName(String)
    case unknown
}

enum SearchResult {
    case sticker(country: Country, number: Int, isNeeded: Bool)
    case country(country: Country, missingNumbers: [Int])
    case notFound(input: String)
}

final class StickerSearchParser {

    private let album: AlbumDataService

    init(album: AlbumDataService = .shared) {
        self.album = album
    }

    // MARK: - Parse

    func parse(_ raw: String) -> SearchQuery {
        let input = raw.trimmingCharacters(in: .whitespaces)
        guard !input.isEmpty else { return .unknown }

        // Normalise separators: "TUR-04", "TUR_04", "TUR04" → "TUR 04"
        let normalised = input
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")

        let parts = normalised.split(separator: " ", omittingEmptySubsequences: true)

        // Two-token input: "TUR 04"
        if parts.count == 2,
           let number = Int(parts[1]),
           number > 0 {
            return .stickerCode(countryCode: parts[0].uppercased(), number: number)
        }

        // One-token input
        if parts.count == 1 {
            let token = String(parts[0])

            // Inline number suffix: "TUR04", "TUR4"
            if let (code, number) = splitInlineCode(token), number > 0 {
                return .stickerCode(countryCode: code, number: number)
            }

            let upper = token.uppercased()

            // Exact country code match (≤4 uppercase letters)
            if upper == token.uppercased(),
               upper.count <= 4,
               album.countries.contains(where: { $0.code == upper }) {
                return .countryCode(upper)
            }

            // Country name match (case-insensitive)
            if album.countries.contains(where: {
                $0.name.lowercased().hasPrefix(token.lowercased())
            }) {
                return .countryName(token)
            }
        }

        // Multi-word country name: "Korea Republic", "South Africa"
        if parts.count >= 2 {
            let joined = parts.joined(separator: " ")
            if album.countries.contains(where: {
                $0.name.lowercased().hasPrefix(joined.lowercased())
            }) {
                return .countryName(joined)
            }
        }

        return .unknown
    }

    // MARK: - Resolve

    func resolve(_ query: SearchQuery, states: [CountryMissingState]) -> SearchResult {
        switch query {
        case .unknown:
            return .notFound(input: "")

        case .stickerCode(let code, let number):
            guard let country = album.countries.first(where: { $0.code == code }),
                  number >= 1, number <= country.stickerCount else {
                return .notFound(input: "\(code) \(String(format: "%02d", number))")
            }
            let missing = AlbumStateService.missingNumbers(for: code, in: states)
            return .sticker(country: country, number: number, isNeeded: missing.contains(number))

        case .countryCode(let code):
            guard let country = album.countries.first(where: { $0.code == code }) else {
                return .notFound(input: code)
            }
            let missing = AlbumStateService.missingNumbers(for: code, in: states).sorted()
            return .country(country: country, missingNumbers: missing)

        case .countryName(let name):
            guard let country = album.countries.first(where: {
                $0.name.lowercased().hasPrefix(name.lowercased())
            }) else {
                return .notFound(input: name)
            }
            let missing = AlbumStateService.missingNumbers(for: country.code, in: states).sorted()
            return .country(country: country, missingNumbers: missing)
        }
    }

    // MARK: - Helpers

    // Splits "TUR04" or "TUR4" into ("TUR", 4)
    private func splitInlineCode(_ token: String) -> (String, Int)? {
        let letters = token.prefix(while: { $0.isLetter })
        let digits = token.dropFirst(letters.count)
        guard !letters.isEmpty, !digits.isEmpty, let number = Int(digits) else { return nil }
        return (letters.uppercased(), number)
    }
}
