import AppKit
import Foundation

@MainActor
final class SignatureStore: ObservableObject {
    @Published private(set) var signatures: [SignatureItem] = []
    @Published var selectedSignatureID: UUID?

    private let metadataKey = "FreePDFEditor.Signatures"

    init() {
        load()
    }

    var selectedSignature: SignatureItem? {
        guard let selectedSignatureID else { return signatures.first }
        return signatures.first { $0.id == selectedSignatureID }
    }

    func image(for item: SignatureItem) -> NSImage? {
        NSImage(contentsOf: signatureDirectory.appendingPathComponent(item.filename))
    }

    func addSignature(image: NSImage, name: String) throws {
        try FileManager.default.createDirectory(at: signatureDirectory, withIntermediateDirectories: true)
        guard let pngData = image.pngData() else { throw SignatureStoreError.imageEncodingFailed }
        let filename = "\(UUID().uuidString).png"
        try pngData.write(to: signatureDirectory.appendingPathComponent(filename))
        let item = SignatureItem(name: name.isEmpty ? "Signature \(signatures.count + 1)" : name, filename: filename)
        signatures.insert(item, at: 0)
        selectedSignatureID = item.id
        saveMetadata()
    }

    func importSignatureWithPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Import Signature Image"
        guard panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) else { return }
        try? addSignature(image: image, name: url.deletingPathExtension().lastPathComponent)
    }

    func remove(_ item: SignatureItem) {
        try? FileManager.default.removeItem(at: signatureDirectory.appendingPathComponent(item.filename))
        signatures.removeAll { $0.id == item.id }
        if selectedSignatureID == item.id {
            selectedSignatureID = signatures.first?.id
        }
        saveMetadata()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let items = try? JSONDecoder().decode([SignatureItem].self, from: data) else {
            signatures = []
            selectedSignatureID = nil
            return
        }
        signatures = items.filter { FileManager.default.fileExists(atPath: signatureDirectory.appendingPathComponent($0.filename).path) }
        selectedSignatureID = signatures.first?.id
    }

    private func saveMetadata() {
        if let data = try? JSONEncoder().encode(signatures) {
            UserDefaults.standard.set(data, forKey: metadataKey)
        }
    }

    private var signatureDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        return base.appendingPathComponent(AppMetadata.bundleIdentifier, isDirectory: true)
            .appendingPathComponent("Signatures", isDirectory: true)
    }
}

enum SignatureStoreError: Error {
    case imageEncodingFailed
}

private extension NSImage {
    func pngData() -> Data? {
        guard let tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
