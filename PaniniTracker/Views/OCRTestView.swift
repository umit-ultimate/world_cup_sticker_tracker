import SwiftUI
import PhotosUI

// TEMPORARY OCR proof-of-concept screen (Phase 3A.0).
// Lets you pick a photo, runs Apple Vision text recognition, and shows
// the raw OCR output alongside parsed sticker codes.
// No SwiftData, no album lookup, no camera, no backup — validation only.
struct OCRTestView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var ocrResult: OCRService.Result?
    @State private var validation: StickerCodeOCRParser.ValidationOutput?
    @State private var isProcessing = false
    @State private var errorMessage: String?

    private let ocr = OCRService()
    private let parser = StickerCodeOCRParser()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    picker
                    if let selectedImage { imagePreview(selectedImage) }
                    if isProcessing { ProgressView("Recognizing text…").padding() }
                    if let errorMessage { errorBanner(errorMessage) }
                    if validation != nil { parsedSection }
                    #if DEBUG
                    if let validation, !validation.rejected.isEmpty { rejectedSection(validation.rejected) }
                    #endif
                    if let ocrResult { rawSection(ocrResult) }
                }
                .padding(16)
            }
            .navigationTitle("OCR Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                guard let newItem else { return }
                loadAndRecognize(newItem)
            }
        }
    }

    // MARK: - Picker

    private var picker: some View {
        PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
            Label("Select Test Image", systemImage: "photo.on.rectangle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private func imagePreview(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 240)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(.separator), lineWidth: 0.5))
    }

    private func errorBanner(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.subheadline)
            .foregroundStyle(.orange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Parsed codes

    private var parsedSection: some View {
        let accepted = validation?.accepted ?? []
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Parsed Sticker Codes")
                    .font(.headline)
                Spacer()
                Text("\(accepted.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Validated against album catalog")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if accepted.isEmpty {
                Text("No valid sticker codes detected.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                ForEach(accepted) { code in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Country: \(code.countryCode)")
                                .font(.system(.subheadline, design: .monospaced))
                            Text("Sticker: \(code.number)")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(code.display)
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                    .padding(.vertical, 4)
                    if code.id != accepted.last?.id { Divider() }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Rejected candidates (DEBUG)

    #if DEBUG
    private func rejectedSection(_ rejected: [StickerCodeOCRParser.RejectedCandidate]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Rejected Candidates")
                    .font(.headline)
                Spacer()
                Text("\(rejected.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(rejected) { item in
                HStack(alignment: .top) {
                    Text(item.parsed.rawMatch)
                        .font(.system(.subheadline, design: .monospaced))
                        .strikethrough()
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.reason.description)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.trailing)
                }
                .padding(.vertical, 3)
                if item.id != rejected.last?.id { Divider() }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    #endif

    // MARK: - Raw OCR output

    private func rawSection(_ result: OCRService.Result) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Raw OCR Output")
                    .font(.headline)
                Spacer()
                if let avg = result.averageConfidence {
                    Text("avg conf \(String(format: "%.0f%%", avg * 100))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if result.lines.isEmpty {
                Text("No text detected.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(result.lines) { line in
                    HStack(alignment: .firstTextBaseline) {
                        Text(line.text)
                            .font(.system(.subheadline, design: .monospaced))
                        Spacer()
                        Text(String(format: "%.0f%%", line.confidence * 100))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Load + recognize

    private func loadAndRecognize(_ item: PhotosPickerItem) {
        isProcessing = true
        errorMessage = nil
        ocrResult = nil
        validation = nil

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    await MainActor.run {
                        errorMessage = "Could not load the selected image."
                        isProcessing = false
                    }
                    return
                }

                let result = try await ocr.recognizeText(in: image)
                let validated = parser.validate(
                    lines: result.lines.map { ($0.text, $0.confidence) },
                    countries: AlbumDataService.shared.countries
                )

                await MainActor.run {
                    selectedImage = image
                    ocrResult = result
                    validation = validated
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isProcessing = false
                }
            }
        }
    }
}

#Preview {
    OCRTestView()
}
