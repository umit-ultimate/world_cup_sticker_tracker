import SwiftUI
import SwiftData

struct ScanBasketView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \ScanBasketItem.lastScannedAt, order: .reverse) private var items: [ScanBasketItem]
    @Query private var missingStates: [CountryMissingState]

    @State private var shareURL: URL? = nil
    @State private var showingDocumentPicker = false
    @State private var insight: ScanBasketService.Insight? = nil
    @State private var showingClearConfirm = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if items.isEmpty {
                        emptyState
                    } else {
                        summarySection
                        basketList
                    }

                    basketActions

                    if let insight { insightSection(insight) }
                }
                .padding(16)
            }
            .navigationTitle("Scan Basket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                if !items.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Clear", role: .destructive) { showingClearConfirm = true }
                    }
                }
            }
            .confirmationDialog("Clear Scan Basket?", isPresented: $showingClearConfirm, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) { clearBasket() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all \(items.count) scanned stickers.")
            }
            .sheet(item: $shareURL) { url in
                ShareSheet(url: url).ignoresSafeArea()
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker { url in handleImport(url: url) }.ignoresSafeArea()
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "basket")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Scan Basket is empty")
                .font(.headline)
            Text("Use the Live Scanner to scan sticker backs. Detected stickers will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 24)
    }

    // MARK: - Summary

    private var summarySection: some View {
        let needed = items.filter(\.neededByExporter).count
        let notNeeded = items.count - needed
        return HStack(spacing: 0) {
            summaryCell(value: items.count, label: "Scanned", color: .primary)
            Divider().frame(height: 44)
            summaryCell(value: needed, label: "Needed", color: .red)
            Divider().frame(height: 44)
            summaryCell(value: notNeeded, label: "Not Needed", color: .green)
        }
        .padding(.vertical, 4)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func summaryCell(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3).fontWeight(.semibold).foregroundStyle(color)
            Text(label)
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: - Basket list

    private var basketList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Scanned Stickers")
                .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayCode)
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                            Text(relativeTime(item.lastScannedAt))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text(item.neededByExporter ? "Needed" : "Not Needed")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(item.neededByExporter ? .red : .green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background((item.neededByExporter ? Color.red : Color.green).opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    if item.stickerID != items.last?.stickerID {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Export / Import buttons

    private var basketActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Share & Import")
                .font(.footnote).fontWeight(.semibold).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                shareURL = ScanBasketService.write(items: items)
                if shareURL == nil {
                    alertTitle = "Export Failed"
                    alertMessage = "Could not write basket file."
                    showingAlert = true
                }
            } label: {
                Label("Share Scan Basket", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .disabled(items.isEmpty)

            Button {
                showingDocumentPicker = true
            } label: {
                Label("Import Scan Basket for Insight", systemImage: "square.and.arrow.down.on.square")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.indigo)
        }
    }

    // MARK: - Clear

    private func clearBasket() {
        for item in items { modelContext.delete(item) }
        try? modelContext.save()
        insight = nil
    }

    // MARK: - Import

    private func handleImport(url: URL) {
        do {
            let entries = try ScanBasketService.validate(url: url)
            insight = ScanBasketService.computeInsight(entries: entries, states: missingStates)
        } catch {
            alertTitle = "Invalid Basket"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    // MARK: - Insight

    private func insightSection(_ result: ScanBasketService.Insight) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Import Insight")
                    .font(.headline)
                Spacer()
                Text("\(result.totalCount) stickers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if result.likelyAvailable.isEmpty && result.possiblyTaken.isEmpty && result.notNeeded.isEmpty {
                Text("No matching stickers found.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !result.likelyAvailable.isEmpty {
                insightGroup(
                    title: "Needed by Me — Likely Available",
                    subtitle: nil,
                    items: result.likelyAvailable,
                    color: .green,
                    icon: "star.circle.fill"
                )
            }

            if !result.possiblyTaken.isEmpty {
                insightGroup(
                    title: "Needed by Me — Possibly Already Taken",
                    subtitle: "This sticker was needed by the exporter and may already have been taken.",
                    items: result.possiblyTaken,
                    color: .orange,
                    icon: "exclamationmark.triangle.fill"
                )
            }

            if !result.notNeeded.isEmpty {
                insightGroup(
                    title: "Not Needed by Me",
                    subtitle: nil,
                    items: result.notNeeded,
                    color: .secondary,
                    icon: "circle"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func insightGroup(
        title: String,
        subtitle: String?,
        items: [ScanBasketService.Insight.Item],
        color: Color,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(color)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(items) { item in
                    Text(item.displayCode)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity)
                        .background(color.opacity(0.12))
                        .foregroundStyle(color)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
        }
        .padding(12)
        .background(color.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ScanBasketView()
        .modelContainer(for: [CountryMissingState.self, ScanBasketItem.self], inMemory: true)
}
