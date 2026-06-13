import Foundation

final class AlbumDataService {
    static let shared = AlbumDataService()

    let countries: [Country]

    private init() {
        guard
            let url = Bundle.main.url(forResource: "album_data", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([Country].self, from: data)
        else {
            fatalError("album_data.json missing or malformed")
        }
        countries = decoded
    }

    var allStickers: [Sticker] {
        countries.flatMap { stickers(for: $0) }
    }

    func stickersForCountry(code: String) -> [Sticker] {
        guard let country = countries.first(where: { $0.code == code }) else { return [] }
        return stickers(for: country)
    }

    func countryForStickerCode(_ stickerCode: String) -> Country? {
        let parts = stickerCode.split(separator: " ")
        guard let countryCode = parts.first.map(String.init) else { return nil }
        return countries.first(where: { $0.code == countryCode })
    }

    private func stickers(for country: Country) -> [Sticker] {
        (1 ... country.stickerCount).map { Sticker(country: country, number: $0) }
    }
}
