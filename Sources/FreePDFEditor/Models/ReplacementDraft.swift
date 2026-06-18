import AppKit
import Foundation
import PDFKit

struct ReplacementDraft: Identifiable {
    let id = UUID()
    let originalText: String
    var replacementText: String
    var fontName: String
    var fontSize: CGFloat
    var textColor: NSColor
    var coverColor: NSColor
    let page: PDFPage
    let bounds: CGRect

    var font: NSFont {
        NSFont(name: fontName, size: fontSize) ?? .systemFont(ofSize: fontSize)
    }
}
