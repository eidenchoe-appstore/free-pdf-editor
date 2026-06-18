import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct FreePDFEditorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var editor = PDFEditorModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(editor)
                .frame(minWidth: 1040, minHeight: 700)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open PDF...") { editor.openWithPanel() }
                    .keyboardShortcut("o")
            }

            CommandGroup(replacing: .saveItem) {
                Button("Save") { editor.save() }
                    .keyboardShortcut("s")
                    .disabled(editor.document == nil || editor.isSaving)
                Button("Save As...") { editor.saveAs() }
                    .keyboardShortcut("s", modifiers: [.command, .shift])
                    .disabled(editor.document == nil || editor.isSaving)
                Button("Export Flattened PDF...") { editor.exportFlattened() }
                    .disabled(editor.document == nil || editor.isSaving)
            }

            CommandGroup(after: .toolbar) {
                Button("Toggle Thumbnails") { editor.toggleSidebar() }
                    .keyboardShortcut("s", modifiers: [.command, .option])
                Button("Toggle Inspector") { editor.toggleInspector() }
                    .keyboardShortcut("i", modifiers: [.command, .option])

                Divider()

                Button("Previous Page") { editor.goToPreviousPage() }
                    .keyboardShortcut(.leftArrow, modifiers: [.command])
                    .disabled(!editor.canNavigateToPreviousPage)
                Button("Next Page") { editor.goToNextPage() }
                    .keyboardShortcut(.rightArrow, modifiers: [.command])
                    .disabled(!editor.canNavigateToNextPage)

                Divider()

                Button("Zoom In") { editor.zoomIn() }
                    .keyboardShortcut("=", modifiers: [.command])
                    .disabled(editor.document == nil)
                Button("Zoom Out") { editor.zoomOut() }
                    .keyboardShortcut("-", modifiers: [.command])
                    .disabled(editor.document == nil)
                Button("Actual Size") { editor.zoomToActualSize() }
                    .keyboardShortcut("0", modifiers: [.command])
                    .disabled(editor.document == nil)
            }

            CommandMenu("PDF Tools") {
                Button("Select") { editor.setTool(.select) }
                    .keyboardShortcut("1")
                    .disabled(editor.document == nil)
                Button("Replace Text") { editor.setTool(.replaceText) }
                    .keyboardShortcut("2")
                    .disabled(editor.document == nil)
                Button("Highlight") { editor.setTool(.highlight) }
                    .keyboardShortcut("3")
                    .disabled(editor.document == nil)
                Button("Underline") { editor.setTool(.underline) }
                    .keyboardShortcut("4")
                    .disabled(editor.document == nil)
                Button("Strikeout") { editor.setTool(.strikeout) }
                    .keyboardShortcut("5")
                    .disabled(editor.document == nil)
                Button("Text Box") { editor.setTool(.textBox) }
                    .keyboardShortcut("6")
                    .disabled(editor.document == nil)
                Button("Comment") { editor.setTool(.comment) }
                    .keyboardShortcut("7")
                    .disabled(editor.document == nil)
                Button("Rectangle") { editor.setTool(.rectangle) }
                    .keyboardShortcut("8")
                    .disabled(editor.document == nil)
                Button("Signature") { editor.setTool(.signature) }
                    .keyboardShortcut("9")
                    .disabled(editor.document == nil)
                Divider()
                Button("Ellipse") { editor.setTool(.ellipse) }
                    .keyboardShortcut("8", modifiers: [.command, .option])
                    .disabled(editor.document == nil)
                Button("Line") { editor.setTool(.line) }
                    .keyboardShortcut("9", modifiers: [.command, .option])
                    .disabled(editor.document == nil)
                Button("Stamp") { editor.setTool(.stamp) }
                    .keyboardShortcut("t", modifiers: [.command, .option])
                    .disabled(editor.document == nil)
                Divider()
                Button("Delete Selection") { editor.deleteSelectedAnnotation() }
                    .keyboardShortcut(.delete, modifiers: [])
                    .disabled(editor.selectedAnnotation == nil)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(editor)
        }
    }
}
