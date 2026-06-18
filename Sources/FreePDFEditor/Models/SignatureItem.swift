import Foundation

struct SignatureItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var filename: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, filename: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.filename = filename
        self.createdAt = createdAt
    }
}
