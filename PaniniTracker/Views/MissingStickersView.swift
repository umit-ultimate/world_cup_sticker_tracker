import SwiftUI
import SwiftData

struct MissingStickersView: View {
    @Query private var states: [CountryMissingState]
    @AppStorage("albumSetupCompleted") private var setupCompleted: Bool = false
    @Environment(\.modelContext) private var modelContext

    // Countries in album order that have at least one missing sticker.
    private var missingGroups: [(country: Country, numbers: [Int])] {
        AlbumDataService.shared.countries.compactMap { country in
            let numbers = AlbumStateService.missingNumbers(for: country.code, in: states)
            guard !numbers.isEmpty else { return nil }
            return (country, numbers.sorted())
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if !setupCompleted {
                    emptySetupState
                } else if missingGroups.isEmpty {
                    allCollectedState
                } else {
                    missingList
                }
            }
            .navigationTitle("Missing Stickers")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - States

    private var emptySetupState: some View {
        ContentUnavailableView(
            "No album data",
            systemImage: "tray",
            description: Text("Complete the album setup on the Dashboard first.")
        )
    }

    private var allCollectedState: some View {
        ContentUnavailableView(
            "Album complete!",
            systemImage: "checkmark.seal.fill",
            description: Text("You have no missing stickers.")
        )
    }

    private var missingList: some View {
        List {
            summarySection
            ForEach(missingGroups, id: \.country.id) { group in
                countrySection(group)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Summary

    private var summarySection: some View {
        Section {
            HStack {
                summaryCell(
                    value: missingGroups.count,
                    label: "Countries",
                    icon: "flag.fill",
                    color: .orange
                )
                Divider()
                summaryCell(
                    value: missingGroups.reduce(0) { $0 + $1.numbers.count },
                    label: "Stickers",
                    icon: "exclamationmark.circle.fill",
                    color: .red
                )
            }
            .padding(.vertical, 4)
        }
    }

    private func summaryCell(value: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
            Text("Missing \(label)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    // MARK: - Country section

    private func markFound(country: Country, number: Int) {
        AlbumStateService.markFound(countryCode: country.code, number: number, context: modelContext)
        let fresh = (try? modelContext.fetch(FetchDescriptor<CountryMissingState>())) ?? []
        BackupService.write(states: fresh)
    }

    private func countrySection(_ group: (country: Country, numbers: [Int])) -> some View {
        Section {
            ForEach(group.numbers, id: \.self) { number in
                Text(String(format: "%@ %02d", group.country.code, number))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            markFound(country: group.country, number: number)
                        } label: {
                            Label("Found", systemImage: "checkmark.circle.fill")
                        }
                        .tint(.green)
                    }
            }
        } header: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.country.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(group.country.code)  ·  Page \(group.country.page)  ·  Group \(group.country.group)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(group.numbers.count) missing")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Capsule())
            }
            .textCase(nil)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    MissingStickersView()
        .modelContainer(for: CountryMissingState.self, inMemory: true)
}
