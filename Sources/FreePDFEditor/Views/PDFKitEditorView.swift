import AppKit
import PDFKit
import SwiftUI

struct PDFKitEditorView: NSViewRepresentable {
    @ObservedObject var editor: PDFEditorModel

    func makeNSView(context: Context) -> EditorPDFView {
        let view = EditorPDFView()
        view.editor = editor
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.displaysPageBreaks = true
        view.backgroundColor = .windowBackgroundColor
        view.delegate = context.coordinator
        view.setupOverlay()
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.pageChanged(_:)),
            name: .PDFViewPageChanged,
            object: view
        )
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.scaleChanged(_:)),
            name: .PDFViewScaleChanged,
            object: view
        )
        return view
    }

    func updateNSView(_ pdfView: EditorPDFView, context: Context) {
        pdfView.editor = editor
        if pdfView.document !== editor.document {
            pdfView.document = editor.document
        }
        pdfView.apply(readingMode: editor.readingMode)
        if abs(pdfView.scaleFactor - editor.zoomScale) > 0.001 {
            pdfView.scaleFactor = editor.zoomScale
        }
        if let page = editor.page(at: editor.currentPageIndex), pdfView.currentPage !== page {
            pdfView.go(to: page)
        }
        pdfView.overlay.select(editor.selectedAnnotation, page: editor.selectedAnnotationPage, in: pdfView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(editor: editor)
    }

    final class Coordinator: NSObject, PDFViewDelegate {
        private weak var editor: PDFEditorModel?

        init(editor: PDFEditorModel) {
            self.editor = editor
        }

        @MainActor @objc func pageChanged(_ notification: Notification) {
            guard let editor,
                  let pdfView = notification.object as? PDFView,
                  let page = pdfView.currentPage,
                  let document = pdfView.document else { return }
            let index = document.index(for: page)
            if index != NSNotFound {
                editor.currentPageIndex = index
            }
        }

        @MainActor @objc func scaleChanged(_ notification: Notification) {
            guard let editor, let pdfView = notification.object as? PDFView else { return }
            editor.zoomScale = pdfView.scaleFactor
        }
    }
}

final class EditorPDFView: PDFView {
    weak var editor: PDFEditorModel?
    let overlay = AnnotationSelectionOverlay()

    private var shapeStart: CGPoint?
    private var shapePage: PDFPage?
    private var shapePreview: PDFAnnotation?

    override var acceptsFirstResponder: Bool { true }

    func setupOverlay() {
        overlay.autoresizingMask = [.width, .height]
        overlay.frame = bounds
        overlay.onChanged = { [weak self] in
            self?.editor?.markChanged("Updated annotation.")
        }
        overlay.onDelete = { [weak self] in
            self?.editor?.deleteSelectedAnnotation()
        }
        addSubview(overlay, positioned: .above, relativeTo: nil)
    }

