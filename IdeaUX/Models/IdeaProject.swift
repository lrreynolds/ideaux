import Foundation
import SwiftData

@Model
final class IdeaProject {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var name: String
    var summary: String
    // status as String: active, paused, archived
    var status: String

    // Relationships
    var collection: IdeaCollection?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        name: String,
        summary: String = "",
        status: String = "active",
        collection: IdeaCollection? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.name = name
        self.summary = summary
        self.status = status
        self.collection = collection
    }
}
