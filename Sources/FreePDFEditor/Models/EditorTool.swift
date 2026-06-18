import Foundation

enum EditorTool: String, CaseIterable, Identifiable {
    case select = "Select"
    case replaceText = "Replace Text"
    case highlight = "Highlight"
    case underline = "Underline"
    case strikeout = "Strikeout"
    case textBox = "Text Box"
    case comment = "Comment"
    case rectangle = "Rectangle"
    case ellipse = "Ellipse"
    case line = "Line"
    case stamp = "Stamp"
    case signature = "Signature"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .select: "cursorarrow"
        case .replaceText: "character.cursor.ibeam"
        case .highlight: "highlighter"
        case .underline: "underline"
        case .strikeout: "strikethrough"
        case .textBox: "textbox"
        case .comment: "bubble.left"
        case .rectangle: "rectangle"
        case .ellipse: "oval"
        case .line: "line.diagonal"
        case .stamp: "seal"
        case .signature: "signature"
        }
    }

    var isSelectionMarkupTool: Bool {
        self == .highlight || self == .underline || self == .strikeout
    }
}
