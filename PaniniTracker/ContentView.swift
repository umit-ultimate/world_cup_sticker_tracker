import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @Query private var states: [CountryMissingState]
    @AppStorage("albumSetupCompleted") private var setupCompleted: Bool = false
    @State private var showingSetup = false
    @State private var showingResetConfirm = false
    @State private var shareURL: URL? = nil

    // Import flow
    @State private var showingDocumentPicker = false
    @State private var pendingImportURL: URL? = nil
    @State private var pendingImportSummary = (countryCount: 0, missingCount: 0)
    @State private var showingImportConfirm = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showingAlert = false

    @State private var showingScanBasket = false

    #if DEBUG
    @State private var showingOCRTest = false
    @State private var showingLiveScanner = false
    #endif

    @Environment(\.modelContext) private var modelContext

    var selectedTab: Binding<Int>?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    Divider()
                        .padding(.horizontal, 24)

                    if setupCompleted {
                        progressSection
                    } else {
                        emptyState
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
            .navigationTitle("Panini Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if setupCompleted {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Reset", role: .destructive) {
                            showingResetConfirm = true
                        }
                        .confirmationDialog(
                            "Reset album?",
                            isPresented: $showingResetConfirm,
                            titleVisibility: .visible
                        ) {
                            Button("Reset", role: .destructive) {
                                BackupService.write(states: states)
                                AlbumStateService.deleteAll(context: modelContext)
                                AlbumSetupFlag.isCompleted = false
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("All missing sticker data will be deleted. A safety backup will be saved first.")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSetup) {
                SetupWizardView(existingStates: states)
            }
            .sheet(item: $shareURL) { url in
                ShareSheet(url: url)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker { url in
                    handlePickedFile(url: url)
                }
                .ignoresSafeArea()
            }
            .confirmationDialog(
                "Import Backup?",
                isPresented: $showingImportConfirm,
                titleVisibility: .visible
            ) {
                Button("Replace Current Data", role: .destructive) {
                    if let url = pendingImportURL {
                        BackupService.restore(from: url, currentStates: states, context: modelContext)
                        alertTitle = "Import Successful"
                        alertMessage = "Restored \(pendingImportSummary.countryCount) countries and \(pendingImportSummary.missingCount) missing stickers."
                        showingAlert = true
                    }
                    pendingImportURL = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingImportURL = nil
                }
            } message: {
                Text("This will replace your current album data with \(pendingImportSummary.countryCount) countries (\(pendingImportSummary.missingCount) missing stickers). A safety backup will be saved first.")
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingScanBasket) {
                ScanBasketView()
            }
            #if DEBUG
            .sheet(isPresented: $showingOCRTest) {
                OCRTestView()
            }
            .fullScreenCover(isPresented: $showingLiveScanner) {
                LiveScannerView()
            }
            #endif
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)
            Text("Panini Tracker")
                .font(.title)
                .fontWeight(.bold)
            Text("World Cup 2026")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty / not set up

    private var emptyState: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "tray")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("Album not set up yet")
                    .font(.headline)
                Text("Go through the wizard once to mark your missing stickers.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button("Start Album Setup") {
                showingSetup = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.top, 8)
    }

    // MARK: - Progress section

    private var progressSection: some View {
        let progress = AlbumStateService.progress(states: states)
        return VStack(spacing: 20) {
            progressGauge(progress)
            statsGrid(progress)
            quickActions
            backupSection
        }
        .padding(.horizontal, 24)
    }

    private func progressGauge(_ p: AlbumProgress) -> some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray4), lineWidth: 14)
            Circle()
                .trim(from: 0, to: min(p.completionPercentage / 100, 1))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: p.completionPercentage)
            VStack(spacing: 2) {
                Text(String(format: "%.1f%%", p.completionPercentage))
                    .font(.title2)
                    .fontWeight(.bold)
                Text("complete")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 130, height: 130)
        .frame(maxWidth: .infinity)
    }

    private func statsGrid(_ p: AlbumProgress) -> some View {
        HStack(spacing: 0) {
            statCell(value: p.totalStickers,   label: "Total",   color: .primary)
            Divider().frame(height: 44)
            statCell(value: p.ownedStickers,   label: "Owned",   color: .green)
            Divider().frame(height: 44)
            statCell(value: p.missingStickers, label: "Missing", color: .red)
        }
        .padding(.vertical, 4)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func statCell(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: - Quick actions

    private var quickActions: some View {
        VStack(spacing: 10) {
            Button {
                selectedTab?.wrappedValue = 1
            } label: {
                Label("View Missing Stickers", systemImage: "exclamationmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Button {
                selectedTab?.wrappedValue = 2
            } label: {
                Label("Check a Sticker", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)

            Button {
                showingSetup = true
            } label: {
                Label("Edit Album", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)

            Button {
                showingScanBasket = true
            } label: {
                Label("Scan Basket", systemImage: "basket")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.indigo)

            #if DEBUG
            Button {
                dumpAlbumState()
            } label: {
                Label("Dump Album State", systemImage: "ladybug")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.purple)

            Button {
                showingOCRTest = true
            } label: {
                Label("OCR Test", systemImage: "text.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.pink)

            Button {
                showingLiveScanner = true
            } label: {
                Label("Live Scanner", systemImage: "camera.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.mint)
            #endif
        }
    }

    // MARK: - Backup section

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Backup")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                if BackupService.write(states: states) != nil {
                    alertTitle = "Backup Exported"
                    alertMessage = "Saved to Documents/panini-backup.json on this device."
                } else {
                    alertTitle = "Export Failed"
                    alertMessage = "Could not write backup file. Please try again."
                }
                showingAlert = true
            } label: {
                Label("Export Backup", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.teal)

            Button {
                shareURL = BackupService.write(states: states)
            } label: {
                Label("Share Backup", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)

            Button {
                showingDocumentPicker = true
            } label: {
                Label("Import Backup", systemImage: "square.and.arrow.down.on.square")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.indigo)
        }
    }

    // MARK: - Import handler

    private func handlePickedFile(url: URL) {
        do {
            let summary = try BackupService.validate(url: url)
            pendingImportURL = url
            pendingImportSummary = summary
            showingImportConfirm = true
        } catch {
            alertTitle = "Invalid Backup"
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }

    // MARK: - Debug

    #if DEBUG
    private func dumpAlbumState() {
        let records = states.map { state in
            [
                "countryCode": state.countryCode,
                "missingNumbers": state.missingNumbers.sorted()
            ] as [String: Any]
        }.sorted { ($0["countryCode"] as! String) < ($1["countryCode"] as! String) }

        let payload: [String: Any] = [
            "recordCount": records.count,
            "totalMissing": records.reduce(0) { $0 + ($1["missingNumbers"] as! [Int]).count },
            "records": records
        ]

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys]),
           let json = String(data: data, encoding: .utf8) {
            print("=== ALBUM STATE DUMP ===")
            print(json)
            print("========================")
        }
    }
    #endif
}

#Preview {
    ContentView(selectedTab: .constant(0))
        .modelContainer(for: CountryMissingState.self, inMemory: true)
}

// ShareSheet and URL+Identifiable are defined in Views/ShareSheet.swift
