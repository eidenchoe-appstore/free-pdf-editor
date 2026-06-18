import AppKit
import PDFKit
import SwiftUI

struct InspectorView: View {
    @EnvironmentObject private var editor: PDFEditorModel
    @State private var selectedTab = InspectorTab.edit
    @State private var textContents = ""

    var body: some View {
        VStack(spacing: 0) {
            Picker("Inspector", selection: $selectedTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.systemImage).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch selectedTab {
                    case .edit:
                        editPane
                    case .signatures:
                        SignatureManagerView()
                    case .document:
                        documentPane
                    }
                }
                .padding(14)
            }

            Divider()

            HStack(spacing: 8) {
                Circle()
                    .fill(editor.isModified ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                Text(editor.statusMessage)
                    .lineLimit(2)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(12)
        }
        .background(.regularMaterial)
        .onChange(of: editor.selectedAnnotation) { _, annotation in
            textContents = annotation?.contents ?? ""
        }
    }

    private var editPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Active Tool", icon: editor.activeTool.systemImage)

            Text(editor.activeTool.rawValue)
                .font(.headline)

            if editor.activeTool == .replaceText || editor.replacementDraft != nil {
                replacementPane
            }

            Divider()

            SectionHeader(title: "Text Style", icon: "textformat")
            fontControls

            Divider()

            SectionHeader(title: "Annotation Style", icon: "paintpalette")
            ColorPicker("Highlight", selection: Binding(
                get: { Color(editor.highlightColor) },
                set: { editor.highlightColor = NSColor($0) }
            ))
            ColorPicker("Stroke", selection: Binding(
                get: { Color(editor.strokeColor) },
                set: { editor.strokeColor = NSColor($0) }
            ))
            ColorPicker("Fill", selection: Binding(
                get: { Color(editor.fillColor) },
                set: { editor.fillColor = NSColor($0) }
            ))
            Stepper("Line width: \(Int(editor.lineWidth))", value: $editor.lineWidth, in: 1...12)

            Divider()

            SectionHeader(title: "Selected Annotation", icon: "selection.pin.in.out")
            selectedAnnotationPane
        }
    }

    private var replacementPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Replace Detected Text", icon: "character.cursor.ibeam")
            if let draft = editor.replacementDraft {
                Text("Original")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(draft.originalText)
                    .font(.callout)
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                Text("Replacement")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: Binding(
                    get: { editor.replacementDraft?.replacementText ?? "" },
                    set: { editor.replacementDraft?.replacementText = $0 }
                ))
                .font(.system(size: 13))
                .frame(minHeight: 78)
                .overlay {
                    RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2))
                }

                fontControls

                ColorPicker("Replacement color", selection: Binding(
                    get: { Color(editor.textColor) },
                    set: {
                        editor.textColor = NSColor($0)
                        editor.replacementDraft?.textColor = NSColor($0)
                    }
                ))
                ColorPicker("Cover color", selection: Binding(
                    get: { Color(editor.coverColor) },
                    set: {
                        editor.coverColor = NSColor($0)
                        editor.replacementDraft?.coverColor = NSColor($0)
                    }
                ))

                HStack {
                    Button("Cancel") { editor.cancelReplacementDraft() }
                    Spacer()
                    Button("Apply") {
                        editor.replacementDraft?.fontName = editor.textFontName
                        editor.replacementDraft?.fontSize = editor.textFontSize
                        editor.replacementDraft?.textColor = editor.textColor
                        editor.applyReplacementDraft()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Choose Replace Text, then click a native PDF text line.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(Color.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var fontControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Font", selection: $editor.textFontName) {
                ForEach(editor.availableFontFamilies, id: \.self) { family in
                    Text(family).tag(family)
                }
            }
            Stepper("Size: \(Int(editor.textFontSize)) pt", value: $editor.textFontSize, in: 8...96)
            ColorPicker("Text color", selection: Binding(
                get: { Color(editor.textColor) },
                set: { editor.textColor = NSColor($0) }
            ))
        }
    }

    private var selectedAnnotationPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let annotation = editor.selectedAnnotation {
                Text(annotation.type ?? "Annotation")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if annotation.type == "FreeText" {
                    TextEditor(text: $textContents)
                        .frame(minHeight: 72)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2))
                        }
                    HStack {
                        Button("Update Text") {
                            editor.updateSelectedTextAnnotation(contents: textContents)
                        }
                        Button("Delete", role: .destructive) {
                            editor.deleteSelectedAnnotation()
                        }
                    }
                } else {
                    Button("Delete Annotation", role: .destructive) {
                        editor.deleteSelectedAnnotation()
                    }
                }
            } else {
                Text("Select an inserted text box, stamp, signature, or shape to edit it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var documentPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Document", icon: "doc.richtext")
            LabeledContent("Name", value: editor.documentTitle)
            LabeledContent("Pages", value: "\(editor.pageCount)")
            LabeledContent("Version", value: "v\(AppMetadata.version) (\(AppMetadata.build))")

            Divider()

            Button {
                editor.exportFlattened()
            } label: {
                Label("Export Flattened PDF", systemImage: "doc.badge.gearshape")
            }
            .disabled(editor.document == nil)

            Text("Flattened export burns annotations into the visible page. Use it for sharing final copies after placing replacement text and signatures.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private enum InspectorTab: String, CaseIterable, Identifiable {
    case edit = "Edit"
    case signatures = "Sign"
    case document = "File"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .edit: "slider.horizontal.3"
        case .signatures: "signature"
        case .document: "doc"
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
