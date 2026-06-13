import SwiftUI
import SwiftData

struct RootView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView(selectedTab: $selectedTab)
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                .tag(0)

            MissingStickersView()
                .tabItem { Label("Missing", systemImage: "exclamationmark.circle.fill") }
                .tag(1)

            CheckView()
                .tabItem { Label("Check", systemImage: "magnifyingglass") }
                .tag(2)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: CountryMissingState.self, inMemory: true)
}
