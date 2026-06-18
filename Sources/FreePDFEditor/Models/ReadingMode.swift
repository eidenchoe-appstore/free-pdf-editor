import Foundation

enum ReadingMode: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case sepia = "Sepia"
    case night = "Night"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .normal: "sun.max"
        case .sepia: "book"
        case .night: "moon"
        }
    }
}
