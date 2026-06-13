import SwiftUI
import SwiftData
import AVFoundation

// TEMPORARY DEBUG live single-sticker scanner (Phase 3A.2).
// Shows a camera preview, runs throttled OCR, and alerts when a needed
// sticker is detected. Does not mark anything as found.
struct LiveScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var vm = LiveScannerViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                if vm.permissionDenied {
                    permissionDeniedView
                } else {
                    CameraPreview(session: vm.controller.session)
                        .ignoresSafeArea()

                    VStack {
                        scanHint
                        Spacer()
                        if let detection = vm.latest {
                            resultOverlay(detection)
                                .id(detection.id)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding()
                    .animation(.easeOut(duration: 0.2), value: vm.latest?.id)
                }
            }
            .navigationTitle("Live Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await vm.start(context: modelContext)
            }
            .onDisappear { vm.stop() }
        }
    }

    // MARK: - Overlays

    private var scanHint: some View {
        Text("Point at a sticker's back-side code")
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.black.opacity(0.5))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func resultOverlay(_ detection: LiveScannerViewModel.Detection) -> some View {
        switch detection.status {
        case .needed:
            VStack(spacing: 8) {
                Text("NEEDED")
                    .font(.system(size: 44, weight: .heavy))
                    .foregroundStyle(.white)
                Text(detection.stickerCode)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text(detection.country.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Page \(detection.country.page)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(Color.red.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 20))

        case .notNeeded:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Not Needed")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(detection.stickerCode) · \(detection.country.name)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer()
            }
            .padding(14)
            .background(.black.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Camera access needed")
                .font(.headline)
            Text("Enable camera access in Settings to use the live scanner.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Camera preview

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
