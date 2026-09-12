import SwiftUI
import VisionKit
import AVFoundation

struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    let onFinished: () -> Void
    @State private var method = 0
    @State private var path: [Equipment] = []
    @State private var manualCode = ""
    @State private var error: String?
    @State private var showCamera = false
    @State private var cameraError: String?

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Eyebrow(title: "A little scan. A big possibility.")
                        Text(method == 0 ? "Meet your next tool." : "A tap is all it takes.")
                            .font(.system(size: 32, weight: .medium, design: .serif)).tracking(-1).multilineTextAlignment(.center)
                        Text(method == 0 ? "Find the QR sticker on your equipment." : "Hold your iPhone near the equipment tag.")
                            .font(.system(size: 14)).foregroundStyle(BorrowStyle.muted)
                    }
                    Picker("Scanning method", selection: $method) { Text("QR code").tag(0); Text("NFC tag").tag(1) }.pickerStyle(.segmented)
                    ZStack {
                        RoundedRectangle(cornerRadius: 30).fill(BorrowStyle.ink)
                        Circle().stroke(BorrowStyle.lime.opacity(0.12), lineWidth: 1).frame(width: 235, height: 235)
                        Circle().stroke(BorrowStyle.lime.opacity(0.15), lineWidth: 1).frame(width: 185, height: 185)
                        VStack(spacing: 23) {
                            Image(systemName: method == 0 ? "qrcode.viewfinder" : "wave.3.right.circle").font(.system(size: 100, weight: .ultraLight)).foregroundStyle(BorrowStyle.lime)
                            Text(method == 0 ? "QR SCANNER DEMO" : "NFC TAP DEMO").font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(2).foregroundStyle(.white.opacity(0.7))
                        }
                    }.frame(height: 275).accessibilityLabel(method == 0 ? "Demo QR scan area" : "Demo NFC scan area")
                    VStack(spacing: 12) {
                        PrimaryButton(title: method == 0 ? "Try a demo scan" : "Simulate NFC tap", symbol: method == 0 ? "qrcode" : "wave.3.right") { resolve("BR-001") }
                        Text(method == 0 ? "Opens a sample cordless drill. No camera needed." : "NFC is simulated in this demo. No tag needed.").font(.system(size: 12)).foregroundStyle(BorrowStyle.muted).multilineTextAlignment(.center)
                        if method == 0 {
                            Button("Use iPhone camera") { Task { await openCamera() } }.font(.system(size: 14, weight: .semibold)).padding(.top, 5)
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(title: "Or enter the equipment code")
                        HStack {
                            TextField("e.g. BR-001", text: $manualCode).textInputAutocapitalization(.characters).autocorrectionDisabled().font(.system(size: 15, design: .monospaced)).submitLabel(.go).onSubmit { resolve(manualCode) }
                            Button { resolve(manualCode) } label: { Image(systemName: "arrow.right").frame(width: 44, height: 44).background(BorrowStyle.sand, in: Circle()) }.accessibilityLabel("Find equipment")
                        }.padding(10).background(.white, in: RoundedRectangle(cornerRadius: 18))
                        if let error { Text(error).font(.system(size: 13)).foregroundStyle(.red).accessibilityAddTraits(.updatesFrequently) }
                    }
                }.padding(24)
            }.pageBackground().navigationTitle("Scan to borrow").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close", systemImage: "xmark") { dismiss() }.labelStyle(.iconOnly) } }
                .navigationDestination(for: Equipment.self) { item in
                    EquipmentDetailView(item: item) { dismiss(); onFinished() }
                }
                .sheet(isPresented: $showCamera) {
                    NavigationStack {
                        CameraScanner { code in showCamera = false; resolve(code) } onError: { message in showCamera = false; cameraError = message }
                            .ignoresSafeArea(edges: .bottom).navigationTitle("Scan equipment QR").navigationBarTitleDisplayMode(.inline)
                            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { showCamera = false } } }
                    }
                }
                .alert("Camera unavailable", isPresented: Binding(get: { cameraError != nil }, set: { if !$0 { cameraError = nil } })) { Button("OK") { cameraError = nil } } message: { Text(cameraError ?? "") }
        }.tint(BorrowStyle.ink)
    }

    private func resolve(_ code: String) {
        guard let item = Equipment.resolve(code) else { error = "Equipment not found. Try BR-001, BR-002, or BR-003."; return }
        error = nil
        path.append(item)
    }

    private func openCamera() async {
        guard DataScannerViewController.isSupported else { cameraError = "Live scanning needs a supported iPhone. You can still try a demo scan or enter an equipment code."; return }
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        guard granted, DataScannerViewController.isAvailable else { cameraError = "Camera access is unavailable. Allow camera access in Settings, or use the demo scan."; return }
        showCamera = true
    }
}

struct CameraScanner: UIViewControllerRepresentable {
    var onCode: (String) -> Void
    var onError: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode, onError: onError) }
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(recognizedDataTypes: [.barcode(symbologies: [.qr])], qualityLevel: .balanced, recognizesMultipleItems: false, isHighlightingEnabled: true)
        scanner.delegate = context.coordinator
        return scanner
    }
    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        guard !scanner.isScanning, !context.coordinator.finished else { return }
        do { try scanner.startScanning() } catch { DispatchQueue.main.async { onError("Scanning couldn't start. Please try again or use a demo scan.") } }
    }
    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) { scanner.stopScanning() }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var finished = false
        let onCode: (String) -> Void
        let onError: (String) -> Void
        init(onCode: @escaping (String) -> Void, onError: @escaping (String) -> Void) { self.onCode = onCode; self.onError = onError }
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !finished else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item, let code = barcode.payloadStringValue {
                    finished = true
                    dataScanner.stopScanning()
                    onCode(code)
                    return
                }
            }
        }
        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) { onError("Camera scanning became unavailable. Try a demo scan instead.") }
    }
}
