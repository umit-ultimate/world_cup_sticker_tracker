import Foundation
import SwiftData

@Observable
final class SetupWizardViewModel {

    let countries: [Country]
    private(set) var currentIndex: Int = 0
    // countryCode -> selected missing numbers
    private var selections: [String: Set<Int>] = [:]

    init(countries: [Country], preloadedSelections: [String: Set<Int>] = [:]) {
        self.countries = countries
        self.selections = preloadedSelections
    }

    var currentCountry: Country { countries[currentIndex] }
    var isFirst: Bool { currentIndex == 0 }
    var isLast: Bool { currentIndex == countries.count - 1 }
    var progress: String { "\(currentIndex + 1) / \(countries.count)" }

    func isMissing(_ number: Int) -> Bool {
        selections[currentCountry.code, default: []].contains(number)
    }

    func toggle(_ number: Int) {
        let code = currentCountry.code
        if selections[code, default: []].contains(number) {
            selections[code]?.remove(number)
        } else {
            selections[code, default: []].insert(number)
        }
    }

    func goNext() {
        guard !isLast else { return }
        currentIndex += 1
    }

    func goPrevious() {
        guard !isFirst else { return }
        currentIndex -= 1
    }

    func persistAll(context: ModelContext) {
        for country in countries {
            let missing = Array(selections[country.code, default: []])
            AlbumStateService.save(
                countryCode: country.code,
                missingNumbers: missing,
                context: context
            )
        }
    }
}
