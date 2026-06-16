import Foundation
import SwiftData

@Model
final class IdeaNode {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var rawCapture: String
    var title: String
    var refinedText: String
    var summary: String
    var tagsText: String
    var status: String // inbox, refined, archived
    // Relationships can be added later for projects/links as needed
    
    init(id: UUID = UUID(), createdAt: Date = Date(), updatedAt: Date = Date(), rawCapture: String, title: String = "", refinedText: String = "", summary: String = "", tagsText: String = "", status: String = "inbox") {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.rawCapture = rawCapture
        self.title = title
        self.refinedText = refinedText
        self.summary = summary
        self.tagsText = tagsText
        self.status = status
    }
}
