import AppKit
import SwiftUI

struct SignatureManagerView: View {
    @EnvironmentObject private var editor: PDFEditorModel
    @State private var isDrawingSheetPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Signatures", icon: "signature")

            HStack {
                Button {
                    isDrawingSheetPresented = true
                } label: {
                    Label("Draw", systemImage: "pencil.tip")
                }
                Button {
                    editor.signatures.importSignatureWithPanel()
                } label: {
                    Label("Import", systemImage: "photo")
                }
            }

            if editor.signatures.signatures.isEmpty {
                Text("Draw a signature or import a transparent PNG/JPEG. Select Signature in the toolbar, then click the PDF to place it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(editor.signatures.signatures) { item in
                        SignatureRow(item: item)
                    }
                }
            }
        }
        .sheet(isPresented: $isDrawingSheetPresented) {
            SignatureDrawingSheet()
                .environmentObject(editor)
        }
    }
}

private struct SignatureRow: View {
    @EnvironmentObject private var editor: PDFEditorModel
    let item: SignatureItem

    var body: some View {
        HStack(spacing: 10) {
            if let image = editor.signatures.image(for: item) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 34)
                    .padding(5)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.callout)
                Text(item.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                editor.signatures.selectedSignatureID = item.id
                editor.activeTool = .signature
            } label: {
                Image(systemName: editor.signatures.selectedSignatureID == item.id ? "checkmark.circle.fill" : "circle")
            }
            .help("Use this signature")

            Button(role: .destructive) {
                editor.signatures.remove(item)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(editor.signatures.selectedSignatureID == item.id ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

struct SignatureDrawingSheet: View {
    @EnvironmentObject private var editor: PDFEditorModel
    @Environment(\.dismiss) private var dismiss
    @State private var signatureImage: NSImage?
    @State private var name = "My Signature"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Draw Signature")
                .font(.title3.weight(.semibold))
            TextField("Signature name", text: $name)
                .textFieldStyle(.roundedBorder)

            SignatureCanvasView(signatureImage: $signatureImage)
                .frame(width: 520, height: 180)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3))
                }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save Signature") {
                    if let signatureImage {
                        try? editor.signatures.addSignature(image: signatureImage, name: name)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(signatureImage == nil)
            }
        }
        .padding(22)
    }
}
