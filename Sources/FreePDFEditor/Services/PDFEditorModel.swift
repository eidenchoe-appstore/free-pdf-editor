import AppKit
import Combine
import Foundation
import PDFKit
import UniformTypeIdentifiers

@MainActor
final class PDFEditorModel: ObservableObject {
    @Published var document: PDFDocument?
    @Published var documentURL: URL?
    @Published var documentTitle: String = "Untitled"
    @Published var isModified = false
    @Published var isSaving = false
    @Published var statusMessage = "Open a PDF to start editing."
    @Published var activeTool: EditorTool = .select
    @Published var readingMode: ReadingMode = .normal
    @Published var zoomScale: CGFloat = 1.0
    @Published var currentPageIndex = 0
    @Published var isSidebarVisible = true
    @Published var isInspectorVisible = true
    @Published var selectedAnnotation: PDFAnnotation?
    @Published var selectedAnnotationPage: PDFPage?
    @Published var replacementDraft: ReplacementDraft?

    @Published var textFontName = "Helvetica"
    @Published var textFontSize: CGFloat = 16
    @Published var textColor = NSColor.labelColor
    @Published var coverColor = NSColor.white
    @Published var highlightColor = NSColor.systemYellow.withAlphaComponent(0.45)
    @Published var strokeColor = NSColor.systemBlue
    @Published var fillColor = NSColor.clear
    @Published var lineWidth: CGFloat = 2
    @Published var stampText = "APPROVED"

    let signatures = SignatureStore()
    let undoManager = UndoManager()
    private var cancellables: Set<AnyCancellable> = []
    private var securityScopedURL: URL?

    init() {
        signatures.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var pageCount: Int { document?.pageCount ?? 0 }

    var canNavigateToPreviousPage: Bool {
        currentPageIndex > 0
    }

    var canNavigateToNextPage: Bool {
        pageCount > 0 && currentPageIndex < pageCount - 1
    }

    var currentPageLabel: String {
        guard pageCount > 0 else { return "-" }
        return "\(min(currentPageIndex + 1, pageCount)) / \(pageCount)"
    }

    var availableFontFamilies: [String] {
        NSFontManager.shared.availableFontFamilies.sorted()
    }

    func openWithPanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Open PDF"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        open(url: url)
    }

    func open(url: URL) {
        if let securityScopedURL {
            securityScopedURL.stopAccessingSecurityScopedResource()
            self.securityScopedURL = nil
        }
        let accessed = url.startAccessingSecurityScopedResource()
        guard let pdf = PDFDocument(url: url) else {
            if accessed { url.stopAccessingSecurityScopedResource() }
            statusMessage = "Could not open \(url.lastPathComponent)."
            return
        }
        if accessed {
            securityScopedURL = url
        }
        document = pdf
        documentURL = url
        documentTitle = url.lastPathComponent
        currentPageIndex = 0
        selectedAnnotation = nil
        selectedAnnotationPage = nil
        replacementDraft = nil
        isModified = false
        statusMessage = "Opened \(url.lastPathComponent)."
    }

    func save() {
        guard let document else { return }
        if let documentURL {
            write(document: document, to: documentURL, flattened: false)
        } else {
            saveAs()
        }
    }

    func saveAs() {
        guard let document else { return }
        guard let url = savePanel(defaultName: documentTitle.hasSuffix(".pdf") ? documentTitle : "\(documentTitle).pdf") else { return }
        write(document: document, to: url, flattened: false)
        documentURL = url
        documentTitle = url.lastPathComponent
    }

    func exportFlattened() {
        guard let document else { return }
        let baseName = documentTitle.replacingOccurrences(of: ".pdf", with: "", options: [.caseInsensitive])
        guard let url = savePanel(defaultName: "\(baseName)-flattened.pdf") else { return }
        write(document: document, to: url, flattened: true)
    }

