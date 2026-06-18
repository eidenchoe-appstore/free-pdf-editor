import SwiftUI

struct EditorToolbarView: View {
    @EnvironmentObject private var editor: PDFEditorModel

    var body: some View {
        HStack(spacing: 10) {
            Button { editor.toggleSidebar() } label: {
                Image(systemName: editor.isSidebarVisible ? "sidebar.left" : "sidebar.left")
                    .symbolVariant(editor.isSidebarVisible ? .none : .slash)
            }
            .help("Toggle thumbnails")

            Button { editor.openWithPanel() } label: {
                Image(systemName: "folder")
            }
            .help("Open PDF")

            Button { editor.save() } label: {
                Image(systemName: editor.isSaving ? "arrow.triangle.2.circlepath" : "square.and.arrow.down")
            }
            .disabled(editor.document == nil || editor.isSaving)
            .help("Save")

            Divider().frame(height: 24)

            Button { editor.goToPreviousPage() } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!editor.canNavigateToPreviousPage)

            Text(editor.currentPageLabel)
                .font(.system(size: 12, weight: .medium).monospacedDigit())
                .frame(width: 58)
                .foregroundStyle(.secondary)

            Button { editor.goToNextPage() } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!editor.canNavigateToNextPage)

            Divider().frame(height: 24)

            toolPicker

            Divider().frame(height: 24)

            Button { editor.zoomOut() } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .disabled(editor.document == nil)

            Text("\(Int(editor.zoomScale * 100))%")
                .font(.system(size: 12, weight: .medium).monospacedDigit())
                .frame(width: 48)

            Button { editor.zoomIn() } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .disabled(editor.document == nil)

            Spacer()

            Menu {
                ForEach(ReadingMode.allCases) { mode in
                    Button {
                        editor.readingMode = mode
                    } label: {
                        Label(mode.rawValue, systemImage: mode.systemImage)
                    }
                }
            } label: {
                Label(editor.readingMode.rawValue, systemImage: editor.readingMode.systemImage)
                    .frame(width: 92, alignment: .leading)
            }
            .menuStyle(.borderlessButton)

            Button { editor.toggleInspector() } label: {
                Image(systemName: editor.isInspectorVisible ? "sidebar.right" : "sidebar.right")
                    .symbolVariant(editor.isInspectorVisible ? .none : .slash)
            }
            .help("Toggle inspector")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(.bar)
    }

    private var toolPicker: some View {
        Picker("Tool", selection: $editor.activeTool) {
            ForEach(EditorTool.allCases) { tool in
                Image(systemName: tool.systemImage).tag(tool)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 520)
        .disabled(editor.document == nil)
        .help("Editing tools")
    }
}
