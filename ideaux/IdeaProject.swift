import Foundation
import SwiftData

@Model
final class IdeaProject {
    var id: UUID
    var createdAt: Date
    var name: String
    var summary: String
    // Relationships to nodes can be added later if needed
    
    init(id: UUID = UUID(), createdAt: Date = Date(), name: String, summary: String = "") {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.summary = summary
    }
}
