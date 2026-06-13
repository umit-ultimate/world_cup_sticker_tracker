import Foundation

struct Sticker: Identifiable {
    let country: Country
    let number: Int

    var id: String { code }

    var code: String {
        String(format: "%@ %02d", country.code, number)
    }
}