    func apply(readingMode: ReadingMode) {
        wantsLayer = true
        switch readingMode {
        case .normal:
            backgroundColor = .windowBackgroundColor
            layer?.filters = nil
        case .sepia:
            backgroundColor = NSColor(red: 0.96, green: 0.93, blue: 0.82, alpha: 1)
            if let filter = CIFilter(name: "CISepiaTone") {
                filter.setValue(0.55, forKey: kCIInputIntensityKey)
                layer?.filters = [filter]
            }
        case .night:
            backgroundColor = .white
            layer?.filters = [CIFilter(name: "CIColorInvert")].compactMap { $0 }
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard let editor else {
            super.mouseDown(with: event)
            return
        }
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)

        switch editor.activeTool {
        case .select:
            if event.clickCount == 2, editAnnotation(at: point) { return }
            if selectAnnotation(at: point) { return }
            editor.select(annotation: nil, on: nil)
            overlay.clear()
            super.mouseDown(with: event)

        case .replaceText:
            if detectTextLine(at: point) { return }
            super.mouseDown(with: event)

        case .textBox:
            addTextBox(at: point)

        case .comment:
            addComment(at: point)

        case .stamp:
            addStamp(at: point)

        case .signature:
            addSignature(at: point)

        case .rectangle, .ellipse, .line:
            beginShape(at: point)

        case .highlight, .underline, .strikeout:
            super.mouseDown(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        if let editor, [.rectangle, .ellipse, .line].contains(editor.activeTool), shapeStart != nil {
            updateShapePreview(at: convert(event.locationInWindow, from: nil))
            return
        }
        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if let editor, [.rectangle, .ellipse, .line].contains(editor.activeTool), shapeStart != nil {
            finishShape(at: convert(event.locationInWindow, from: nil))
            return
        }
        super.mouseUp(with: event)
        if editor?.activeTool.isSelectionMarkupTool == true {
            applySelectionMarkup()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 51 || event.keyCode == 117 {
            editor?.deleteSelectedAnnotation()
            overlay.clear()
            return
        }
        super.keyDown(with: event)
    }

    private func pageAndPoint(for viewPoint: CGPoint, nearest: Bool = true) -> (PDFPage, CGPoint)? {
        guard let page = page(for: viewPoint, nearest: nearest) else { return nil }
        return (page, convert(viewPoint, to: page))
    }

    private func selectAnnotation(at viewPoint: CGPoint) -> Bool {
        guard let editor, let (page, pagePoint) = pageAndPoint(for: viewPoint, nearest: false) else { return false }
        let hit = page.annotations.reversed().first {
            $0.bounds.insetBy(dx: -6, dy: -6).contains(pagePoint)
        }
        guard let hit else { return false }
        editor.select(annotation: hit, on: page)
        overlay.select(hit, page: page, in: self)
        return true
    }

    private func editAnnotation(at viewPoint: CGPoint) -> Bool {
        guard let editor, let (page, pagePoint) = pageAndPoint(for: viewPoint, nearest: false) else { return false }
        guard let annotation = page.annotations.reversed().first(where: {
            $0.bounds.insetBy(dx: -6, dy: -6).contains(pagePoint)
        }) else { return false }
        editor.select(annotation: annotation, on: page)
        overlay.select(annotation, page: page, in: self)
        if annotation.type == "FreeText" {
            editor.textFontName = annotation.font?.fontName ?? editor.textFontName
            editor.textFontSize = annotation.font?.pointSize ?? editor.textFontSize
            editor.textColor = annotation.fontColor ?? editor.textColor
            editor.statusMessage = "Edit selected text in the inspector."
        }
        return true
    }

    private func addTextBox(at viewPoint: CGPoint) {
        guard let editor, let (page, pagePoint) = pageAndPoint(for: viewPoint) else { return }
        let rect = CGRect(x: pagePoint.x - 90, y: pagePoint.y - 18, width: 180, height: 36)
        let annotation = PDFAnnotation(bounds: rect, forType: .freeText, withProperties: nil)
        annotation.contents = "Text"
        annotation.font = NSFont(name: editor.textFontName, size: editor.textFontSize) ?? .systemFont(ofSize: editor.textFontSize)
        annotation.fontColor = editor.textColor
        annotation.color = .clear
        let border = PDFBorder()
        border.lineWidth = 0
        annotation.border = border
        page.addAnnotation(annotation)
        editor.select(annotation: annotation, on: page)
        overlay.select(annotation, page: page, in: self)
        editor.activeTool = .select
        editor.markChanged("Added text box.")
    }

    private func addComment(at viewPoint: CGPoint) {
        guard let editor, let (page, pagePoint) = pageAndPoint(for: viewPoint) else { return }
        let rect = CGRect(x: pagePoint.x - 105, y: pagePoint.y - 42, width: 210, height: 84)
        let annotation = PDFAnnotation(bounds: rect, forType: .freeText, withProperties: nil)
        annotation.contents = "Comment"
        annotation.font = .systemFont(ofSize: 13)
        annotation.fontColor = .black
        annotation.color = NSColor.systemYellow.withAlphaComponent(0.88)
        page.addAnnotation(annotation)
        editor.select(annotation: annotation, on: page)
        overlay.select(annotation, page: page, in: self)
        editor.activeTool = .select
        editor.markChanged("Added comment.")
    }

    private func addStamp(at viewPoint: CGPoint) {
        guard let editor, let (page, pagePoint) = pageAndPoint(for: viewPoint) else { return }
        let rect = CGRect(x: pagePoint.x - 72, y: pagePoint.y - 23, width: 144, height: 46)
        let annotation = PDFTextStampAnnotation(label: editor.stampText, color: editor.strokeColor, bounds: rect)
        page.addAnnotation(annotation)
        editor.select(annotation: annotation, on: page)
        overlay.select(annotation, page: page, in: self)
        editor.activeTool = .select
        editor.markChanged("Added stamp.")
    }

    private func addSignature(at viewPoint: CGPoint) {
        guard let editor, let item = editor.signatures.selectedSignature,
              let image = editor.signatures.image(for: item),
              let (page, pagePoint) = pageAndPoint(for: viewPoint) else {
            editor?.statusMessage = "Create or import a signature first."
            return
        }
        let width: CGFloat = 190
        let height = image.size.width > 0 ? min(90, width * image.size.height / image.size.width) : 70
        let rect = CGRect(x: pagePoint.x - width / 2, y: pagePoint.y - height / 2, width: width, height: height)
        let annotation = PDFImageAnnotation(image: image, bounds: rect)
        page.addAnnotation(annotation)
        editor.select(annotation: annotation, on: page)
        overlay.select(annotation, page: page, in: self)
        editor.activeTool = .select
        editor.markChanged("Added signature.")
    }

    private func beginShape(at viewPoint: CGPoint) {
        guard let (page, pagePoint) = pageAndPoint(for: viewPoint) else { return }
        shapeStart = pagePoint
        shapePage = page
    }

    private func updateShapePreview(at viewPoint: CGPoint) {
        guard let editor, let page = shapePage, let start = shapeStart else { return }
        if let shapePreview {
            page.removeAnnotation(shapePreview)
        }
        let current = convert(viewPoint, to: page)
        let annotation = makeShapeAnnotation(tool: editor.activeTool, start: start, end: current, preview: true)
        guard annotation.bounds.width > 3, annotation.bounds.height > 3 else { return }
        page.addAnnotation(annotation)
        shapePreview = annotation
    }

    private func finishShape(at viewPoint: CGPoint) {
        guard let editor, let page = shapePage, let start = shapeStart else { return }
        if let shapePreview {
            page.removeAnnotation(shapePreview)
        }
        let end = convert(viewPoint, to: page)
        let annotation = makeShapeAnnotation(tool: editor.activeTool, start: start, end: end, preview: false)
        shapeStart = nil
        shapePage = nil
        shapePreview = nil
        guard annotation.bounds.width > 8, annotation.bounds.height > 8 else { return }
        page.addAnnotation(annotation)
        editor.select(annotation: annotation, on: page)
        overlay.select(annotation, page: page, in: self)
        editor.activeTool = .select
        editor.markChanged("Added shape.")
    }

    private func makeShapeAnnotation(tool: EditorTool, start: CGPoint, end: CGPoint, preview: Bool) -> PDFAnnotation {
        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
        let subtype: PDFAnnotationSubtype = {
            switch tool {
            case .ellipse: return .circle
            case .line: return .line
            default: return .square
            }
        }()
        let annotation = PDFAnnotation(bounds: rect.insetBy(dx: tool == .line ? -6 : 0, dy: tool == .line ? -6 : 0), forType: subtype, withProperties: nil)
        if tool == .line {
            annotation.startPoint = start
            annotation.endPoint = end
        }
        annotation.color = (editor?.strokeColor ?? .systemBlue).withAlphaComponent(preview ? 0.55 : 1)
        if let fill = editor?.fillColor, fill.alphaComponent > 0, tool != .line {
            annotation.interiorColor = fill.withAlphaComponent(preview ? 0.25 : fill.alphaComponent)
        }
        let border = PDFBorder()
        border.lineWidth = editor?.lineWidth ?? 2
        border.style = .solid
        annotation.border = border
        return annotation
    }

    private func detectTextLine(at viewPoint: CGPoint) -> Bool {
        guard let editor, let (page, pagePoint) = pageAndPoint(for: viewPoint, nearest: false),
              let attr = page.attributedString,
              attr.length > 0,
              let selection = page.selectionForLine(at: pagePoint),
              let text = selection.string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return false }

        let index = max(0, min(page.characterIndex(at: pagePoint), attr.length - 1))
        let font = attr.attribute(.font, at: index, effectiveRange: nil) as? NSFont ?? .systemFont(ofSize: 12)
        let color = attr.attribute(.foregroundColor, at: index, effectiveRange: nil) as? NSColor ?? .labelColor
        let bounds = selection.bounds(for: page)
        editor.createReplacementDraft(text: text, page: page, bounds: bounds, font: font, color: color)
        return true
    }

    private func applySelectionMarkup() {
        guard let editor, let selection = currentSelection, !(selection.string ?? "").isEmpty else { return }
        let subtype: PDFAnnotationSubtype
        switch editor.activeTool {
        case .highlight: subtype = .highlight
        case .underline: subtype = .underline
        case .strikeout: subtype = .strikeOut
        default: return
        }
        for lineSelection in selection.selectionsByLine() {
            for page in lineSelection.pages {
                let bounds = lineSelection.bounds(for: page)
                guard !bounds.isEmpty else { continue }
                let annotation = PDFAnnotation(bounds: bounds, forType: subtype, withProperties: nil)
                annotation.color = editor.activeTool == .highlight ? editor.highlightColor : editor.strokeColor
                page.addAnnotation(annotation)
            }
        }
        clearSelection()
        editor.markChanged("Applied \(editor.activeTool.rawValue.lowercased()).")
    }
}

final class AnnotationSelectionOverlay: NSView {
    weak var pdfView: PDFView?
    weak var annotation: PDFAnnotation?
    weak var page: PDFPage?

    var onChanged: (() -> Void)?
    var onDelete: (() -> Void)?

    private enum DragMode { case move, resizeTopLeft, resizeTopRight, resizeBottomLeft, resizeBottomRight }
    private var dragMode: DragMode?
    private var dragStartPoint: CGPoint = .zero
    private var originalViewRect: CGRect = .zero

    override var acceptsFirstResponder: Bool { true }

    func select(_ annotation: PDFAnnotation?, page: PDFPage?, in pdfView: PDFView) {
        self.annotation = annotation
        self.page = page
        self.pdfView = pdfView
        isHidden = annotation == nil
        needsDisplay = true
    }

    func clear() {
        annotation = nil
        page = nil
        isHidden = true
        needsDisplay = true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard selectedRect.insetBy(dx: -10, dy: -10).contains(point) else { return nil }
        return self
    }

    override func draw(_ dirtyRect: NSRect) {
        guard !isHidden else { return }
        let rect = selectedRect
        NSColor.controlAccentColor.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 1.5
        path.stroke()
        NSColor.controlAccentColor.setFill()
        for handle in handles(for: rect) {
            NSBezierPath(roundedRect: handle, xRadius: 2, yRadius: 2).fill()
        }
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        dragStartPoint = convert(event.locationInWindow, from: nil)
        originalViewRect = selectedRect
        dragMode = mode(at: dragStartPoint, rect: originalViewRect)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragMode, let annotation, let page, let pdfView else { return }
        let point = convert(event.locationInWindow, from: nil)
        let dx = point.x - dragStartPoint.x
        let dy = point.y - dragStartPoint.y
        var rect = originalViewRect

        switch dragMode {
        case .move:
            rect.origin.x += dx
            rect.origin.y += dy
        case .resizeTopLeft:
            rect.origin.x += dx
            rect.size.width -= dx
            rect.size.height += dy
        case .resizeTopRight:
            rect.size.width += dx
            rect.size.height += dy
        case .resizeBottomLeft:
            rect.origin.x += dx
            rect.origin.y += dy
            rect.size.width -= dx
            rect.size.height -= dy
        case .resizeBottomRight:
            rect.origin.y += dy
            rect.size.width += dx
            rect.size.height -= dy
        }

        if rect.width < 18 { rect.size.width = 18 }
        if rect.height < 12 { rect.size.height = 12 }
        annotation.bounds = pdfView.convert(rect.standardized, to: page).standardized
        pdfView.setNeedsDisplay(pdfView.bounds)
        needsDisplay = true
        onChanged?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 51 || event.keyCode == 117 {
            onDelete?()
            return
        }
        super.keyDown(with: event)
    }

    private var selectedRect: CGRect {
        guard let annotation, let page, let pdfView else { return .zero }
        return pdfView.convert(annotation.bounds, from: page).standardized
    }

    private func handles(for rect: CGRect) -> [CGRect] {
        let size: CGFloat = 8
        return [
            CGRect(x: rect.minX - size / 2, y: rect.minY - size / 2, width: size, height: size),
            CGRect(x: rect.maxX - size / 2, y: rect.minY - size / 2, width: size, height: size),
            CGRect(x: rect.minX - size / 2, y: rect.maxY - size / 2, width: size, height: size),
            CGRect(x: rect.maxX - size / 2, y: rect.maxY - size / 2, width: size, height: size)
        ]
    }

    private func mode(at point: CGPoint, rect: CGRect) -> DragMode {
        let all = handles(for: rect)
        if all[0].contains(point) { return .resizeBottomLeft }
        if all[1].contains(point) { return .resizeBottomRight }
        if all[2].contains(point) { return .resizeTopLeft }
        if all[3].contains(point) { return .resizeTopRight }
        return .move
    }
}
