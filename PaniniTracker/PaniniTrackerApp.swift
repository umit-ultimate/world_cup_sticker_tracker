import SwiftUI
import SwiftData

@main
struct PaniniTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [CountryMissingState.self, ScanBasketItem.self])
    }
}