    private func savePanel(defaultName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = defaultName
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func write(document: PDFDocument, to url: URL, flattened: Bool) {
        isSaving = true
        let data: Data?
        if flattened {
            let options: [PDFDocumentWriteOption: Any] = [.burnInAnnotationsOption: true]
            data = document.dataRepresentation(options: options)
        } else {
            data = document.dataRepresentation()
        }
        guard let data else {
            isSaving = false
            statusMessage = "Could not serialize PDF."
            return
        }
        do {
            try data.write(to: url)
            isModified = false
            statusMessage = flattened ? "Exported flattened PDF." : "Saved \(url.lastPathComponent)."
        } catch {
            statusMessage = "Save failed: \(error.localizedDescription)"
        }
        isSaving = false
    }

    func markChanged(_ message: String) {
        isModified = true
        statusMessage = message
    }

    func select(annotation: PDFAnnotation?, on page: PDFPage?) {
        selectedAnnotation = annotation
        selectedAnnotationPage = page
        replacementDraft = nil
    }

    func deleteSelectedAnnotation() {
        guard let selectedAnnotation, let page = selectedAnnotationPage else { return }
        page.removeAnnotation(selectedAnnotation)
        self.selectedAnnotation = nil
        selectedAnnotationPage = nil
        markChanged("Deleted annotation.")
    }

    func updateSelectedTextAnnotation(contents: String) {
        guard let annotation = selectedAnnotation else { return }
        annotation.contents = contents
        annotation.font = NSFont(name: textFontName, size: textFontSize) ?? .systemFont(ofSize: textFontSize)
        annotation.fontColor = textColor
        markChanged("Updated text annotation.")
    }

    func createReplacementDraft(text: String, page: PDFPage, bounds: CGRect, font: NSFont, color: NSColor) {
        replacementDraft = ReplacementDraft(
            originalText: text,
            replacementText: text,
            fontName: font.fontName,
            fontSize: max(8, font.pointSize),
            textColor: color,
            coverColor: coverColor,
            page: page,
            bounds: bounds.insetBy(dx: -2, dy: -2)
        )
        textFontName = font.fontName
        textFontSize = max(8, font.pointSize)
        textColor = color
        activeTool = .replaceText
        statusMessage = "Edit detected text, then apply replacement."
    }

    func applyReplacementDraft() {
        guard let draft = replacementDraft else { return }
        let cover = PDFAnnotation(bounds: draft.bounds.insetBy(dx: -1, dy: -1), forType: .square, withProperties: nil)
        cover.color = draft.coverColor
        cover.interiorColor = draft.coverColor
        let coverBorder = PDFBorder()
        coverBorder.lineWidth = 0
        cover.border = coverBorder
        cover.shouldDisplay = true
        cover.shouldPrint = true
        cover.setValue("replace-cover" as NSString, forAnnotationKey: PDFAnnotationKey(rawValue: "/FPEType"))

        let text = PDFAnnotation(bounds: draft.bounds, forType: .freeText, withProperties: nil)
        text.contents = draft.replacementText
        text.font = draft.font
        text.fontColor = draft.textColor
        text.color = .clear
        text.alignment = .left
        let textBorder = PDFBorder()
        textBorder.lineWidth = 0
        text.border = textBorder
        text.shouldDisplay = true
        text.shouldPrint = true
        text.setValue("replace-text" as NSString, forAnnotationKey: PDFAnnotationKey(rawValue: "/FPEType"))

        draft.page.addAnnotation(cover)
        draft.page.addAnnotation(text)
        selectedAnnotation = text
        selectedAnnotationPage = draft.page
        replacementDraft = nil
        activeTool = .select
        markChanged("Applied text replacement overlay.")
    }

    func cancelReplacementDraft() {
        replacementDraft = nil
        statusMessage = "Text replacement cancelled."
    }

    func page(at index: Int) -> PDFPage? {
        document?.page(at: index)
    }

    func goToPage(_ index: Int) {
        guard pageCount > 0 else { return }
        currentPageIndex = min(max(index, 0), pageCount - 1)
    }

    func goToPreviousPage() {
        goToPage(currentPageIndex - 1)
    }

    func goToNextPage() {
        goToPage(currentPageIndex + 1)
    }

    func zoomIn() {
        guard document != nil else { return }
        zoomScale = min(4.0, zoomScale + 0.1)
        statusMessage = "Zoomed to \(Int(zoomScale * 100))%."
    }

    func zoomOut() {
        guard document != nil else { return }
        zoomScale = max(0.25, zoomScale - 0.1)
        statusMessage = "Zoomed to \(Int(zoomScale * 100))%."
    }

    func zoomToActualSize() {
        guard document != nil else { return }
        zoomScale = 1.0
        statusMessage = "Zoomed to actual size."
    }

    func toggleSidebar() {
        isSidebarVisible.toggle()
    }

    func toggleInspector() {
        isInspectorVisible.toggle()
    }

    func setTool(_ tool: EditorTool) {
        guard document != nil else { return }
        activeTool = tool
        statusMessage = "\(tool.rawValue) tool selected."
    }
}
