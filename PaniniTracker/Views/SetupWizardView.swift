import SwiftUI
import SwiftData

struct SetupWizardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var vm: SetupWizardViewModel

    init(existingStates: [CountryMissingState] = []) {
        let preloaded = Dictionary(
            uniqueKeysWithValues: existingStates.map { ($0.countryCode, Set($0.missingNumbers)) }
        )
        _vm = State(initialValue: SetupWizardViewModel(
            countries: AlbumDataService.shared.countries,
            preloadedSelections: preloaded
        ))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                countryHeader
                Divider()
                stickerGrid
                Divider()
                navigationBar
            }
            .navigationTitle("Album Setup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Country header

    private var countryHeader: some View {
        VStack(spacing: 6) {
            Text(vm.currentCountry.name)
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                Label(vm.currentCountry.code, systemImage: "flag")
                Label("Page \(vm.currentCountry.page)", systemImage: "book")
                Label("Group \(vm.currentCountry.group)", systemImage: "person.3")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(vm.progress)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(.bar)
    }

    // MARK: - Sticker grid

    private var stickerGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)
        return ScrollView {
            VStack(spacing: 8) {
                Text("Tap missing stickers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(1 ... vm.currentCountry.stickerCount, id: \.self) { number in
                        StickerCell(
                            number: number,
                            isMissing: vm.isMissing(number)
                        ) {
                            vm.toggle(number)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
        }
    }

    // MARK: - Navigation bar

    private var navigationBar: some View {
        HStack {
            Button(action: vm.goPrevious) {
                Label("Previous", systemImage: "chevron.left")
            }
            .disabled(vm.isFirst)

            Spacer()

            if vm.isLast {
                Button("Finish") {
                    vm.persistAll(context: modelContext)
                    AlbumSetupFlag.isCompleted = true
                    let saved = (try? modelContext.fetch(FetchDescriptor<CountryMissingState>())) ?? []
                    BackupService.write(states: saved)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: vm.goNext) {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                        .environment(\.layoutDirection, .rightToLeft)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.bar)
    }
}

// MARK: - Sticker cell

private struct StickerCell: View {
    let number: Int
    let isMissing: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(String(format: "%02d", number))
                .font(.system(.callout, design: .monospaced))
                .fontWeight(isMissing ? .bold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isMissing ? Color.red.opacity(0.85) : Color(.systemGray5))
                .foregroundStyle(isMissing ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SetupWizardView()
        .modelContainer(for: CountryMissingState.self, inMemory: true)
}
