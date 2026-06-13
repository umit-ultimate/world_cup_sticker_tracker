import SwiftUI
import SwiftData

struct CheckView: View {
    @Query private var states: [CountryMissingState]
    @AppStorage("albumSetupCompleted") private var setupCompleted: Bool = false
    @State private var input: String = ""
    @State private var bulkInput: String = ""
    @State private var bulkSuccessMessage: String? = nil
    @FocusState private var isInputFocused: Bool
    @Environment(\.modelContext) private var modelContext

    private let parser = StickerSearchParser()

    private var trimmedInput: String { input.trimmingCharacters(in: .whitespaces) }

    private var result: SearchResult? {
        guard !trimmedInput.isEmpty else { return nil }
        let query = parser.parse(trimmedInput)
        // Block sticker status before setup is done to prevent misleading "Not Needed" results.
        if !setupCompleted, case .stickerCode = query { return nil }
        return parser.resolve(query, states: states)
    }

    private var bulkResult: BulkParseResult { parseBulkInput() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Single sticker search
                    VStack(spacing: 8) {
                        searchBar
                        if trimmedInput.isEmpty { exampleChips }
                    }
                    Divider()

                    if let result {
                        resultCard(result).padding(16)
                    } else if !setupCompleted && isStickerCodeInput {
                        setupRequiredMessage.padding(32)
                    } else if !trimmedInput.isEmpty {
                        placeholder.padding(32)
                    }

                    // Bulk update section
                    Divider().padding(.top, trimmedInput.isEmpty ? 0 : 8)
                    bulkUpdateSection
                }
            }
            .navigationTitle("Check")
            .navigationBarTitleDisplayMode(.large)
            .alert("Applied", isPresented: Binding(
                get: { bulkSuccessMessage != nil },
                set: { if !$0 { bulkSuccessMessage = nil } }
            )) {
                Button("OK") { bulkSuccessMessage = nil }
            } message: {
                Text(bulkSuccessMessage ?? "")
            }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("TUR 04 · Turkey · TUR", text: $input)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .focused($isInputFocused)
                .submitLabel(.search)
            if !input.isEmpty {
                Button {
                    input = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Example chips

    private var exampleChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text("Try:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(["TUR 04", "GER 20", "Turkey", "ENG"], id: \.self) { example in
                    Button(example) { input = example }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color(.separator), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Setup required / placeholder

    private var isStickerCodeInput: Bool {
        guard !trimmedInput.isEmpty else { return false }
        if case .stickerCode = parser.parse(trimmedInput) { return true }
        return false
    }

    private var setupRequiredMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("Album setup required")
                .font(.headline)
            Text("Complete album setup first to check whether stickers are needed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.quaternary)
            Text("Enter a sticker code, country code, or country name.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Result card routing

    @ViewBuilder
    private func resultCard(_ result: SearchResult) -> some View {
        switch result {
        case .sticker(let country, let number, let isNeeded):
            StickerResultCard(
                country: country,
                number: number,
                isNeeded: isNeeded,
                onMarkFound: isNeeded ? { markFound(country: country, number: number) } : nil
            )
        case .country(let country, let missingNumbers):
            CountryResultCard(country: country, missingNumbers: missingNumbers)
        case .notFound(let input):
            NotFoundCard(input: input)
        }
    }

    // MARK: - Mark as found (single)

    private func markFound(country: Country, number: Int) {
        AlbumStateService.markFound(countryCode: country.code, number: number, context: modelContext)
        writeBackup()
    }

    // MARK: - Bulk update section

    private var bulkUpdateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bulk Update")
                    .font(.headline)
                Text("Paste sticker codes to mark multiple as found at once.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $bulkInput)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100, maxHeight: 180)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if bulkInput.isEmpty {
                    Text("TUR 04\nGER 06, ENG 12\nTUR04 ARG-05")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 16)

            if !bulkResult.isEmpty {
                bulkPreviewCard(bulkResult)
                    .padding(.horizontal, 16)

                if !bulkResult.willMarkFound.isEmpty {
                    Button {
                        applyBulkFound(bulkResult.willMarkFound)
                    } label: {
                        Label("Mark \(bulkResult.willMarkFound.count) as Found", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 16)
    }

    private func bulkPreviewCard(_ result: BulkParseResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !result.willMarkFound.isEmpty {
                previewGroup(
                    title: "Will mark as found (\(result.willMarkFound.count))",
                    codes: result.willMarkFound.map { String(format: "%@ %02d", $0.country.code, $0.number) },
                    color: .green,
                    icon: "checkmark.circle.fill"
                )
            }
            if !result.alreadyOwned.isEmpty {
                if !result.willMarkFound.isEmpty { Divider() }
                previewGroup(
                    title: "Already owned (\(result.alreadyOwned.count))",
                    codes: result.alreadyOwned.map { String(format: "%@ %02d", $0.country.code, $0.number) },
                    color: .secondary,
                    icon: "checkmark.circle"
                )
            }
            if !result.invalid.isEmpty {
                if !result.willMarkFound.isEmpty || !result.alreadyOwned.isEmpty { Divider() }
                previewGroup(
                    title: "Invalid (\(result.invalid.count))",
                    codes: result.invalid,
                    color: .orange,
                    icon: "exclamationmark.triangle.fill"
                )
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func previewGroup(title: String, codes: [String], color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(codes, id: \.self) { code in
                    Text(code)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(color.opacity(0.1))
                        .foregroundStyle(color)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }

    // MARK: - Bulk parsing

    private func parseBulkInput() -> BulkParseResult {
        let rawText = bulkInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawText.isEmpty else {
            return BulkParseResult(willMarkFound: [], alreadyOwned: [], invalid: [])
        }

        // Step 1: split by newlines and commas into segments
        let segments = rawText
            .components(separatedBy: CharacterSet.newlines.union(.init(charactersIn: ",")))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Step 2: each segment either parses as a single code ("TUR 04") or
        // gets split by whitespace into inline codes ("TUR04 GER-06")
        var rawTokens: [String] = []
        for segment in segments {
            if case .stickerCode = parser.parse(segment) {
                rawTokens.append(segment)
            } else {
                let subTokens = segment
                    .split(separator: " ", omittingEmptySubsequences: true)
                    .map(String.init)
                rawTokens.append(contentsOf: subTokens)
            }
        }

        // Step 3: classify, deduplicating by normalized key
        var seenKeys = Set<String>()
        var seenInvalid = Set<String>()
        var willMarkFound: [(country: Country, number: Int)] = []
        var alreadyOwned: [(country: Country, number: Int)] = []
        var invalid: [String] = []

        for token in rawTokens {
            guard case .stickerCode(let code, let number) = parser.parse(token) else {
                let display = token.uppercased()
                if seenInvalid.insert(display).inserted { invalid.append(display) }
                continue
            }

            let key = "\(code)-\(number)"
            guard seenKeys.insert(key).inserted else { continue }

            guard let country = AlbumDataService.shared.countries.first(where: { $0.code == code }),
                  number >= 1, number <= country.stickerCount else {
                let display = String(format: "%@ %02d", code, number)
                if seenInvalid.insert(display).inserted { invalid.append(display) }
                continue
            }

            let missing = AlbumStateService.missingNumbers(for: code, in: states)
            if missing.contains(number) {
                willMarkFound.append((country, number))
            } else {
                alreadyOwned.append((country, number))
            }
        }

        return BulkParseResult(willMarkFound: willMarkFound, alreadyOwned: alreadyOwned, invalid: invalid)
    }

    // MARK: - Apply bulk found

    private func applyBulkFound(_ items: [(country: Country, number: Int)]) {
        for item in items {
            AlbumStateService.markFound(countryCode: item.country.code, number: item.number, context: modelContext)
        }
        writeBackup()
        bulkInput = ""
        bulkSuccessMessage = "Marked \(items.count) sticker\(items.count == 1 ? "" : "s") as found."
    }

    // MARK: - Backup

    private func writeBackup() {
        let fresh = (try? modelContext.fetch(FetchDescriptor<CountryMissingState>())) ?? []
        BackupService.write(states: fresh)
    }
}

// MARK: - Bulk parse result

private struct BulkParseResult {
    let willMarkFound: [(country: Country, number: Int)]
    let alreadyOwned: [(country: Country, number: Int)]
    let invalid: [String]

    var isEmpty: Bool { willMarkFound.isEmpty && alreadyOwned.isEmpty && invalid.isEmpty }
}

// MARK: - Sticker result card

private struct StickerResultCard: View {
    let country: Country
    let number: Int
    let isNeeded: Bool
    var onMarkFound: (() -> Void)? = nil

    private var stickerCode: String {
        String(format: "%@ %02d", country.code, number)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Status badge
            VStack(spacing: 8) {
                Image(systemName: isNeeded ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(isNeeded ? .red : .green)
                Text(isNeeded ? "Needed" : "Not Needed")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(isNeeded ? .red : .green)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background((isNeeded ? Color.red : Color.green).opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Sticker details
            VStack(spacing: 0) {
                detailRow(label: "Sticker", value: stickerCode, mono: true)
                Divider().padding(.leading, 16)
                detailRow(label: "Country", value: country.name)
                Divider().padding(.leading, 16)
                detailRow(label: "Code", value: country.code, mono: true)
                Divider().padding(.leading, 16)
                detailRow(label: "Album page", value: "Page \(country.page)")
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Mark as Found action (only when sticker is needed)
            if let onMarkFound {
                Button(action: onMarkFound) {
                    Label("Mark as Found", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .controlSize(.large)
            }
        }
    }
}

// MARK: - Country result card

private struct CountryResultCard: View {
    let country: Country
    let missingNumbers: [Int]

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text(country.name)
                    .font(.title2)
                    .fontWeight(.bold)
                HStack(spacing: 16) {
                    Label(country.code, systemImage: "flag")
                    Label("Page \(country.page)", systemImage: "book")
                    Label("Group \(country.group)", systemImage: "person.3")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if missingNumbers.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("No missing stickers for this country.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Missing stickers")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(missingNumbers.count) missing")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(missingNumbers, id: \.self) { n in
                            Text(String(format: "%02d", n))
                                .font(.system(.callout, design: .monospaced))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.12))
                                .foregroundStyle(.red)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Not found card

private struct NotFoundCard: View {
    let input: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("No result for \"\(input)\"")
                .font(.headline)
            Text("Try a sticker code like TUR 04, a country code like GER, or a country name like England.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Shared helper

private func detailRow(label: String, value: String, mono: Bool = false) -> some View {
    HStack {
        Text(label)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        Spacer()
        Text(value)
            .font(mono ? .system(.subheadline, design: .monospaced) : .subheadline)
            .fontWeight(.medium)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
}

#Preview {
    CheckView()
        .modelContainer(for: CountryMissingState.self, inMemory: true)
}
