import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var editor: PDFEditorModel

    var body: some View {
        HStack(spacing: 0) {
            if editor.isSidebarVisible, editor.document != nil {
                ThumbnailSidebarView()
                    .frame(width: 168)
                Divider()
            }

            VStack(spacing: 0) {
                EditorToolbarView()
                Divider()

                ZStack {
                    if editor.document != nil {
                        PDFKitEditorView(editor: editor)
                            .ignoresSafeArea(edges: .bottom)
                    } else {
                        WelcomeView()
                    }
                }
            }

            if editor.isInspectorVisible {
                Divider()
                InspectorView()
                    .frame(width: 312)
            }
        }
        .background(.regularMaterial)
        .fileImporter(
            isPresented: Binding(
                get: { false },
                set: { _ in }
            ),
            allowedContentTypes: [.pdf]
        ) { _ in }
    }
}

struct WelcomeView: View {
    @EnvironmentObject private var editor: PDFEditorModel
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .shadow(radius: 12, y: 5)

            VStack(spacing: 6) {
                Text("Free PDF Editor")
                    .font(.system(size: 30, weight: .semibold))
                Text("Open a PDF, then replace text, highlight, add signatures, and export a clean copy.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }

            Button {
                editor.openWithPanel()
            } label: {
                Label("Open PDF", systemImage: "doc.badge.plus")
                    .frame(width: 160)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            RoundedRectangle(cornerRadius: 8)
                .fill(isTargeted ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08))
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                        Text("Drop a PDF here")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 360, height: 120)
                .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                    guard let provider = providers.first else { return false }
                    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                        if let data = item as? Data,
                           let url = URL(dataRepresentation: data, relativeTo: nil),
                           url.pathExtension.lowercased() == "pdf" {
                            Task { @MainActor in editor.open(url: url) }
                        }
                    }
                    return true
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var editor: PDFEditorModel

    var body: some View {
        Form {
            Picker("Default text font", selection: $editor.textFontName) {
                ForEach(editor.availableFontFamilies, id: \.self) { family in
                    Text(family).tag(family)
                }
            }
            Stepper("Default size: \(Int(editor.textFontSize)) pt", value: $editor.textFontSize, in: 8...96)
            ColorPicker("Text color", selection: Binding(
                get: { Color(editor.textColor) },
                set: { editor.textColor = NSColor($0) }
            ))
            ColorPicker("Cover color", selection: Binding(
                get: { Color(editor.coverColor) },
                set: { editor.coverColor = NSColor($0) }
            ))
        }
        .padding(24)
        .frame(width: 420)
    }
}
